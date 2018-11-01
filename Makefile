USER={USER:=$$USER}

build_python_urlib3:
	sudo pip install --upgrade
	pip --version
	sudo pip install urllib3[secure] ndg-httpsclient

build_python_shyaml:
	sudo pip install shyaml

build_python: build_python_urlib3 build_python_shyaml

build_qemu:
	export QEMU_ARCHES=`cat .qemu.yml | shyaml get-value qemu.arch`
	git clone https://git.qemu.org/git/qemu.git $$HOME/qemu	
	cd $HOME/qemu
	bash -e ./configure \
		--prefix="$HOME/qemu" \
		--target-list=`cat .qemu.yml | shyaml get-value qemu.targes` \
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
	echo  `cat .qemu.yml | shyaml get-value qemu.version` `cat .qemu.yml | shyaml get-value qemu.targes` > $HOME/qemu/.build
	export PATH=$$PATH:$HOME/qemu/bin

build: build_python build_qemu

env:
	for i in cat .qemu.yml | shyaml get-value qemu.env ; do \
			qemu-$$QEMU_ARCHES export $i ; \
	done

before_install:
	for i in cat .qemu.yml | shyaml get-value qemu.before_install ; do \
			qemu-$$QEMU_ARCHES $i ; \
	done

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
