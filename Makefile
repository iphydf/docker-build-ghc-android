TAG := iphydf/haskell:8.0.1

default: build

build: $(shell find . -type f)
	chmod 0644 */*
	chmod 0755 patches/cabal-wrapper */*.sh */*.pl
	docker build -f Dockerfile -t $(TAG) .

push: build
	docker push $(TAG)

fast-scripts: Dockerfile.fast user-scripts/build-all.sh

Dockerfile.fast: Dockerfile Makefile
	sed -e '/\$$BEGIN-BUILD-ALL\$$/,/\$$END-BUILD-ALL\$$/d;s/^#@ *//' $< > $@

user-scripts/build-all.sh: Dockerfile Makefile
	echo '#!/bin/bash' > $@
	sed -n -e '/\$$BEGIN-BUILD-ALL\$$/,/\$$END-BUILD-ALL\$$/{ s/^RUN //; s/^WORKDIR/cd/; /^COPY/d; p; }' $< >> $@
