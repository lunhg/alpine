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
	docker run --rm --privileged multiarch/qemu-user-static:register --reset

before_script:
	mkdir -p $$PWD/bin
	for i in `cat .qemu.yml | shyaml get-value targets | sed -E 's|-\s(.+)|\1|g'` ; do \
		mkdir -p $$PWD/bin/$$i ; \
		# docker-compose composition 
		echo "version: '2'" >> $$PWD/bin/$$i/docker-compose.yml ; \
		echo "services:" >> $$PWD/bin/$$i/docker-compose.yml ; \
		for j in `cat .qemu.yml | shyaml get-value arches | sed -E 's|-\s(.+)|\1|g'` ; do \
			mkdir -p $$PWD/bin/$$i/$$j ; \

			# Dockerfile env as arguments composition
			echo "FROM "`cat .qemu.yml | shyaml get-value image`":"$$j-$$i >> $$PWD/bin/$$i/$$j/Dockerfile ; \
			echo "ARG DOCKER_USERNAME" >> $$PWD/bin/$$i/$$j/Dockerfile ; \
			echo "ARG DOCKER_PASSWORD" >> $$PWD/bin/$$i/$$j/Dockerfile ; \

			# docker-compose composition
			echo "  "$$i"_"$$j":" >> $$PWD/bin/$$i/docker-compose.yml ; \
			echo "    image: redelivre/qemu:$$i-$$j" >> $$PWD/bin/docker-compose.yml ; \
			echo "    build:" >> $$PWD/bin/$$i/docker-compose.yml ; \
			echo "      context: $$PWD/bin/$$i/$$j" >> $$PWD/bin/$$i/docker-compose.yml ; \
			echo "      dockerfile: Dockerfile" >> $$PWD/bin/$$i/docker-compose.yml ; \

			# docker-compose env as arguments composition
			echo "      args:" >> $$PWD/bin/$$i/docker-compose.yml ; \
			echo "        - 'DOCKER_USERNAME=\$$DOCKER_USERNAME'" >> $$PWD/bin/$$i/docker-compose.yml ; \
			echo "        - 'DOCKER_PASSWORD=\$$DOCKER_PASSWORD'" >> $$PWD/bin/$$i/docker-compose.yml ; \
			cat .qemu.yml | shyaml get-value env | sed -E 's|- (.+)=(.+)|ARG \1|g' >> $$PWD/bin/$$i/$$j/Dockerfile ; \
			cat .qemu.yml | shyaml get-value env | sed -E 's|- (.+)=(.+)|        - "\1=\2"|g' >> $$PWD/bin/$$i/docker-compose.yml ; \

			# Volumes composition
			echo "    volumes:" >> $$PWD/bin/$$i/docker-compose.yml ; \
			cat .qemu.yml | shyaml get-value volumes | sed -E 's|- (.+)=(.+)|VOLUME \2|g' >> $$PWD/bin/$$i/$$j/Dockerfile ; \
			cat .qemu.yml | shyaml get-value volumes | sed -E 's|- (.+)=(.+)|      - "\1"|g' >> $$PWD/bin/$$i/$$j/Dockerfile ; \

			# Unique user
			echo "RUN addgroup --gid 1000 qemu" >> $$PWD/bin/$$i/$$j/Dockerfile ; \
			echo "RUN echo 'y' | adduser --force-badname --ingroup qemu --uid 1000 --disabled-password --home /home/$$(cat $$PWD/bin/.qemu.yml | shyaml get-value id) $$(cat $$PWD/bin/.qemu.yml | shyaml get-value id)"  >> $$PWD/bin/$$i/$$j/Dockerfile ; \
			echo "RUN echo '%qemu ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers" >> $$PWD/bin/$$i/$$j/Dockerfile ; \
			echo "RUN chown -R $$(cat $$PWD/bin/.qemu.yml | shyaml get-value id):qemu /home/$$(cat $$PWD/bin/.qemu.yml | shyaml get-value id)" >> $$PWD/bin/$$i/$$j/Dockerfile ; \
		done ; \
	done ; 

script:
	for i in `cat .qemu.yml | shyaml get-value targets | sed -E 's|-\s(.+)|\1|g'` ; do \
		for j in `cat .qemu.yml | shyaml get-value arches | sed -E 's|-\s(.+)|\1|g'` ; do \
			for k in `cat .qemu.yml | shyaml keys | grep "[^image|targets|arches|env]"` ; do \
				cat .qemu.yml | shyaml get-value $$k | sed -E 's|-\s(.+)|RUN \1|g'  >> bin/$$i/$$j/Dockerfile ; \
				if [ "$$k" = "before_install" ] ; then \
					echo "WORKDIR /home/$$(cat $$PWD/bin/.qemu.yml | shyaml get-value id)" >> bin/$$i/$$j/Dockerfile ; \
					echo "USER $$(cat $$PWD/bin/.qemu.yml | shyaml get-value id)" >> bin/$$i/$$j/Dockerfile ; \
				fi ; \
			done ; \
		done ; \
	done ;

after_script:
	for i in `cat .qemu.yml | shyaml get-value targets | sed -E 's|-\s(.+)|\1|g'` ; do \
		cat $$PWD/bin/$$i/docker-compose.yml ; \
		for j in `cat .qemu.yml | shyaml get-value arches | sed -E 's|-\s(.+)|\1|g'` ; do \
			cat $$PWD/bin/$$i/$$j/Dockerfile ; \
			docker-compose --file=$$PWD/bin/$$i/docker-compose.yml build ""$$i"_"$$j ; \
		done \
	done \

qemu-composer: clean before_install install before_script script after_script
