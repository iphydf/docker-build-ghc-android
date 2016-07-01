fast-scripts: Dockerfile.fast user-scripts/build-all.sh

Dockerfile.fast: Dockerfile Makefile
	sed -e '/\$$BEGIN-BUILD-ALL\$$/,/\$$END-BUILD-ALL\$$/d' $< > $@
	echo 'COPY patches/* $$BASE/patches/' >> $@
	echo '' >> $@
	echo 'WORKDIR /home/androidbuilder' >> $@
	echo '' >> $@
	echo '# Add and run all user scripts.' >> $@
	echo 'COPY user-scripts/README user-scripts/*.sh $$BASE/' >> $@
	echo 'RUN user-scripts/build-all.sh' >> $@

user-scripts/build-all.sh: Dockerfile Makefile
	echo '#!/bin/bash' > $@
	sed -n -e '/\$$BEGIN-BUILD-ALL\$$/,/\$$END-BUILD-ALL\$$/{ s/^RUN //; s/^WORKDIR/cd/; /^COPY/d; p; }' $< >> $@
