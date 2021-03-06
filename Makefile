
export GITHUB_RELEASE_PATH = "$(HOME)/.go/bin/github-release"

export PROFILENAME=kloster

export SIGNING_KEY=70D2060738BEF80523ACAFF7D75C03B39B5E14E1

export SEARCHTERM ?= xen

export LOCAL_PATH ?= /usr/local/bin/

export release ?=  $(shell date +%Y%W)

define ALPINE_BASE_PACKAGES
\"\$$apks iscsi-scst zfs-scripts zfs zfs-utils-py \
cciss_vol_status lvm2 mdadm mkinitfs mtools nfs-utils \
parted rsync sfdisk syslinux unrar util-linux xfsprogs \
dosfstools ntfs-3g ethtool multipath-tools linux-firmware \
openvswitch paxctl nano\"
endef

define ALPINE_SWAY_PACKAGES
\"\$$apks sway mutt htop wireless-tools mesa mesa-dri-ati mesa-dri-intel \
mesa-dri-nouveau xorg-server-xwayland xf86-input-libinput xf86-input-synaptics \
xf86-input-keyboard xf86-input-mouse xf86-input-evdev udev sudo st wayland \
weston-xwayland weston-shell-desktop\"
endef

export XEN_KERNEL=xen

#NOTES: Sway requires a pax flag(-m) to be set.


define ALPINE_XEN_PACKAGES
\"\$$apks xen xen-hypervisor xen-bridge\"
endef

define ALPINE_XGO_PACKAGES
\"\$$apks x2goserver xf86-video-ati xf86-video-nouveau xf86-video-amdgpu \
xf86-video-intel xf86-input-synaptics \
\"
endef

define ALPINE_DOCKER_PACKAGES
\"\$$apks docker\"
endef

define ALPINE_DOCKER_REGISTRY_PACKAGES
\"\$$apks docker-registry\"
endef

define ALPINE_DARKHTTPD_PACKAGES
\"\$$apks darkhttpd\"
endef

dummy:
	make list | less

list:
	@echo "Available commands"
	@echo "=================="
	@echo ""
	@grep '^[^#[:space:]].*:' Makefile config.mk pvs.mk includes.mk

pv:
	@echo "$$ALPINE_PV_FILE"

rinfo:
	@echo $(release)

clean:
	docker rm -f alpine-x2go-iso alpine-darkhttpd-iso alpine-registry-iso alpine-docker-iso alpine-xen-iso

clobber: clean
	docker rmi -f alpine-xen-iso

config:
	@echo "#! /bin/sh"
	@echo "#export PROFILENAME=kloster"
	@echo "build_xen() {"
	@echo "	apk fetch --root \"\$$APKROOT\" --stdout xen-hypervisor | tar -C \"\$$DESTDIR\" -xz boot"
	@echo "}"
	@echo "section_xen() {"
	@echo "	[ -n \"\$${xen_params+set}\" ] || return 0"
	@echo "	build_section xen \$$ARCH $(apk fetch --root \"\$$APKROOT\" --simulate xen-hypervisor | checksum)"
	@echo "}"
	@echo "profile_kloster(){"
	@echo "    profile_standard"
	@echo "    profile_xen"
	@echo "    kernel_cmdline=\"nomodeset\""
	@echo "    syslinux_serial=\"0 115200\""
	@echo "    kernel_addons=\"zfs spl\""
	@echo "    apks=$(ALPINE_BASE_PACKAGES)"
	@echo "    apks=$(ALPINE_SWAY_PACKAGES)"
	@echo "    apks=$(ALPINE_XEN_PACKAGES)"
	@echo "    apkovl='genapkovl-xen.sh'"
	@echo "    local _k _a"
	@echo "    for _k in \$$kernel_flavors; do"
	@echo "        apks=\"\$$apks linux-\$$_k\""
	@echo "        for _a in \$$kernel_addons; do"
	@echo "            apks=\"\$$apks \$$_a-\$$_k\""
	@echo "        done"
	@echo "    done"
	@echo "}"
	@echo ""

include pvs.mk
include config.mk
include edgeonly.mk

build:
	docker build --force-rm -f Dockerfile -t alpine-xen-iso .

