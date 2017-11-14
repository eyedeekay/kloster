
export GITHUB_RELEASE_PATH = "$(HOME)/.go/bin/github-release"

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

sum:
	cd ./iso; \
	sha256sum "alpine-kloster-edge-x86_64.iso" > \
		"alpine-kloster-edge-x86_64.iso.sha256sum" || \
		rm alpine-kloster-edge-x86_64.iso.sha256sum; \
	@echo sums computed

sig:
	gpg --batch --yes --clear-sign -u "$(SIGNING_KEY)" \
		"alpine-kloster-edge-x86_64.iso.sha256sum" ; \
	@echo images signed

torrent:
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
	@echo torrents created

release:
	$(GITHUB_RELEASE_PATH) release \
		--user eyedeekay \
		--repo closter \
		--tag $(release) \
		--name "kloster" \
		--description "xen distro for self hosting"

upload:
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

