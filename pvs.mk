pv-docker-config:
	@echo "#! /bin/sh"
	@echo "#export PROFILENAME=docker"
	@echo "profile_docker(){"
	@echo "    profile_standard"
	@echo "    kernel_cmdline=\"\""
	@echo "    syslinux_serial=\"0 115200\""
	@echo "    apks=$(ALPINE_DOCKER_PACKAGES)"
	@echo "    local _k _a"
	@echo "    for _k in \$$kernel_flavors; do"
	@echo "        apks=\"\$$apks linux-\$$_k\""
	@echo "        for _a in \$$kernel_addons; do"
	@echo "            apks=\"\$$apks \$$_a-\$$_k\""
	@echo "        done"
	@echo "    done"
	@echo "}"
	@echo ""

docker-pv:
	sh mkimage.sh --tag $(branch) \
		--outdir ~/iso \
		--arch x86_64 \
		--repository       $(mirror)$(branch)/main \
		--extra-repository $(mirror)$(branch)/community \
		$$edge_extra_repository \
		--profile docker

pv-docker-registry-config:
	@echo "#! /bin/sh"
	@echo "#export PROFILENAME=registry"
	@echo "profile_registry(){"
	@echo "    profile_standard"
	@echo "    kernel_cmdline=\"\""
	@echo "    syslinux_serial=\"0 115200\""
	@echo "    apks=$(ALPINE_DOCKER_REGISTRY_PACKAGES)"
	@echo "    local _k _a"
	@echo "    for _k in \$$kernel_flavors; do"
	@echo "        apks=\"\$$apks linux-\$$_k\""
	@echo "        for _a in \$$kernel_addons; do"
	@echo "            apks=\"\$$apks \$$_a-\$$_k\""
	@echo "        done"
	@echo "    done"
	@echo "}"
	@echo ""

docker-registry-pv:
	sh mkimage.sh --tag $(branch) \
		--outdir ~/iso \
		--arch x86_64 \
		--repository       $(mirror)$(branch)/main \
		--extra-repository $(mirror)$(branch)/community \
		$$edge_extra_repository \
		--profile registry

pv-darkhttpd-config:
	@echo "#! /bin/sh"
	@echo "#export PROFILENAME=docker"
	@echo "profile_darkhttpd(){"
	@echo "    profile_standard"
	@echo "    kernel_cmdline=\"\""
	@echo "    syslinux_serial=\"0 115200\""
	@echo "    apks=$(ALPINE_DARKHTTPD_PACKAGES)"
	@echo "    local _k _a"
	@echo "    for _k in \$$kernel_flavors; do"
	@echo "        apks=\"\$$apks linux-\$$_k\""
	@echo "        for _a in \$$kernel_addons; do"
	@echo "            apks=\"\$$apks \$$_a-\$$_k\""
	@echo "        done"
	@echo "    done"
	@echo "}"
	@echo ""

darkhttpd-pv:
	sh mkimage.sh --tag $(branch) \
		--outdir ~/iso \
		--arch x86_64 \
		--repository       $(mirror)$(branch)/main \
		--extra-repository $(mirror)$(branch)/community \
		$$edge_extra_repository \
		--profile darkhttpd

docker-iso:
	docker rm -f alpine-docker-iso; \
	docker run -d --privileged \
		-w /home/build/aports/scripts/ \
		--cap-add=SYS_ADMIN \
		--name alpine-docker-iso \
		-t alpine-xen-iso sh -c 'make docker-pv && sh'

docker-registry-iso:
	docker rm -f alpine-registry-iso; \
	docker run -d --privileged \
		-w /home/build/aports/scripts/ \
		--cap-add=SYS_ADMIN \
		--name alpine-registry-iso \
		-t alpine-xen-iso \
		sh -c 'make docker-registry-pv && sh'

darkhttpd-iso:
	docker rm -f alpine-darkhttpd-iso; \
	docker run -d --privileged \
		-w /home/build/aports/scripts/ \
		--cap-add=SYS_ADMIN \
		--name alpine-darkhttpd-iso \
		-t alpine-xen-iso \
		sh -c 'make darkhttpd-pv && sh'

define DOCKER_PV_FILE
# Alpine Linux PV DomU

$(INSTALL_KERNEL)

# Path to HDD and iso file
disk = [
        'format=raw, vdev=xvda, access=w, target=$(HDD_PATH)/docker.img',
        'format=raw, vdev=xvdc, access=r, devtype=cdrom, target=$(HDD_PATH)/alpine-docker-$(branch)-x86_64.iso'
       ]

# Network configuration
vif = ['bridge=br0']

# DomU settings
memory = $(high_mem)
name = "docker"
vcpus = 3
maxvcpus = 3
endef

export DOCKER_PV_FILE

