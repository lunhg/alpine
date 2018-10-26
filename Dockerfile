FROM alpine:latest
ARG username
ENV POOLS="ipv4.pool.sks-keyservers.net keyserver.pgp.com ha.pool.sks-keyservers.net"
ENV KEYS="94AE36675C464D64BAFA68DD7434390BDBE9B9C5 B9AE9905FFD7803F25714661B63B535A4C206CA9 77984A986EBC2AA786BC0F66B01FBB92821C587A 71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 FD3A5288F042B6850C66B31F09FE44734EB7990E 8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 DD8F2338BAE7501E3DD5AC78C273792F7D83545D 6A010C5166006599AA17F08146C2130DFD2497F5"
RUN for server in $POOLS; do gpg --keyserver $server --recv-keys $KEYS && break ; done \
    && apk --update upgrade \
    && apk add --virtual build-essentials alpine-sdk linux-headers binutils-gold gnupg libgcc libstc++ make xz python tcl \
    && adduser -G wheel -D -h /home/$username $username \
    && echo "%wheel ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && chown -R $username: /home/$username