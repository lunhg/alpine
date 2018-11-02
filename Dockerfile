FROM forumi0721/alpine-aarch64-base
ARG username
RUN apk --update upgrade \
    && apk add --virtual build-essentials build-base linux-headers binutils-gold gnupg libgcc libstdc++ make xz python tcl curl \
    && p
