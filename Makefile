USER={USER:=$$USER}
DOCKER_COMPOSE_URL:=https://github.com/docker/compose/releases/download/$$DOCKER_COMPOSE_VERSION/docker-compose-`uname -s`-`uname -m`
VERSION={$$QEMU_VERSION:=3.0.0}
ARCHES={$$QEMU_ARCHES:=arm aarch64 i386 x86_64}
TARGETS={$$QEMU_TARGETS:=$(echo $ARCHES | sed 's#$# #;s#\([^ ]*\) #\1-softmmu \1-linux-user #g')}

build_python_urlib3:
	python -c "import urllib3; urllib3.disable_warnings()"
	sudo pip install urllib3 --upgrade
	sudo pip install urllib3[secure] --upgrade
	python -c "import urllib3.contrib.pyopenssl; urllib3.contrib.pyopenssl.inject_into_urllib3()"

build_python_shyaml:
	sudo pip install shyaml

build_python: build_python_urlib3 build_python_shyaml

build_qemu:
	git clone https://git.qemu.org/git/qemu.git $$HOME/qemu
	if echo "$VERSION $TARGETS" | cmp --silent $HOME/qemu/.build -; then echo "==> qemu $VERSION up to date!" && exit 0 ; fi
	echo "VERSION: $VERSION"
	echo "TARGETS: $TARGETS"
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
