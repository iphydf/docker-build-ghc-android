TAG	:= iphydf/haskell
VERSION	:= 8.0.1

arm_NDK_TOOLCHAIN	:= arm-linux-androideabi-4.8
arm_NDK_TARGET		:= arm-linux-androideabi
arm_NDK_ABI		:= arm-unknown-linux-androideabi
arm_ARCH_OPTS		:= -fllvm

x86_NDK_TOOLCHAIN	:= x86-4.8
x86_NDK_TARGET		:= i686-linux-android
x86_NDK_ABI		:= i686-linux-android
x86_ARCH_OPTS		:=

SCRIPTS := 				\
	arm/Dockerfile			\
	arm/Dockerfile.fast		\
	arm/build-all.sh		\
	x86/Dockerfile			\
	x86/Dockerfile.fast		\
	x86/build-all.sh		\

all: build scripts
build: build-arm build-x86
push: push-arm push-x86
scripts: $(SCRIPTS)

build-%: %/Dockerfile $(wildcard */*)
	chmod 0644 patches/*
	chmod 0755 *-scripts/* */*.sh
	docker build -f $< -t $(TAG):$(VERSION)-$* .

fast-build-%: %/Dockerfile.fast $(wildcard */*)
	chmod 0644 patches/*
	chmod 0755 *-scripts/* */*.sh
	docker build -f $< -t $(TAG):$(VERSION)-$* .

push-%: build-%
	docker push $(TAG):$(VERSION)-$*

%/Dockerfile: Dockerfile.in %/config.status %/.gitignore
	$*/config.status $< > $@

%/config.status: Makefile
	echo "#!/bin/sh"						>  $@
	echo "cat \$$1 \\"						>> $@
	echo "| sed -e 's/@NDK_TOOLCHAIN@/${$*_NDK_TOOLCHAIN}/g' \\"	>> $@
	echo "| sed -e 's/@NDK_TARGET@/${$*_NDK_TARGET}/g' \\"		>> $@
	echo "| sed -e 's/@NDK_ABI@/${$*_NDK_ABI}/g' \\"		>> $@
	echo "| sed -e 's/@ARCH_OPTS@/${$*_ARCH_OPTS}/g' \\"		>> $@
	chmod +x $@

%/Dockerfile.fast: %/Dockerfile Makefile
	sed -e '/\$$BEGIN-BUILD-ALL\$$/,/\$$END-BUILD-ALL\$$/d;s/^#@ *//' $< > $@

%/build-all.sh: %/Dockerfile Makefile
	echo '#!/bin/bash' > $@
	sed -n -e '/\$$BEGIN-BUILD-ALL\$$/,/\$$END-BUILD-ALL\$$/{ s/^RUN //; s/^WORKDIR/cd/; /^COPY/d; p; }' $< >> $@
