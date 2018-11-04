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
		for k in "version: '2'" \
				"\tservices:" ; do \
				echo -e $$k >> $$PWD/bin/docker-compose.yml ; \
		done ; \
		for j in `cat .qemu.yml | shyaml get-value arches | sed -E 's|-\s(.+)|\1|g'` ; do \
			mkdir -p $$PWD/bin/$$i/$$j ; \
			echo "FROM "`cat .qemu.yml | shyaml get-value image`":"$$j-$$i >> $$PWD/bin/$$i/$$j/Dockerfile ; \
			echo "ARG username" >> $$PWD/bin/$$i/$$j/Dockerfile ; \
			echo "ARG DOCKER_USERNAME" >> $$PWD/bin/$$i/$$j/Dockerfile ; \
			echo "ARG DOCKER_PASSWORD" >> $$PWD/bin/$$i/$$j/Dockerfile ; \
			for k in "\t\t"$$i"_"$$j":" \
					"\t\t\timage: redelivre/qemu:$$i-$$j" \
					"\t\t\tbuild:" \
					"\t\t\t\tcontext: $$PWD/$$i/$$j" \
					"\t\t\t\tdockerfile: Dockerfile" \
					"\t\t\t\targs:" \
					"\t\t\t\t\t- 'username=$$(cat $$PWD/bin/.qemu.yml | shyaml get-value id)'" \
					"\t\t\t\t\t- 'DOCKER_USERNAME=\$$DOCKER_USERNAME'" \
					"\t\t\t\t\t- 'DOCKER_PASSWORD=\$$DOCKER_PASSWORD'" ; do \
					echo -e $$k >> $$PWD/bin/docker-compose.yml ; \
			done ; \
			cat .qemu.yml | shyaml get-value env | sed -E 's|- (.+)=(.+)|ARG \1|g' >> $$PWD/bin/$$i/$$j/Dockerfile ; \
			cat .qemu.yml | shyaml get-value env | sed -E 's|- (.+)=(.+)|\t\t\t\t\t- "\1=\2"|g' >> $$PWD/bin/docker-compose.yml ; \
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
					cat .qemu.yml | shyaml get-value $$k | sed -E 's|-\s(.+)|RUN \1|g' >> bin/$$i/$$j/Dockerfile ; \
			done \
		done \
	done

after_script:
	for i in `cat .qemu.yml | shyaml get-value targets | sed -E 's|-\s(.+)|\1|g'` ; do \
		for j in `cat .qemu.yml | shyaml get-value arches | sed -E 's|-\s(.+)|\1|g'` ; do \
			echo $$i"_"$$j ; \
			docker-compose up -d --build --project-directory $$PWD/bin $$i"_"$$j ; \
		done \
	done
