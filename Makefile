USER={USER:=$$USER}

build_python_urlib3:
	sudo pip install urllib3[secure] ndg-httpsclient

build_python_shyaml:
	sudo pip install shyaml

build_python: build_python_urlib3 build_python_shyaml

build_qemu_targets:
	export QEMU_TARGETS=""
	for i in `cat .qemu.yml | shyaml get-value arches` ; do \
		for j in `cat .qemu.yml | shyaml get-value targets` ; do \
			export QEMU_TARGETS+=$$QEMU_TARGETS"  "$i-$j ; \
		done \
	done

build_qemu_flags:
	export QEMU_FLAGS=""
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
		export QEMU_FLAGS = $$QEMU_FLAGS" "$i ; \
	done

build_qemu_build:
	git clone https://git.qemu.org/git/qemu.git $$HOME/qemu	
	cd $HOME/qemu
	bash -e ./configure $$QEMU_FLAGS
	make -j4
	make install
	__QEMU_BUILD__=""
	for i in `cat .qemu.yml | shyaml get-value version`
			$$QEMU_TARGETS ; do \
		__QEMU_BUILD__="${__QEMU_BUILD__} ${i}" ; \
	done
	echo "${__QEMU_BUILD__}" > /home/$$USER/qemu/.build
	export QEMU_BUILD=/home/$$USER/qemu/.build
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
