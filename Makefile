USER={USER:=$$USER}
__QEMU_TARGETS__=""
__QEMU_FLAGS__=""

build_python_urlib3:
	sudo pip install urllib3[secure] ndg-httpsclient

build_python_shyaml:
	sudo pip install shyaml

build_python: build_python_urlib3 build_python_shyaml

build_qemu_targets:
	for i in `cat .qemu.yml | shyaml get-value arches` ; do \
		for j in `cat .qemu.yml | shyaml get-value targets` ; do \
			$__QEMU_TARGETS__ = "$i-$j " ; \
		done \
	done
	export QEMU_TARGETS=${__QEMU_TARGETS__}

build_qemu_flags:
	for i in "--prefix=/home/$$USER/qemu" \
					 "--target-list=$$QEMU_TARGETS" \
		       "--enable-debug" \
					 "--disable-docs" \
					 "--disable-sdl" \
					 "--disable-gtk" \
				   "--disable-gnutls" \
					 "--disable-gcrypt" \
					 "--disable-nettle" \
					 "--disable-curses" \
					 "--static" ; do \
		__QEMU_FLAGS__ = $__QEMU_FLAGS__" $i" ; \
	done
	export QEMU_FLAGS=${__QEMU_FLAGS__}

build_qemu_build:
	git clone https://git.qemu.org/git/qemu.git $$HOME/qemu	
	cd $HOME/qemu
	bash -e ./configure $$QEMU_FLAGS
	make -j4
	make install
	echo `cat .qemu.yml | shyaml get-value version `" "$$QEMU_TARGETS > /home/$$USER/qemu/.build
	export PATH=$$PATH:/home/$$USER/qemu/bin

build_qemu: build_qemu_targets build_qemu_flags

build: build_python build_qemu

env:
	for i in cat .qemu.yml | shyaml get-value env ; do \
			qemu-$$QEMU_ARCHES export $i ; \
	done

before_install:
	for i in cat .qemu.yml | shyaml get-value before_install ; do \
			qemu-$$QEMU_ARCHES $i ; \
	done

install:
	for i in cat .qemu.yml | shyaml get-value install ; do \
			qemu-$$QEMU_ARCHES $i ; \
	done

after_install:
	for i in cat .qemu.yml | shyaml get-value after_install ; do \
			qemu-$$QEMU_ARCHES $i ; \
	done

before_script:
	for i in cat .qemu.yml | shyaml get-value before_script ; do \
			qemu-$$QEMU_ARCHES $i ; \
	done

script:
	for i in cat .qemu.yml | shyaml get-value script ; do \
			qemu-$$QEMU_ARCHES $i ; \
	done

after_success:
	for i in cat .qemu.yml | shyaml get-value after_success ; do \
			qemu-$$QEMU_ARCHES $i ; \
	done
