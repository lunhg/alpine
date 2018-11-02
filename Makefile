USER={USER:=$$USER}

build:
	sudo pip install shyaml
	mkdir bin

env:
	if [ -d bin/env.py ] ; then \
		rm bin/env.py ; \
	fi
	echo "import os " >> bin/env.py
	echo "import uuid " >> bin/env.py
	cat .qemu.yml | shyaml get-value env | sed -E 's|-\s(.+)=(.+)|os.environ["\1"] = "\2"|g' >> bin/env.py
	echo 'os.environ["USER"] = uuid.uuid4().hex' >> bin/env.py
	echo 'os.environ["PWD"] = uuid.uuid4().hex' >> bin/env.py
	echo 'print "%s: %s" % (k, v) for k,v in os.environ.iteritems()' >> bin/env.py

before_install:
	if [ -d bin/before_install.py ] ; then \
		rm bin/before_install.py ; \
	fi
	echo "import os" >> bin/before_install.py
	cat .qemu.yml | shyaml get-value before_install | sed -E 's|-\s(.+)|os.system("\1")|g' >> before_install.py

install:
	if [ -d bin/install.py ] ; then \
		rm bin/install.py ; \
	fi
	echo "import os" >> bin/install.py
	cat .qemu.yml | shyaml get-value install | sed -E 's|-\s(.+)|os.system("\1")|g' >> install.py

after_install:
	if [ -d bin/after_install.py ] ; then \
		rm bin/after_install.py ; \
	fi
	echo "import os" >> bin/after_install.py
	cat .qemu.yml | shyaml get-value after_install | sed -E 's|-\s(.+)|os.system("\1")|g' >> bin/after_install.py

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
