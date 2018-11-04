USER={USER:=$$USER}
ARCHES=""
TARGETS=""
clean:
	if [ -d $$PWD/bin ] ; then rm -rf $$PWD/bin ; fi

build: clean
	pip install shyaml
	ARCHES=`cat .qemu.yml | shyaml get-value arches | sed -E 's|-\s(.+)|\1|g'`
	TARGETS=`cat .qemu.yml | shyaml get-value targets | sed -E 's|-\s(.+)|\1|g'`
	ENVS=`cat .qemu.yml | shyaml get-value env | sed -E 's|-\s(.+)|\1|g'`
	@docker run --rm --privileged --name qemu -v -ti multiarch/qemu-user-static:register --reset

%:
	for i in ${TARGETS}; do \
		rm -rf bin/$$i
		for j in ${ARCHES} ; do \
			mkdir -p bin/$$i
			mkdir -p bin/$$i/$$j
			echo "FROM multiarch/debian-debootstrap-$$i-$$j" >> bin/$$i/$$j/Dockerfile
			for line in "version: '2'" \
			    "  services:" \
					"    $$i_$$j:" \
				  "      image: redelivre/debian-qemu:$$i-$$j" \
				  "      build:" \
					"        context: $$PWD/bin/$$i/$$j" \
					"        dockerfile: Dockerfile" \
					"        args:" ; do \
					echo $$line >> bin/$$i/$$j/docker-compose.yml ; \
					for a in "username="$(whoami) \
							${ENVS} ; do \
							echo "          - "$$a  >> bin/$$i/$$j/docker-compose.yml \
							echo "ARG "$$a >> bin/$$i/$$j/Dockerfile
					done \
				done \
			done \
			cat .qemu.yml | shyaml get-value $@ | sed -E 's|-\s(.+)|RUN \1|g' >> bin/$$i/$$j/Dockerfile \
			docker-compose up -d $$i_$$j ; \
		done /
	done