run:
	docker rm -f alpine-xen-iso; \
	docker run -d --privileged --cap-add=SYS_ADMIN --name alpine-xen-iso -t alpine-xen-iso

dom0-iso: build run

kloster:
	sh mkimage.sh --tag $(branch) \
		--outdir ~/iso \
		--arch x86_64 \
		--repository       $(mirror)$(branch)/main \
		--extra-repository $(mirror)$(branch)/community \
		$$edge_extra_repository \
		--profile kloster

searchm:
	docker run -d --restart always --name alpine-apk-search -t alpine-xen-iso sh

search:
	docker exec -i -t alpine-apk-search apk search $(SEARCHTERM)

searchd:
	docker rm -f alpine-apk-search

install-search:
	@echo "#! /usr/bin/env sh" | tee $(LOCAL_PATH)/apk-search
	@echo "SEARCHTERM=\"\$$1\"" | tee -a $(LOCAL_PATH)/apk-search
	@echo "docker run -d --restart always --name alpine-apk-search -t alpine-xen-iso sh 1>/dev/null 2>/dev/null" | tee -a $(LOCAL_PATH)/apk-search
	@echo "docker exec -i -u root -t alpine-apk-search sh -c \"apk update; echo apk search \"\$$SEARCHTERM\"; apk search \"\$$SEARCHTERM\"\"" | tee -a $(LOCAL_PATH)/apk-search
	@echo "docker rm -f alpine-apk-search 1>/dev/null 2>/dev/null" | tee -a $(LOCAL_PATH)/apk-search
	chmod +x $(LOCAL_PATH)/apk-search


copy:
	rm -rf ./iso && mkdir iso
	docker cp alpine-xen-iso:/home/build/iso/alpine-kloster-$(branch)-x86_64.iso ./iso
	docker cp alpine-docker-iso:/home/build/iso/alpine-docker-$(branch)-x86_64.iso ./iso
	docker cp alpine-registry-iso:/home/build/iso/alpine-registry-$(branch)-x86_64.iso ./iso
	docker cp alpine-darkhttpd-iso:/home/build/iso/alpine-darkhttpd-$(branch)-x86_64.iso ./iso
	docker cp alpine-x2go-iso:/home/build/iso/alpine-xgo-$(branch)-x86_64.iso ./iso


sum:
	cd ./iso; \
	sha256sum "alpine-kloster-$(branch)-x86_64.iso" > \
		"alpine-kloster-$(branch)-x86_64.iso.sha256sum" || \
		rm alpine-kloster-$(branch)-x86_64.iso.sha256sum; \
	sha256sum "alpine-docker-$(branch)-x86_64.iso" > \
		"alpine-docker-$(branch)-x86_64.iso.sha256sum" || \
		rm alpine-docker-$(branch)-x86_64.iso.sha256sum; \
	sha256sum "alpine-registry-$(branch)-x86_64.iso" > \
		"alpine-registry-$(branch)-x86_64.iso.sha256sum" || \
		rm alpine-registry-$(branch)-x86_64.iso.sha256sum; \
	sha256sum "alpine-darkhttpd-$(branch)-x86_64.iso" > \
		"alpine-darkhttpd-$(branch)-x86_64.iso.sha256sum" || \
		rm alpine-darkhttpd-$(branch)-x86_64.iso.sha256sum; \
	sha256sum "alpine-xgo-$(branch)-x86_64.iso" > \
		"alpine-xgo-$(branch)-x86_64.iso.sha256sum" || \
		rm alpine-sgo-$(branch)-x86_64.iso.sha256sum; \
	echo sums computed

sig:
	cd ./iso; \
	gpg --batch --yes --clear-sign -u "$(SIGNING_KEY)" \
		"alpine-kloster-$(branch)-x86_64.iso.sha256sum" ; \
	gpg --batch --yes --clear-sign -u "$(SIGNING_KEY)" \
		"alpine-docker-$(branch)-x86_64.iso.sha256sum" ; \
	gpg --batch --yes --clear-sign -u "$(SIGNING_KEY)" \
		"alpine-registry-$(branch)-x86_64.iso.sha256sum" ; \
	gpg --batch --yes --clear-sign -u "$(SIGNING_KEY)" \
		"alpine-darkhttpd-$(branch)-x86_64.iso.sha256sum" ; \
	gpg --batch --yes --clear-sign -u "$(SIGNING_KEY)" \
		"alpine-xgo-$(branch)-x86_64.iso.sha256sum" ; \
	echo images signed

