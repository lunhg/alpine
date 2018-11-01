USER={USER:=$$USER}
DOCKER_COMPOSE_URL:=https://github.com/docker/compose/releases/download/$$DOCKER_COMPOSE_VERSION/docker-compose-`uname -s`-`uname -m`

build_python_urlib3:
	sudo apt-get install python-pip
	sudo pip install --upgrade --index-url=https://pypi.python.org/simple/ pip==8.1.2
	pip --version
	sudo pip install urllib3[secure] ndg-httpsclient

build_python_shyaml:
	sudo pip install shyaml

build_python: build_python_urlib3 build_python_shyaml

build_qemu:
	git clone https://git.qemu.org/git/qemu.git $$HOME/qemu
	VERSION=`cat .qemu.yml | shyaml get-value qemu.version`
	ARCHES=`cat .qemu.yml | shyaml get-value qemu.arches`
  TARGETS=`cat .qemu.yml | shyaml get value qemu.targets`;
	echo "QEMU $VERSION: $ARCHES $TARGETS"
	cd $HOME/qemu
	./configure \
		--prefix="$HOME/qemu" \
		--target-list="$TARGETS" \
		--enable-debug \
		--disable-docs \
		--disable-sdl \
		--disable-gtk \
		--disable-gnutls \
		--disable-gcrypt \
		--disable-nettle \
		--disable-curses \
		--static
	make -j4
	make install
	echo "$VERSION $TARGETS" > $HOME/qemu/.build
	export PATH=$$PATH:$HOME/qemu/bin

build: build_python build_qemu

install:
	for i in cat .qemu.yml | shyaml get-value qemu.install ; do \
			qemu-$$QEMU_ARCHES $i ; \
	done

after_install:
	for i in cat .qemu.yml | shyaml get-value qemu.after_install ; do \
			qemu-$$QEMU_ARCHES $i ; \
	done

before_script:
	for i in cat .qemu.yml | shyaml get-value qemu.before_script ; do \
			qemu-$$QEMU_ARCHES $i ; \
	done

script:
	for i in cat .qemu.yml | shyaml get-value qemu.script ; do \
			qemu-$$QEMU_ARCHES $i ; \
	done

after_success:
	for i in cat .qemu.yml | shyaml get-value qemu.after_success ; do \
			qemu-$$QEMU_ARCHES $i ; \
	done
