qemu:
  chmod +x ./travis-qemu.sh
  ./travis-qemu.sh
  export PATH=$PATH:$HOME/qemu/bin

docker_compose:
	@curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > docker-compose
  chmod +x docker-compose

versions:
	docker -v
  docker-compose -v
	qemu-$QEMU_ARCHES --version

install: qemu docker_compose versions

build:
	qemu-$QEMU_ARCHES docker-compose up -d alpine

print:
	qemu-$QEMU_ARCHES docker-compose ps alpine
  qemu-$QEMU_ARCHES docker-compose logs alpine

push:
  qemu-$QEMU_ARCHES docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
