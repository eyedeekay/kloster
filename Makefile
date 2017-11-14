
export GITHUB_RELEASE_PATH = "$(HOME)/.go/bin/github-release"

export PROFILENAME=kloster

export SIGNING_KEY=70D2060738BEF80523ACAFF7D75C03B39B5E14E1

export SEARCHTERM ?= xen

export LOCAL_PATH ?= /usr/local/bin/

define ALPINE_BASE_PACKAGES
\"\$$apks iscsi-scst zfs-scripts zfs zfs-utils-py \
cciss_vol_status lvm2 mdadm mkinitfs mtools nfs-utils \
parted rsync sfdisk syslinux unrar util-linux xfsprogs \
dosfstools ntfs-3g ethtool multipath-tools linux-firmware \
openvswitch sway mutt nano htop wireless-tools\"
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
	@echo "docker exec -i -t alpine-apk-search apk search \$$SEARCHTERM" | tee -a $(LOCAL_PATH)/apk-search
	@echo "docker rm -f alpine-apk-search 1>/dev/null 2>/dev/null" | tee -a $(LOCAL_PATH)/apk-search
	chmod +x $(LOCAL_PATH)/apk-search


copy:
	rm -rf ./iso
	docker cp alpine-xen-iso:/home/build/iso/ ./iso

sum:
	cd ./iso; \
	sha256sum "alpine-kloster-edge-x86_64.iso" > \
		"alpine-kloster-edge-x86_64.iso.sha256sum" || \
		rm alpine-kloster-edge-x86_64.iso.sha256sum; \
	echo sums computed

sig:
	cd ./iso; \
	gpg --batch --yes --clear-sign -u "$(SIGNING_KEY)" \
		"alpine-kloster-edge-x86_64.iso.sha256sum" ; \
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
		-w https://github.com/eyedeekay/kloster/releases/download/$(release)/alpine-kloster-edge-x86_64.iso \
		"alpine-kloster-edge-x86_64.iso"; \
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
	$(GITHUB_RELEASE_PATH) upload --user eyedeekay --repo kloster --tag $(release) \
		--name "alpine-kloster-edge-x86_64.iso.sha256sum" \
		--file "alpine-kloster-edge-x86_64.iso.sha256sum"; \
	$(GITHUB_RELEASE_PATH) upload --user eyedeekay --repo kloster --tag $(release) \
		--name "alpine-kloster-edge-x86_64.iso.sha256sum.asc" \
		--file "alpine-kloster-edge-x86_64.iso.sha256sum.asc";\
	$(GITHUB_RELEASE_PATH) upload --user eyedeekay --repo kloster --tag $(release) \
		--name "alpine-kloster-edge-x86_64.iso.torrent" \
		--file "alpine-kloster-edge-x86_64.iso.torrent";\
	$(GITHUB_RELEASE_PATH) upload --user eyedeekay --repo kloster --tag $(release) \
		--name "alpine-kloster-edge-x86_64.iso" \
		--file "alpine-kloster-edge-x86_64.iso"; \

docker-build: build run

rerelease:
	make delrelease
	make sum
	make sig
	make torrent
	make release
	make upload

docker-release:
	make docker-build; sleep 10m; make copy
	make rerelease


