FROM alpine:latest
ARG username
RUN apk --update upgrade \
    && apk add --virtual build-essentials alpine-sdk linux-headers tcl \
    && adduser -G wheel -D -h /home/$username $username \
    && echo "%wheel ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && chown -R $username: /home/$username