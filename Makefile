USER={USER:=$$USER}
NAME=$$(cat /proc/sys/kernel/random/uuid)
docker:
	mkdir -p bin
	@docker run --rm \
							--privileged \
							multiarch/qemu-user-static:register \
							--reset
	@docker service create \
		--mount 'type=volume,src=$$HOME/bin,dest=/usr/local/bin,volume-driver=local' \
		--name $$NAME

build:
	sudo pip install shyaml
	mkdir -p bin
	for i in `cat .qemu.yml | shyaml get-value arches | sed -E 's|-\s(.+)|\1|g'` ; do \
		for j in `cat .qemu.yml | shyaml get-value targets | sed -E 's|-\s(.+)|\1|g'` ; do \
			docker run --name=$$NAME --user=$$(id -u):$$(id -g) -t multiarch/debian-debootstrap:$$i-$$j sudo apt-get install python ; \
		done \
	done

env:
	if [ -f bin/env.py ] ; then \
		rm bin/env.py ; \
	fi
	for i in "#!/usr/bin/python" \
					 "import os" \
					 "import uuid" ; do \
		echo "$$i" >> bin/env.py ; \
	done
	cat .qemu.yml | shyaml get-value env | sed -E 's|-\s(.+)=(.+)|os.environ["\1"] = "\2"|g' >> bin/env.py
	echo 'for k,v in os.environ.iteritems(): ' >> bin/env.py
	echo '  print "%s: %s" % (k, v)' >> bin/env.py
	for i in `cat .qemu.yml | shyaml get-value arches | sed -E 's|-\s(.+)|\1|g'` ; do \
		for j in `cat .qemu.yml | shyaml get-value targets | sed -E 's|-\s(.+)|\1|g'` ; do \
			docker run --rm --name=$$NAME --user=$$(id -u):$$(id -g) multiarch/debian-debootstrap:$$i-$$j python /usr/local/bin/$$NAME-env.py ; \
		done \
	done

before_install:
	if [ -d bin/before_install.py ] ; then \
		rm bin/before_install.py ; \
	fi
	echo "import os" >> bin/before_install.py
	cat .qemu.yml | shyaml get-value before_install | sed -E 's|-\s(.+)|os.system("\1")|g' >> bin/before_install.py
	for i in `cat .qemu.yml | shyaml get-value arches | sed -E 's|-\s(.+)|\1|g'` ; do \
		for j in `cat .qemu.yml | shyaml get-value targets | sed -E 's|-\s(.+)|\1|g'` ; do \
			docker run --name=$$NAME --user=$$(id -u):$$(id -g) -t multiarch/debian-debootstrap:$$i-$$j python /usr/local/bin/$$NAME-before_install ; \
		done \
	done

install:
	if [ -d bin/install.py ] ; then \
		rm bin/install.py ; \
	fi
	echo "import os" >> bin/install.py
	cat .qemu.yml | shyaml get-value install | sed -E 's|-\s(.+)|os.system("\1")|g' >> install.py
	python bin/install.py

after_install:
	if [ -d bin/after_install.py ] ; then \
		rm bin/after_install.py ; \
	fi
	echo "import os" >> bin/after_install.py
	cat .qemu.yml | shyaml get-value after_install | sed -E 's|-\s(.+)|os.system("\1")|g' >> bin/after_install.py
	python bin/after_install.py

before_script:
	if [ -d bin/before_script.py ] ; then \
		rm bin/before_script.py ; \
	fi
	echo "import os" >> bin/before_script.py
	cat .qemu.yml | shyaml get-value before_script | sed -E 's|-\s(.+)|os.system("\1")|g' >> bin/before_script.py

script:
	if [ -d bin/script.py ] ; then \
		rm bin/script.py ; \
	fi
	echo "import os" >> bin/script.py
	cat .qemu.yml | shyaml get-value script | sed -E 's|-\s(.+)|os.system("\1")|g' >> bin/script.py

after_success:
	if [ -d bin/after_success.py ] ; then \
		rm bin/after_success.py ; \
	fi
	echo "import os" >> bin/after_success.py
	cat .qemu.yml | shyaml get-value after_success | sed -E 's|-\s(.+)|os.system("\1")|g' >> bin/after_success.py
