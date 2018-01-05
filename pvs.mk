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

# Kernel paths for install
kernel = "iso/docker/boot/vmlinuz-virtgrsec"
ramdisk = "iso/docker/boot/initramfs-virtgrsec"
extra="modules=loop,squashfs console=hvc0"

# Path to HDD and iso file
disk = [
        'format=raw, vdev=xvda, access=w, target=iso/docker.img',
        'format=raw, vdev=xvdc, access=r, devtype=cdrom, target=iso/alpine-docker-$(branch)-x86_64.iso'
       ]

# Network configuration
vif = ['bridge=br0']

# DomU settings
memory = $(low_mem)
name = "docker"
vcpus = 1
maxvcpus = 1
endef

export DOCKER_PV_FILE

define DOCKER_PV_FILE_STAGE
# Alpine Linux PV DomU

# Kernel paths for install
kernel = "/usr/lib/xen/boot/pv-grub-x86_64.gz"

# Path to HDD and iso file
disk = [
        'format=raw, vdev=xvda, access=w, target=iso/docker.img'
       ]

# Network configuration
vif = ['bridge=br0']

# DomU settings
memory = $(low_mem)
name = "docker"
vcpus = 1
maxvcpus = 1
endef

export DOCKER_PV_FILE_STAGE

define DOCKER_GRUB
default 0
timeout 5

title alpine-docker-pv
	root (hd0,0)
	kernel /boot/vmlinuz-virtgrsec modules=ext4 console=hvc0 root=/dev/xvda3
	initrd /boot/initramfs-virtgrsec
endef

export DOCKER_GRUB

pv-docker-file:
	@echo "$$DOCKER_PV_FILE" | tee docker.cfg

pv-docker-disk:
	rm -rf iso/docker; mkdir -p iso/docker
	sudo -E mount -t iso9660 -o loop iso/alpine-docker-$(branch)-x86_64.iso iso/docker
	dd if=/dev/zero of=iso/docker.img bs=1M count=3000
	make pv-docker-file

define REGISTRY_PV_FILE
# Alpine Linux PV DomU

# Kernel paths for install
kernel = "iso/registry/boot/vmlinuz-virtgrsec"
ramdisk = "iso/registry/boot/initramfs-virtgrsec"
extra="modules=loop,squashfs console=hvc0"

