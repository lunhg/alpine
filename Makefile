qemu:
	chmod +x ./travis-qemu.sh
	./travis-qemu.sh

docker_compose:
	mkdir -p $$HOME/docker-compose
	mkdir -p $$HOME/docker-compose/bin
	curl -L https://github.com/docker/compose/releases/download/$$DOCKER_COMPOSE_VERSION/docker-compose-`uname -s`-`uname -m` > $$HOME/docker-compose/bin/docker-compose
	chmod +x $$HOME/docker-compose/bin/docker-compose

versions:
	docker -v
	docker-compose -v
	qemu-$$QEMU_ARCHES --version

install: qemu docker_compose versions

build:
	qemu-$$QEMU_ARCHES docker-compose up -d alpine

print:
	qemu-$$QEMU_ARCHES docker-compose ps alpine
	qemu-$$QEMU_ARCHES docker-compose logs alpine

push:
	qemu-$$QEMU_ARCHES docker login -u $$DOCKER_USERNAME -p $$DOCKER_PASSWORD
	qemu-$$QEMU_ARCHES docker-compose push alpine