torrent:
	cd ./iso; \
	mktorrent -a "udp://tracker.openbittorrent.com:80" \
		-a "udp://tracker.publicbt.com:80" \
		-a "udp://tracker.istole.it:80" \
		-a "udp://tracker.btzoo.eu:80/announce" \
		-a "http://opensharing.org:2710/announce" \
		-a "udp://open.demonii.com:1337/announce" \
		-a "http://announce.torrentsmd.com:8080/announce.php" \
		-a "http://announce.torrentsmd.com:6969/announce" \
		-a "http://bt.careland.com.cn:6969/announce" \
		-a "http://i.bandito.org/announce" \
		-a "http://bttrack.9you.com/announce" \
		-w https://github.com/eyedeekay/kloster/releases/download/$(release)/alpine-kloster-$(branch)-x86_64.iso \
		"alpine-kloster-$(branch)-x86_64.iso"; \
	mktorrent -a "udp://tracker.openbittorrent.com:80" \
		-a "udp://tracker.publicbt.com:80" \
		-a "udp://tracker.istole.it:80" \
		-a "udp://tracker.btzoo.eu:80/announce" \
		-a "http://opensharing.org:2710/announce" \
		-a "udp://open.demonii.com:1337/announce" \
		-a "http://announce.torrentsmd.com:8080/announce.php" \
		-a "http://announce.torrentsmd.com:6969/announce" \
		-a "http://bt.careland.com.cn:6969/announce" \
		-a "http://i.bandito.org/announce" \
		-a "http://bttrack.9you.com/announce" \
		-w https://github.com/eyedeekay/kloster/releases/download/$(release)/alpine-docker-$(branch)-x86_64.iso \
		"alpine-docker-$(branch)-x86_64.iso"; \
	mktorrent -a "udp://tracker.openbittorrent.com:80" \
		-a "udp://tracker.publicbt.com:80" \
		-a "udp://tracker.istole.it:80" \
		-a "udp://tracker.btzoo.eu:80/announce" \
		-a "http://opensharing.org:2710/announce" \
		-a "udp://open.demonii.com:1337/announce" \
		-a "http://announce.torrentsmd.com:8080/announce.php" \
		-a "http://announce.torrentsmd.com:6969/announce" \
		-a "http://bt.careland.com.cn:6969/announce" \
		-a "http://i.bandito.org/announce" \
		-a "http://bttrack.9you.com/announce" \
		-w https://github.com/eyedeekay/kloster/releases/download/$(release)/alpine-registry-$(branch)-x86_64.iso \
		"alpine-registry-$(branch)-x86_64.iso"; \
	mktorrent -a "udp://tracker.openbittorrent.com:80" \
		-a "udp://tracker.publicbt.com:80" \
		-a "udp://tracker.istole.it:80" \
		-a "udp://tracker.btzoo.eu:80/announce" \
		-a "http://opensharing.org:2710/announce" \
		-a "udp://open.demonii.com:1337/announce" \
		-a "http://announce.torrentsmd.com:8080/announce.php" \
		-a "http://announce.torrentsmd.com:6969/announce" \
		-a "http://bt.careland.com.cn:6969/announce" \
		-a "http://i.bandito.org/announce" \
		-a "http://bttrack.9you.com/announce" \
		-w https://github.com/eyedeekay/kloster/releases/download/$(release)/alpine-darkhttpd-$(branch)-x86_64.iso \
		"alpine-darkhttpd-$(branch)-x86_64.iso"; \
	mktorrent -a "udp://tracker.openbittorrent.com:80" \
		-a "udp://tracker.publicbt.com:80" \
		-a "udp://tracker.istole.it:80" \
		-a "udp://tracker.btzoo.eu:80/announce" \
		-a "http://opensharing.org:2710/announce" \
		-a "udp://open.demonii.com:1337/announce" \
		-a "http://announce.torrentsmd.com:8080/announce.php" \
		-a "http://announce.torrentsmd.com:6969/announce" \
		-a "http://bt.careland.com.cn:6969/announce" \
		-a "http://i.bandito.org/announce" \
		-a "http://bttrack.9you.com/announce" \
		-w https://github.com/eyedeekay/kloster/releases/download/$(release)/alpine-xgo-$(branch)-x86_64.iso \
		"alpine-xgo-$(branch)-x86_64.iso"; \
	echo torrents created

