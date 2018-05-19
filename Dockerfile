FROM alpine:3.7
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" | tee -a /etc/apk/repositories
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" | tee -a /etc/apk/repositories
RUN apk update && apk upgrade && apk update
RUN apk add alpine-sdk build-base apk-tools alpine-conf busybox fakeroot syslinux xorriso mtools dosfstools grub-efi make git sudo
RUN adduser -h /home/build -D build -G abuild
RUN git clone https://github.com/alpinelinux/aports /home/build/aports
ADD . /home/build/aports/scripts
RUN cd /home/build/aports && apk update
RUN chmod +x /home/build/aports/scripts/*.sh && \
        cd /home/build/aports/scripts && make config | tee /home/build/aports/scripts/mkimg.kloster.sh && \
        make pv-docker-config | tee /home/build/aports/scripts/mkimg.docker.sh && \
        make pv-docker-registry-config | tee /home/build/aports/scripts/mkimg.registry.sh && \
        make pv-darkhttpd-config | tee /home/build/aports/scripts/mkimg.darkhttpd.sh && \
        make pv-xgo-config | tee /home/build/aports/scripts/mkimg.xgo.sh && \
        chmod +x /home/build/aports/scripts/mkimg.kloster.sh /home/build/aports/scripts/mkimg.docker.sh /home/build/aports/scripts/mkimg.registry.sh /home/build/aports/scripts/mkimg.darkhttpd.sh
RUN echo 'build ALL=(ALL) NOPASSWD: ALL' | tee -a /etc/sudoers
USER build
RUN abuild-keygen -i -a
WORKDIR /home/build/aports/scripts/
RUN mkdir /home/build/iso
CMD make kloster && sh