# Path to HDD and iso file
disk = [
        'format=raw, vdev=xvda, access=w, target=iso/registry.img',
        'format=raw, vdev=xvdc, access=r, devtype=cdrom, target=iso/alpine-registry-$(branch)-x86_64.iso'
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

define REGISTRY_PV_FILE_STAGE
# Alpine Linux PV DomU

# Kernel paths for install
kernel = "/usr/lib/xen/boot/pv-grub-x86_64.gz"

# Path to HDD and iso file
disk = [
        'format=raw, vdev=xvda, access=w, target=iso/registry.img'
       ]

# Network configuration
vif = ['bridge=br0']

# DomU settings
memory = $(low_mem)
name = "registry"
vcpus = 1
maxvcpus = 1
endef

export REGISTRY_PV_FILE_STAGE

define REGISTRY_GRUB
default 0
timeout 5

title alpine-registry-pv
	root (hd0,0)
	kernel /boot/vmlinuz-virtgrsec modules=ext4 console=hvc0 root=/dev/xvda3
	initrd /boot/initramfs-virtgrsec
endef

export REGISTRY_GRUB

pv-registry-file:
	@echo "$$REGISTRY_PV_FILE" | tee registry.cfg

pv-registry-disk:
	rm -rf iso/registry; mkdir -p iso/registry
	sudo -E mount -t iso9660 -o loop iso/alpine-registry-$(branch)-x86_64.iso iso/registry
	dd if=/dev/zero of=iso/registry.img bs=1M count=3000

define DARKHTTPD_PV_FILE
# Alpine Linux PV DomU

# Kernel paths for install
kernel = "iso/darkhttpd/boot/vmlinuz-virtgrsec"
ramdisk = "iso/darkhttpd/boot/initramfs-virtgrsec"
extra="modules=loop,squashfs console=hvc0"

# Path to HDD and iso file
disk = [
        'format=raw, vdev=xvda, access=w, target=iso/darkhttpd.img',
        'format=raw, vdev=xvdc, access=r, devtype=cdrom, target=iso/alpine-darkhttpd-$(branch)-x86_64.iso'
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

define DARKHTTPD_PV_FILE_STAGE
# Alpine Linux PV DomU

# Kernel paths for install
kernel = "/usr/lib/xen/boot/pv-grub-x86_64.gz"

# Path to HDD and iso file
disk = [
        'format=raw, vdev=xvda, access=w, target=iso/darkhttpd.img'
       ]

# Network configuration
vif = ['bridge=br0']

# DomU settings
memory = $(low_mem)
name = "darkhttpd"
vcpus = 1
maxvcpus = 1
endef

export DARKHTTPD_PV_FILE_STAGE

define DARKHTTPD_GRUB
default 0
timeout 5

title alpine-darkhttpd-pv
	root (hd0,0)
	kernel /boot/vmlinuz-virtgrsec modules=ext4 console=hvc0 root=/dev/xvda3
	initrd /boot/initramfs-virtgrsec
endef

export DARKHTTPD_GRUB

pv-darkhttpd-file:
	@echo "$$DARKHTTPD_PV_FILE" | tee darkhttpd.cfg

pv-darkhttpd-disk:
	rm -rf iso/dockerhttpd; mkdir -p iso/darkhttpd
	sudo -E mount -t iso9660 -o loop iso/alpine-darkhttpd-$(branch)-x86_64.iso iso/darkhttpd
	dd if=/dev/zero of=iso/darkhttpd.img bs=1M count=3000
	make pv-darkhttpd-file


xgo-iso:
	docker rm -f alpine-xgo-iso; \
	docker run -d --privileged \
		-w /home/build/aports/scripts/ \
		--cap-add=SYS_ADMIN \
		--name alpine-xgo-iso \
		-t alpine-xen-iso sh -c 'make xgo-pv && sh'

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

# Kernel paths for install
kernel = "iso/xgo/boot/vmlinuz-virtgrsec"
ramdisk = "iso/xgo/boot/initramfs-virtgrsec"
extra="modules=loop,squashfs console=hvc0"

# Path to HDD and iso file
disk = [
        'format=raw, vdev=xvda, access=w, target=iso/xgo.img',
        'format=raw, vdev=xvdc, access=r, devtype=cdrom, target=iso/alpine-xgo-$(branch)-x86_64.iso'
       ]

# Network configuration
vif = ['bridge=br0']

# DomU settings
memory = $(high_mem)
name = "xgo"
vcpus = 1
maxvcpus = 1
endef

export XGO_PV_FILE

define XGO_PV_FILE_STAGE
# Alpine Linux PV DomU

# Kernel paths for install
kernel = "/usr/lib/xen/boot/pv-grub-x86_64.gz"

# Path to HDD and iso file
disk = [
        'format=raw, vdev=xvda, access=w, target=iso/xgo.img'
       ]

# Network configuration
vif = ['bridge=br0']

# DomU settings
memory = $(high_mem)
name = "xgo"
vcpus = 1
maxvcpus = 1
endef

export XGO_PV_FILE_STAGE

define XGO_GRUB
default 0
timeout 5

title alpine-xgo-pv
	root (hd0,0)
	kernel /boot/vmlinuz-virtgrsec modules=ext4 console=hvc0 root=/dev/xvda3
	initrd /boot/initramfs-virtgrsec
endef

export XGO_GRUB

pv-xgo-file:
	@echo "$$XGO_PV_FILE" | tee xgo.cfg

pv-xgo-disk:
	rm -rf iso/xgo; mkdir -p iso/xgo
	sudo -E mount -t iso9660 -o loop iso/alpine-xgo-$(branch)-x86_64.iso iso/xgo
	dd if=/dev/zero of=iso/xgo.img bs=1M count=10000
	make pv-xgo-file
