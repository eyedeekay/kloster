pv-docker-config:
	@echo "#! /bin/sh" | tee
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
		$(extra_repository) \
		--profile docker

pv-docker-registry-config:
	@echo "#! /bin/sh" | tee
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
		$(extra_repository) \
		--profile registry

pv-darkhttpd-config:
	@echo "#! /bin/sh" | tee
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
		$(extra_repository) \
		--profile darkhttpd

docker-iso:
	docker rm -f alpine-docker-iso; \
	docker run -d --privileged \
		-w /home/build/aports/scripts/ \
		--cap-add=SYS_ADMIN \
		--name alpine-docker-iso \
		-t alpine-xen-iso make docker-pv

docker-registry-iso:
	docker rm -f alpine-registry-iso; \
	docker run -d --privileged \
		-w /home/build/aports/scripts/ \
		--cap-add=SYS_ADMIN \
		--name alpine-registry-iso \
		-t alpine-xen-iso \
		make docker-registry-pv

darkhttpd-iso:
	docker rm -f alpine-darkhttpd-iso; \
	docker run -d --privileged \
		-w /home/build/aports/scripts/ \
		--cap-add=SYS_ADMIN \
		--name alpine-darkhttpd-iso \
		-t alpine-xen-iso \
		make darkhttpd-pv
