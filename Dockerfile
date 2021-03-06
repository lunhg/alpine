FROM alpine:latest
ARG username
RUN apk --update upgrade \
    && apk add --virtual build-essentials build-base linux-headers binutils-gold gnupg libgcc libstdc++ make xz python tcl curl \
    && adduser -G wheel -D -h /home/$username $username \
    && echo "%wheel ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && chown -R $username: /home/$username