delrelease:
	$(GITHUB_RELEASE_PATH) delete \
		--user eyedeekay \
		--repo kloster \
		--tag $(release); true

release:
	cd ./iso; \
	$(GITHUB_RELEASE_PATH) release \
		--user eyedeekay \
		--repo kloster \
		--tag $(release) \
		--name "kloster" \
		--description "xen distro for self hosting"

upload:
	cd ./iso; \
	$(GITHUB_RELEASE_PATH) upload --replace --user eyedeekay --repo kloster --tag $(release) \
		--name "alpine-kloster-$(branch)-x86_64.iso.sha256sum" \
		--file "alpine-kloster-$(branch)-x86_64.iso.sha256sum"; \
	$(GITHUB_RELEASE_PATH) upload --replace --user eyedeekay --repo kloster --tag $(release) \
		--name "alpine-kloster-$(branch)-x86_64.iso.sha256sum.asc" \
		--file "alpine-kloster-$(branch)-x86_64.iso.sha256sum.asc";\
	$(GITHUB_RELEASE_PATH) upload --replace --user eyedeekay --repo kloster --tag $(release) \
		--name "alpine-kloster-$(branch)-x86_64.iso.torrent" \
		--file "alpine-kloster-$(branch)-x86_64.iso.torrent";\
	$(GITHUB_RELEASE_PATH) upload --replace --user eyedeekay --repo kloster --tag $(release) \
		--name "alpine-kloster-$(branch)-x86_64.iso" \
		--file "alpine-kloster-$(branch)-x86_64.iso"; \
	$(GITHUB_RELEASE_PATH) upload --replace --user eyedeekay --repo kloster --tag $(release) \
		--name "alpine-docker-$(branch)-x86_64.iso.sha256sum" \
		--file "alpine-docker-$(branch)-x86_64.iso.sha256sum"; \
	$(GITHUB_RELEASE_PATH) upload --replace --user eyedeekay --repo kloster --tag $(release) \
		--name "alpine-docker-$(branch)-x86_64.iso.sha256sum.asc" \
		--file "alpine-docker-$(branch)-x86_64.iso.sha256sum.asc";\
	$(GITHUB_RELEASE_PATH) upload --replace --user eyedeekay --repo kloster --tag $(release) \
		--name "alpine-docker-$(branch)-x86_64.iso.torrent" \
		--file "alpine-docker-$(branch)-x86_64.iso.torrent";\
	$(GITHUB_RELEASE_PATH) upload --replace --user eyedeekay --repo kloster --tag $(release) \
		--name "alpine-docker-$(branch)-x86_64.iso" \
		--file "alpine-docker-$(branch)-x86_64.iso"; \
	$(GITHUB_RELEASE_PATH) upload --replace --user eyedeekay --repo kloster --tag $(release) \
		--name "alpine-registry-$(branch)-x86_64.iso.sha256sum" \
		--file "alpine-registry-$(branch)-x86_64.iso.sha256sum"; \
	$(GITHUB_RELEASE_PATH) upload --replace --user eyedeekay --repo kloster --tag $(release) \
		--name "alpine-registry-$(branch)-x86_64.iso.sha256sum.asc" \
		--file "alpine-registry-$(branch)-x86_64.iso.sha256sum.asc";\
	$(GITHUB_RELEASE_PATH) upload --replace --user eyedeekay --repo kloster --tag $(release) \
		--name "alpine-registry-$(branch)-x86_64.iso.torrent" \
		--file "alpine-registry-$(branch)-x86_64.iso.torrent";\
	$(GITHUB_RELEASE_PATH) upload --replace --user eyedeekay --repo kloster --tag $(release) \
		--name "alpine-registry-$(branch)-x86_64.iso" \
		--file "alpine-registry-$(branch)-x86_64.iso"; \
	$(GITHUB_RELEASE_PATH) upload --replace --user eyedeekay --repo kloster --tag $(release) \
		--name "alpine-darkhttpd-$(branch)-x86_64.iso.sha256sum" \
		--file "alpine-darkhttpd-$(branch)-x86_64.iso.sha256sum"; \
	$(GITHUB_RELEASE_PATH) upload --replace --user eyedeekay --repo kloster --tag $(release) \
		--name "alpine-darkhttpd-$(branch)-x86_64.iso.sha256sum.asc" \
		--file "alpine-darkhttpd-$(branch)-x86_64.iso.sha256sum.asc";\
	$(GITHUB_RELEASE_PATH) upload --replace --user eyedeekay --repo kloster --tag $(release) \
		--name "alpine-darkhttpd-$(branch)-x86_64.iso.torrent" \
		--file "alpine-darkhttpd-$(branch)-x86_64.iso.torrent";\
	$(GITHUB_RELEASE_PATH) upload --replace --user eyedeekay --repo kloster --tag $(release) \
		--name "alpine-darkhttpd-$(branch)-x86_64.iso" \
		--file "alpine-darkhttpd-$(branch)-x86_64.iso"; \
	$(GITHUB_RELEASE_PATH) upload --replace --user eyedeekay --repo kloster --tag $(release) \
		--name "alpine-xgo-$(branch)-x86_64.iso.sha256sum" \
		--file "alpine-xgo-$(branch)-x86_64.iso.sha256sum"; \
	$(GITHUB_RELEASE_PATH) upload --replace --user eyedeekay --repo kloster --tag $(release) \
		--name "alpine-xgo-$(branch)-x86_64.iso.sha256sum.asc" \
		--file "alpine-xgo-$(branch)-x86_64.iso.sha256sum.asc";\
	$(GITHUB_RELEASE_PATH) upload --replace --user eyedeekay --repo kloster --tag $(release) \
		--name "alpine-xgo-$(branch)-x86_64.iso.torrent" \
		--file "alpine-xgo-$(branch)-x86_64.iso.torrent";\
	$(GITHUB_RELEASE_PATH) upload --replace --user eyedeekay --repo kloster --tag $(release) \
		--name "alpine-xgo-$(branch)-x86_64.iso" \
		--file "alpine-xgo-$(branch)-x86_64.iso"; \


