
export PROFILENAME=kloster

define ALPINE_BASE_PACKAGES
\"\$$apks iscsi-scst zfs-scripts zfs zfs-utils-py \
cciss_vol_status lvm2 mdadm mkinitfs mtools nfs-utils \
parted rsync sfdisk syslinux unrar util-linux xfsprogs \
dosfstools ntfs-3g ethtool multipath-tools linux-firmware \
openvswitch sway mutt nano\"
endef

define ALPINE_XEN_PACKAGES
\"\$$apks xen\"
endef

list:
	@echo ""
	@echo ""
	@echo ""

config:
	@echo "#! /bin/sh" | tee
	@echo "#export PROFILENAME=kloster"
	@echo "profile_kloster(){"
	@echo "    profile_standard"
	@echo "    kernel_cmdline=\"\""
	@echo "    syslinux_serial=\"0 115200\""
	@echo "    kernel_addons=\"zfs spl\""
	@echo "    apks=$(ALPINE_BASE_PACKAGES)"
	@echo "    apks=$(ALPINE_XEN_PACKAGES)"
	@echo "    local _k _a"
	@echo "    for _k in \$$kernel_flavors; do"
	@echo "        apks=\"\$$apks linux-\$$_k\""
	@echo "        for _a in \$$kernel_addons; do"
	@echo "            apks=\"\$$apks \$$_a-\$$_k\""
	@echo "        done"
	@echo "    done"
	@echo "}"
	@echo ""

build:
	docker build --rm -f Dockerfile -t alpine-xen-iso .

run:
	docker rm -f alpine-xen-iso; \
	docker run -d --privileged --cap-add=SYS_ADMIN --name alpine-xen-iso -t alpine-xen-iso

copy:
	rm -rf ./iso
	docker cp alpine-xen-iso:/home/build/iso/ ./iso

docker-build: build run

