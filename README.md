Kloster
=======

Kloster is an Alpine Linux+Xen spin I am using to host my own services. It's not
much right now, but the intention is to have a tiny, secure Dom0 based on Alpine
Linux with the Sway wayland wm that comes with scripts to set up a set of
default DomU's, not entirely unlike Qubes but with the express purpose of using
the DomU's to deploy services in a long-term way and no intention to be directly
useful as a desktop OS. Do not take this setup to be secure! I'm just
experimenting with the ideas, I don't know if I've made a mistake! Use a mature
system if you want security.

Planned Default DomU's
----------------------

  * Alpine, deploying Docker
  * Alpine, deploying Docker-Registry
  * Alpine, deploying DarkHTTPD
  * Alpine, deploying x2goserver and a variety of games
  * Alpine, deploying i2pd in a Whonix-like configuration
  * Whonix
  * Network VM
  * USB VM
  * Debian-minbase

References
----------

  * [How to make a custom ISO image with mkimage](https://wiki.alpinelinux.org/wiki/How_to_make_a_custom_ISO_image_with_mkimage)
  * [Aports Tree, needed to obtain mkimage.sh](http://git.alpinelinux.org/cgit/aports/) (git://git.alpinelinux.org/aports)
    * [Forked out to fix build errors, likely temporary](https://github.com/eyedeekay/aports)
  * [Create an Alpine Linux paravirtualized DomU](https://wiki.alpinelinux.org/wiki/Create_Alpine_Linux_PV_DomU)
