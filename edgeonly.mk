## This makefile contains instructions for creating iso's that demand the edge
#repo of Alpine linux. As packages are added to stable branches, they will be
#moved
export edge_branch = edge
xgo-iso:
	docker rm -f alpine-xgo-iso; \
	docker run -d --privileged \
		-w /home/build/aports/scripts/ \
		--cap-add=SYS_ADMIN \
		--name alpine-xgo-iso \
		-t alpine-xen-iso make xgo-pv

pv-xgo-config:
	@echo "#! /bin/sh" | tee
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
	sh mkimage.sh --tag $(edge_branch) \
		--outdir ~/iso \
		--arch x86_64 \
		--repository       $(mirror)$(edge_branch)/main \
		--extra-repository $(mirror)$(edge_branch)/community \
		--extra-repository $(mirror)$(edge_branch)/testing \
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
	mount -t iso9660 -o loop iso/alpine-xgo-$(branch)-x86_64.iso iso/xgo
	dd if=/dev/zero of=iso/xgo.img bs=1M count=10000
	make pv-xgo-file
