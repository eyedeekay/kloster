
export mirror = http://dl-cdn.alpinelinux.org/alpine/
#export branch = edge
export branch = v3.6

define edge_extra_repository
--extra-repository http://dl-cdn.alpinelinux.org/alpine/v3.6/main
--extra-repository http://dl-cdn.alpinelinux.org/alpine/v3.6/community
endef

export edge_extra_repository
