FROM alpine:latest
ARG username
apk --update upgrade \
    && apk add --virtual build-essentials build-base gpg linux-headers binutils-gold gnupg libgcc libstc++ make xz python tcl \
    && adduser -G wheel -D -h /home/$username $username \
    && echo "%wheel ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && chown -R $username: /home/$username