
export mirror = http://dl-cdn.alpinelinux.org/alpine/
#export branch = edge
export branch = v3.7

#export extra_repository = "--extra-repository http://dl-cdn.alpinelinux.org/alpine/edge/main"

define edge_extra_repository
--extra-repository http://dl-cdn.alpinelinux.org/alpine/edge/main
--extra-repository http://dl-cdn.alpinelinux.org/alpine/edge/community
--extra-repository http://dl-cdn.alpinelinux.org/alpine/edge/testing
endef

export edge_extra_repository

export low_mem = 512
export med_mem = 2048
export high_mem = 6144
export super_high_mem = 12288