define DOCKER_GRUB
default 0
timeout 5

title alpine-docker-pv
	root (hd0,0)
	kernel /boot/vmlinuz-virthardened modules=ext4 console=hvc0 root=/dev/xvda3
	initrd /boot/initramfs-virthardened
endef

export DOCKER_GRUB

pv-docker-file:
	@echo "$$DOCKER_PV_FILE" | tee docker/docker.install.cfg

pv-docker-booted-file:
	echo "$$DOCKER_PV_FILE" | \
		sed 's|kernel = "$(HDD_PATH)/boot/boot/vmlinuz-virthardened"|kernel = \"/usr/lib/xen/boot/pv-grub-x86_64.gz\"|g' | \
		sed 's|ramdisk = "$(HDD_PATH)/boot/boot/initramfs-virthardened"||g' | \
		sed 's|extra = "modules=loop,squashfs console=hvc0"||g' | \
		tee docker/docker.cfg

pv-docker-disk:
	rm -rf $(HDD_PATH)/docker; mkdir -p $(HDD_PATH)/docker
	dd if=/dev/zero of=$(HDD_PATH)/docker.img bs=1M count=$(ONEHUNDREDGB)
	make pv-docker-file pv-docker-booted-file

define REGISTRY_PV_FILE
# Alpine Linux PV DomU

$(INSTALL_KERNEL)

# Path to HDD and iso file
disk = [
        'format=raw, vdev=xvda, access=w, target=$(HDD_PATH)/registry.img',
        'format=raw, vdev=xvdc, access=r, devtype=cdrom, target=$(HDD_PATH)/alpine-registry-$(branch)-x86_64.iso'
       ]

# Network configuration
vif = ['bridge=br0']

# DomU settings
memory = $(low_mem)
name = "registry"
vcpus = 1
maxvcpus = 1
endef

export REGISTRY_PV_FILE

define REGISTRY_GRUB
default 0
timeout 5

title alpine-registry-pv
	root (hd0,0)
	kernel /boot/vmlinuz-virthardened modules=ext4 console=hvc0 root=/dev/xvda3
	initrd /boot/initramfs-virthardened
endef

export REGISTRY_GRUB

pv-registry-file:
	@echo "$$REGISTRY_PV_FILE" | tee registry/registry.install.cfg

pv-registry-booted-file:
	echo "$$REGISTRY_PV_FILE" | \
		sed 's|kernel = "$(HDD_PATH)/boot/boot/vmlinuz-virthardened"|kernel = \"/usr/lib/xen/boot/pv-grub-x86_64.gz\"|g' | \
		sed 's|ramdisk = "$(HDD_PATH)/boot/boot/initramfs-virthardened"||g' | \
		sed 's|extra = "modules=loop,squashfs console=hvc0"||g' | \
		tee registry/registry.cfg

pv-registry-disk:
	rm -rf $(HDD_PATH)/registry; mkdir -p $(HDD_PATH)/registry
	dd if=/dev/zero of=$(HDD_PATH)/registry.img bs=1M count=$(THREEGB)
	make pv-registry-file pv-registry-booted-file

define DARKHTTPD_PV_FILE
# Alpine Linux PV DomU

$(INSTALL_KERNEL)

# Path to HDD and iso file
disk = [
        'format=raw, vdev=xvda, access=w, target=$(HDD_PATH)/darkhttpd.img',
        'format=raw, vdev=xvdc, access=r, devtype=cdrom, target=$(HDD_PATH)/alpine-darkhttpd-$(branch)-x86_64.iso'
       ]

# Network configuration
vif = ['bridge=br0']

# DomU settings
memory = $(low_mem)
name = "darkhttpd"
vcpus = 1
maxvcpus = 1
endef

export DARKHTTPD_PV_FILE

define DARKHTTPD_GRUB
default 0
timeout 5

title alpine-darkhttpd-pv
	root (hd0,0)
	kernel /boot/vmlinuz-virthardened modules=ext4 console=hvc0 root=/dev/xvda3
	initrd /boot/initramfs-virthardened
endef

export DARKHTTPD_GRUB

pv-darkhttpd-file:
	@echo "$$DARKHTTPD_PV_FILE" | tee darkhttpd/darkhttpd.install.cfg

pv-darkhttpd-booted-file:
	echo "$$DARKHTTPD_PV_FILE" | \
		sed 's|kernel = "$(HDD_PATH)/boot/boot/vmlinuz-virthardened"|kernel = \"/usr/lib/xen/boot/pv-grub-x86_64.gz\"|g' | \
		sed 's|ramdisk = "$(HDD_PATH)/boot/boot/initramfs-virthardened"||g' | \
		sed 's|extra = "modules=loop,squashfs console=hvc0"||g' | \
		tee darkhttpd/darkhttpd.cfg

