FROM alpine:edge
RUN apk update
RUN apk add alpine-sdk build-base apk-tools alpine-conf busybox fakeroot syslinux xorriso mtools dosfstools grub-efi make git sudo
RUN adduser -h /home/build -D build -G abuild
RUN git clone https://github.com/eyedeekay/aports /home/build/aports
ADD . /home/build/config
RUN cd /home/build/aports && apk update
RUN chmod +x /home/build/aports/scripts/*.sh && \
        cd /home/build/config && make config | tee /home/build/aports/scripts/mkimg.kloster.sh && \
        chmod +x /home/build/aports/scripts/mkimg.kloster.sh
RUN echo 'livebuilder ALL=(ALL) NOPASSWD: ALL' | tee -a /etc/sudoers
USER build
RUN abuild-keygen -i -a
WORKDIR /home/build/aports/scripts/
RUN mkdir /home/build/iso
CMD sh mkimage.sh --tag edge \
	--outdir ~/iso \
	--arch x86_64 \
	--repository       http://dl-cdn.alpinelinux.org/alpine/edge/main \
        --extra-repository http://dl-cdn.alpinelinux.org/alpine/edge/community \
        --extra-repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
	--profile kloster
