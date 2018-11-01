URL:=https://github.com/docker/compose/releases/download/$$DOCKER_COMPOSE_VERSION/docker-compose-`uname -s`-`uname -m`

install:
	chmod +x ./travis-qemu.sh
	./travis-qemu.sh

build:
	qemu-$$QEMU_ARCHES apt-get install curl
	sudo qemu-$$QEMU_ARCHES curl -L ${URL} > /usr/bin/docker-compose
	chmod +x /usr/bin/docker-compose
	qemu-$$QEMU_ARCHES docker-compose up -d alpine

print:
	qemu-$$QEMU_ARCHES docker-compose ps alpine
	qemu-$$QEMU_ARCHES docker-compose logs alpine

push:
	qemu-$$QEMU_ARCHES docker login -u $$DOCKER_USERNAME -p $$DOCKER_PASSWORD
	qemu-$$QEMU_ARCHES docker-compose push alpine