pv-darkhttpd-disk:
	rm -rf $(HDD_PATH)/dockerhttpd; mkdir -p $(HDD_PATH)/darkhttpd
	dd if=/dev/zero of=$(HDD_PATH)/darkhttpd.img bs=1M count=$(THREEGB)
	make pv-darkhttpd-file pv-darkhttpd-booted-file

xgo-iso:
	docker rm -f alpine-x2go-iso; \
	docker run -d --privileged \
		-w /home/build/aports/scripts/ \
		--cap-add=SYS_ADMIN \
		--name alpine-x2go-iso \
		-t alpine-xen-iso \
		sh -c 'make xgo-pv && sh'

pv-xgo-config:
	@echo "#! /bin/sh"
	@echo "#export PROFILENAME=xgo"
	@echo "profile_xgo(){"
	@echo "    profile_standard"
	@echo "    kernel_cmdline=\"\""
	@echo "    syslinux_serial=\"0 115200\""
	@echo "    apks=$(ALPINE_XGO_PACKAGES)"
	@echo "    local _k _a"
	@echo "    for _k in \$$kernel_flavors; do"
	@echo "        apks=\"\$$apks linux-\$$_k\""
	@echo "        for _a in \$$kernel_addons; do"
	@echo "            apks=\"\$$apks \$$_a-\$$_k\""
	@echo "        done"
	@echo "    done"
	@echo "}"
	@echo ""

xgo-pv:
	sh mkimage.sh --tag $(branch) \
		--outdir ~/iso \
		--arch x86_64 \
		--repository       $(mirror)$(branch)/main \
		--extra-repository $(mirror)$(branch)/community \
		$$edge_extra_repository \
		--profile xgo

define XGO_PV_FILE
# Alpine Linux PV DomU

$(INSTALL_KERNEL)

# Path to HDD and iso file
disk = [
        'format=raw, vdev=xvda, access=w, target=$(HDD_PATH)/xgo.img',
        'format=raw, vdev=xvdc, access=r, devtype=cdrom, target=$(HDD_PATH)/alpine-xgo-$(branch)-x86_64.iso'
       ]

# Network configuration
vif = ['bridge=br0']

# DomU settings
memory = $(high_mem)
name = "xgo"
vcpus = 3
maxvcpus = 3
endef

export XGO_PV_FILE

define XGO_GRUB
default 0
timeout 5

title alpine-xgo-pv
	root (hd0,0)
	kernel /boot/vmlinuz-virthardened modules=ext4 console=hvc0 root=/dev/xvda3
	initrd /boot/initramfs-virthardened
endef

export XGO_GRUB

pv-xgo-file:
	@echo "$$XGO_PV_FILE" | tee x2go/xgo.install.cfg

pv-xgo-booted-file:
	echo "$$XGO_PV_FILE" | \
		sed 's|kernel = "$(HDD_PATH)/boot/boot/vmlinuz-virthardened"|kernel = \"/usr/lib/xen/boot/pv-grub-x86_64.gz\"|g' | \
		sed 's|ramdisk = "$(HDD_PATH)/boot/boot/initramfs-virthardened"||g' | \
		sed 's|extra = "modules=loop,squashfs console=hvc0"||g' | \
		tee x2go/xgo.cfg

pv-xgo-disk:
	rm -rf $(HDD_PATH)/xgo; mkdir -p $(HDD_PATH)/xgo
	dd if=/dev/zero of=$(HDD_PATH)/xgo.img bs=1M count=$(TENGB)
	make pv-xgo-file pv-xgo-booted-file

pv-files: pv-install-files pv-installed-files

pv-install-files: pv-darkhttpd-file pv-docker-file pv-registry-file pv-xgo-file

pv-installed-files: pv-darkhttpd-booted-file pv-docker-booted-file pv-registry-booted-file pv-xgo-booted-file

define INSTALL_KERNEL
# Kernel paths for install
kernel = "$(HDD_PATH)/boot/boot/vmlinuz-virthardened"
ramdisk = "$(HDD_PATH)/boot/boot/initramfs-virthardened"
extra = "modules=loop,squashfs console=hvc0"
endef

export INSTALL_KERNEL

HDD_PATH=/media/disk

TWOGB=2000

THREEGB=3000

TENGB=10000

TWENTYGB=20000

THIRTYGB=30000

FIFTYGB=30000

SIXTYGB=30000

ONEHUNDREDGB=100000

ONEHUNDREDFIFTYGB=150000

TWOHUNDREDGB=200000

THREEHUNDREDGB=300000

bootdir=$(HDD_PATH)/boot/

directory:
	mkdir -p $(bootdir)

mount:
	mount $(HDD_PATH)/alpine-virt-3.7.0-x86_64.iso $(HDD_PATH)/boot/; true
