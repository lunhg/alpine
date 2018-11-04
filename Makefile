USER={USER:=$$USER}
ARCHES=""
TARGETS=""
clean:
	if [ -d $$PWD/bin ] ; then \
		rm -rf $$PWD/bin ; \
	fi

install: clean
	pip install --user -U pip
	pip install --user shyaml
	export QEMU_ARCHES=`cat .qemu.yml | shyaml get-value arches | sed -E 's|-\s(.+)|\1|g'`
	export QEMU_TARGETS=`cat .qemu.yml | shyaml get-value targets | sed -E 's|-\s(.+)|\1|g'`
	export QEMU_ENVS=`cat .qemu.yml | shyaml get-value env | sed -E 's|-\s(.+)|\1|g'`
	export QEMU_NAME=`cat /proc/sys/kernel/random/uuid`

after_install:
	@docker run --rm --privileged --name $$QEMU_NAME -v -ti multiarch/qemu-user-static:register --reset

%:
	for i in $$QEMU_TARGETS; do \
		rm -rf bin/$$i \
		for j in $$QEMU_ARCHES ; do \
			mkdir -p bin/$$i \
			mkdir -p bin/$$i/$$j \
			echo "FROM multiarch/debian-debootstrap-$$i-$$j" >> bin/$$i/$$j/Dockerfile \
			for line in "version: '2'" \
			    "  services:" \
					"    $$i_$$j:" \
				  "      image: redelivre/qemu:$$i-$$j" \
				  "      build:" \
					"        context: $$PWD/bin/$$i/$$j" \
					"        dockerfile: Dockerfile" \
					"        args:" ; do \
					echo $$line >> bin/$$i/$$j/docker-compose.yml ; \
					for a in "username="$(whoami) \
							$$ENVS ; do \
							echo "          - "$$a  >> bin/$$i/$$j/docker-compose.yml \
							echo "ARG "$$a >> bin/$$i/$$j/Dockerfile
					done \
				done \
			done \
			cat .qemu.yml | shyaml get-value $@ | sed -E 's|-\s(.+)|RUN \1|g' >> bin/$$i/$$j/Dockerfile \
			docker-compose up -d $$i_$$j ; \
		done /
	done
