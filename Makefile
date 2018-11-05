clean:
	if [ -d $$PWD/bin ] ; then \
		rm -rf $$PWD/bin ; \
	fi

before_install:
	mkdir -p $$PWD/bin
	echo "id: `python -c 'from uuid import uuid4; print uuid4().hex'`" >> $$PWD/bin/.qemu.yml


install:before_install
	pip install --user -U pip
	pip install --user shyaml

after_install:
	docker run --rm --privileged multiarch/qemu-user-static:register --reset

before_script:
	mkdir -p $$PWD/bin
	for i in `cat .qemu.yml | shyaml get-value targets | sed -E 's|-\s(.+)|\1|g'` ; do \
		mkdir -p $$PWD/bin/$$i ; \
		echo "version: '2'" >> $$PWD/bin/docker-compose.yml ; \
		echo "services:" >> $$PWD/bin/docker-compose.yml ; \
		for j in `cat .qemu.yml | shyaml get-value arches | sed -E 's|-\s(.+)|\1|g'` ; do \
			mkdir -p $$PWD/bin/$$i/$$j ; \
			echo "FROM "`cat .qemu.yml | shyaml get-value image`":"$$j-$$i >> $$PWD/bin/$$i/$$j/Dockerfile ; \
			echo "ARG username" >> $$PWD/bin/$$i/$$j/Dockerfile ; \
			echo "ARG DOCKER_USERNAME" >> $$PWD/bin/$$i/$$j/Dockerfile ; \
			echo "ARG DOCKER_PASSWORD" >> $$PWD/bin/$$i/$$j/Dockerfile ; \
			echo "  "$$i"_"$$j":" >> $$PWD/bin/docker-compose.yml ; \
			echo "    image: redelivre/qemu:$$i-$$j" >> $$PWD/bin/docker-compose.yml ; \
			echo "    build:" >> $$PWD/bin/docker-compose.yml ; \
			echo "      context: $$PWD/bin/$$i/$$j" >> $$PWD/bin/docker-compose.yml ; \
			echo "      dockerfile: Dockerfile" >> $$PWD/bin/docker-compose.yml ; \
			echo "      args:" >> $$PWD/bin/docker-compose.yml ; \
			echo "        - 'username=$$(cat $$PWD/bin/.qemu.yml | shyaml get-value id)'" >> $$PWD/bin/docker-compose.yml ; \
			echo "        - 'DOCKER_USERNAME=\$$DOCKER_USERNAME'" >> $$PWD/bin/docker-compose.yml ; \
			echo "        - 'DOCKER_PASSWORD=\$$DOCKER_PASSWORD'" >> $$PWD/bin/docker-compose.yml ; \
			cat .qemu.yml | shyaml get-value env | sed -E 's|- (.+)=(.+)|ARG \1|g' >> $$PWD/bin/$$i/$$j/Dockerfile ; \
			cat .qemu.yml | shyaml get-value env | sed -E 's|- (.+)=(.+)|        - "\1=\2"|g' >> $$PWD/bin/docker-compose.yml ; \
		done ; \
	done

script:
	for i in `cat .qemu.yml | shyaml get-value targets | sed -E 's|-\s(.+)|\1|g'` ; do \
		for j in `cat .qemu.yml | shyaml get-value arches | sed -E 's|-\s(.+)|\1|g'` ; do \
			for k in "before_install" \
					"install" \
					"after_install" \
					"before_script" \
					"script" \
					"after_script" \
					"after_success" ; do \
					echo "RUN echo '==> redelivre/qemu:"$$i"-"$$j"."$$k"'" >> $$PWD/bin/$$i/$$j/Dockerfile ; \
					cat .qemu.yml | shyaml get-value $$k | sed -E 's|-\s(.+)|RUN \1|g' >> bin/$$i/$$j/Dockerfile ; \
					if [ $$k == 'before_install' ] ; then \
						echo "WORKDIR /home/\$$username" >> $$PWD/bin/$$i/$$j/Dockerfile ; \
						echo "USER \$$username" >> $$PWD/bin/$$i/$$j/Dockerfile ; \
					fi ; \
			done \
		done \
	done

after_script:
	cat $$PWD/bin/docker-compose.yml
	for i in `cat .qemu.yml | shyaml get-value targets | sed -E 's|-\s(.+)|\1|g'` ; do \
		for j in `cat .qemu.yml | shyaml get-value arches | sed -E 's|-\s(.+)|\1|g'` ; do \
			cat $$PWD/bin/$$i/$$j/Dockerfile ; \
			docker-compose --file=$$PWD/bin/docker-compose.yml up -d ""$$i"_"$$j ; \
		done \
	done \
