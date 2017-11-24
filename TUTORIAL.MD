It is *Shockingly* easy to produce a custom Alpine Linux LiveCD
===============================================================

Like, sickeningly so. Really, it'd mind-blowing how easy it is. Especially if
you use a "stable" baseline derived from one of Alpine's point releases. It's
a little less reliable if you need software in unstable. I am going to really,
really drag out this tutorial and be exhaustive on my method for generating
Alpine LiveCD's.

OK, so what do you need to create an Alpine Linux LiveCD? Well, for starters,
it helps to have an Alpine Linux installation running already. Fortunately for
me, I use Docker all the time and Alpine-on-Docker gets is used preposterously
often. So, even though I'm pretty sure all the dependencies can be installed
on any distribution, I think the most reliable way to generate these LiveCD's
is in a Docker container used especially for the purpose. Of course, you can
always use a native Alpine installation with this method, or you can use your
virtualization/containerization technology of your choice. This tutorial will
use Docker though.

Step Zero: Dealing with some mild counter-intuition
---------------------------------------------------

Alpine doesn't produce packages containing it's mkimage.sh scripts(yet, I really
don't know if it will or won't be packaged). Instead, you get the scripts by
cloning the [aports tree](http://git.alpinelinux.org/cgit/aports/). This will
be covered in Step Two: Install the Alpine Linux toolchain.

Step One: Creating a Container to work in
-----------------------------------------

First, you'll need to create an Alpine Linux based Docker container, which if
you've already used docker, you know is very easy.

        FROM alpine:edge

Next, enable the community repository.

        RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" | tee -a /etc/apk/repositories

Step Two: Install the Alpine Linux toolchain
--------------------------------------------

        RUN apk update
        RUN apk add alpine-sdk build-base apk-tools alpine-conf busybox \
                fakeroot syslinux xorriso mtools dosfstools grub-efi make \
                git sudo

Sometimes, I just keep a container with all this stuff in it, and use it as a
new base container for creating alpine packagesof all types.

Step Three: Create a "build" user and an "abuild" group
-----------------------------------------------------

Finally, you'll need to create a "build" user with it's own home directory, who
is a member of the "abuild" group. This will allow that user to generate Alpine
packages and sign them with the keys we will be generating momentarily.

        RUN adduser -h /home/build -D build -G abuild

Because this is being run in a Docker container(And therefore there is no TTY
to capture a sudo password during the build phase) we also need to add the build
user to the sudoers file. Because this container will only be used to generate
the LiveCD and will not be running any services, this seems to be acceptable.
This allows us to use the default settings defined by mkimage and or the Alpine
toolchain.

        RUN echo 'build ALL=(ALL) NOPASSWD: ALL' | tee -a /etc/sudoers

Step Four: Clone the aports tree
--------------------------------

Now that you have your toolchain and build user set up, you'll need to obtain
the "aports" tree where alpine packages are organized and built according to
rules. In particular, you need the scripts directory.

        RUN git clone http://git.alpinelinux.org/cgit/aports/ /home/build/aports
        RUN cd /home/build/aports && apk update

Step Five: Copy, Create, or Generate a mkimage sub-script
---------------------------------------------------------

This is far and away the only involved task in the whole process. mkimage.sh
uses these little sub-scripts that configure package installation on the LiveCD.
Because I'm a chronic Makefile abuser, I embed parameters to generate the files
in a Makefile, then have the Makefile emit them inside the container. You don't
have to do that, though, a basic mkimage sub-script is just a function, which
specifies a few variables. **NOTE** this section will grow as I find out more
about what the variables are. But the most relevant of them are covered here.

  * apks: Obviously, this is a list of apks to try and install on the LiveCD. If
  they are in an unbuilt or failing state, and you're using edge as a basis for
  your LiveCD, then it will fail and inform you of the packages that failed to
  install.
  * kernel\_addons: This is a list of kernel addons you want to exist on your
  LiveCD. I'm not sure, but these may be automatically added based on the
  dependencies of your apk's.
  * kernel\_cmdline: This is a list of commands to add to your Linux Kernel
  command line.
  * syslinux\_serial: This is used to configure the syslinux serial interface.
  For most people, "0 115200" should be fine.


So, first, decide on an identifier and create a file named
*mkimg.$identifier.sh* and add your #! line at the top to specify the
interpreter. Then declare a function, with the name *profile\_$identifier* and
call, at least *profile\_standard*. This function *profile\_standard* is already
defined in the other mkimg.*.sh scripts in the aports scripts directory and it
makes sure that you have the Alpine standard packages, which are pretty minimal.
You could also write your own function to base it on by examinging and copying
parts of the profile\_standard option.

        #! /bin/sh
        profile_kloster(){
          profile_standard

Next, you should set the variables associated with the kernel\_cmdline,
syslinux\_serial, and kernel\_addons. In most cases, you'll only need to set
these once, but in case of more complex configurations, you may need to add
things to them conditionally, or in many stages. In that case, you may need to
prefix the value set by the variables with the value of the variable itself,
like in the apk's example to follow.

          kernel_cmdline=""
          syslinux_serial="0 115200"
          kernel_addons="zfs spl"

Now, you can specify the apks you wish to install. Note that each of these apk
lines begins with an $apks; this is because the value is additive. While this
format isn't strictly necessary in this static example, in more complex
configurations where packages are selected dynamically, this pattern is very
useful.

          apks="$apks iscsi-scst zfs-scripts zfs zfs-utils-py cciss_vol_status lvm2 mdadm mkinitfs mtools nfs-utils parted rsync sfdisk syslinux unrar util-linux xfsprogs dosfstools ntfs-3g ethtool multipath-tools linux-firmware openvswitch"
          apks="$apks sway gdm mutt nano htop wireless-tools"
          apks="$apks xen xen-bridge"

Finally, loop over the apk and kernel_addons variables in order to finalize the
configuration of the LiveCD.

          local _k _a
          for _k in $kernel_flavors; do
              apks="$apks linux-$_k"
              for _a in $kernel_addons; do
                  apks="$apks $_a-$_k"
              done
          done

and close the function.

        }

Step Six:
---------

Finally, run the mkimage.sh script with the newly created LiveCD profile. In
surprisingly short order, you'll have a custom LiveCD containing your custom
packages.

        sh mkimage.sh --tag v3.6 \
		--outdir ~/iso \
		--arch x86_64 \
		--repository       http://dl-cdn.alpinelinux.org/alpine/v3.6/main \
		--extra-repository http://dl-cdn.alpinelinux.org/alpine/v3.6/community \
		"$extra_repository" \
		--profile kloster