docker-build:
	git pull; \
	make build

compile:
	make run; \
	make docker-iso; \
	make docker-registry-iso; \
	make darkhttpd-iso; \
	make xgo-iso; \
	true

rerelease: copy delrelease sum sig torrent release upload

docker-release:
	make docker-build; sleep 1h; make copy
	make rerelease

wget:
	wget -c https://github.com/eyedeekay/kloster/releases/download/201801/alpine-xgo-v3.7-x86_64.iso; true
	wget -c https://github.com/eyedeekay/kloster/releases/download/201801/alpine-registry-v3.7-x86_64.iso; true
	wget -c https://github.com/eyedeekay/kloster/releases/download/201801/alpine-docker-v3.7-x86_64.iso; true
	wget -c https://github.com/eyedeekay/kloster/releases/download/201801/alpine-darkhttpd-v3.7-x86_64.iso; true
	wget -c http://dl-cdn.alpinelinux.org/alpine/v3.7/releases/x86_64/alpine-virt-3.7.0-x86_64.iso; true

install: wget pv-files
	cp darkhttpd/*.cfg /etc/xen
	cp docker/*.cfg /etc/xen
	cp registry/*.cfg /etc/xen
	cp x2go/*.cfg /etc/xen

copy-disks:
	cp *.iso $(HDD_PATH)

autostart-docker:
	cp /etc/xen/docker.cfg /etc/xen/auto

docker-xl-create: directory docker-mount
	xl create /etc/xen/docker.install.cfg -c # 'setup-alpine'
	umount -f /media/disk/boot

registry-xl-create: directory mount registry-mount
	xl create /etc/xen/registry.install.cfg -c # 'setup-alpine'
	umount -f /media/disk/boot

darkhttpd-xl-create: directory darkhttpd-mount
	xl create /etc/xen/darkhttpd.install.cfg -c # 'setup-alpine'
	umount -f /media/disk/boot

xgo-xl-create: directory xgo-mount
	xl create /etc/xen/xgo.install.cfg -c # 'setup-alpine'
	umount -f /media/disk/boot
