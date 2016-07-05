# vim:ft=dockerfile
FROM ubuntu:16.04
MAINTAINER iphydf@gmail.com

#
# Install required packages
#
RUN apt-get update && apt-get -y install \
  autoconf \
  automake \
  build-essential \
  c2hs \
  cabal-install \
  ca-certificates \
  curl \
  ghc \
  git \
  libtool \
  llvm-3.7 \
  pkg-config \
  python \
  zlib1g-dev
WORKDIR /root
ENV TERM xterm

# Create a new user 'androidbuilder'
COPY root-scripts/create-androidbuilder-user.sh /root/
RUN bash -c ./create-androidbuilder-user.sh

# Log-in to the new user
USER androidbuilder
ENV HOME /home/androidbuilder

# Set the working directory
ENV BASE $HOME/ghc-build

# The adding of the patches happens later in the Docker build, just before the
# patched code is built
RUN mkdir -p $BASE/patches

#@ COPY patches/* $BASE/patches/
#@
#@ WORKDIR /home/androidbuilder
#@
#@ # Add and run all user scripts.
#@ COPY user-scripts/README user-scripts/*.sh $BASE/
#@ RUN user-scripts/build-all.sh

# $BEGIN-BUILD-ALL$

COPY user-scripts/set-env.sh $BASE/

WORKDIR $BASE

#
# Start preparing the environment.
#

COPY user-scripts/install-ndk.sh $BASE/
RUN ./install-ndk.sh

COPY user-scripts/create-ndk-standalone-toolchain.sh $BASE/
RUN ./create-ndk-standalone-toolchain.sh

#
# Build required libraries for Android.
#

COPY patches/iconv-* $BASE/patches/
COPY user-scripts/build-iconv.sh $BASE/
RUN ./build-iconv.sh

COPY user-scripts/build-ncurses.sh $BASE/
RUN ./build-ncurses.sh

COPY patches/gmp-* $BASE/patches/
COPY user-scripts/build-gmp.sh $BASE/
RUN ./build-gmp.sh

COPY patches/gsasl-* $BASE/patches/
COPY user-scripts/build-gsasl.sh $BASE/
RUN ./build-gsasl.sh

COPY user-scripts/build-libidn.sh $BASE/
RUN ./build-libidn.sh

COPY patches/libxml2-* $BASE/patches/
COPY user-scripts/build-libxml2.sh $BASE/
RUN ./build-libxml2.sh

COPY user-scripts/build-nettle.sh $BASE/
RUN ./build-nettle.sh

COPY patches/gnutls-* $BASE/patches/
COPY user-scripts/build-gnutls30.sh $BASE/
RUN ./build-gnutls30.sh

#
# At last we are ready to build GHC. First we build it for the host
# architecture and then we build the cross-compiler.
#

COPY patches/ghc-* $BASE/patches/
COPY user-scripts/build-ghc.sh \
     user-scripts/download-ghc.sh \
     user-scripts/build-ghc-host.sh \
     user-scripts/build-ghc-cross-compiler.sh \
     $BASE/
RUN ./build-ghc.sh

COPY user-scripts/build-hsc2hs-wrapper.sh $BASE/
RUN ./build-hsc2hs-wrapper.sh

COPY patches/cabal-wrapper $BASE/patches/
COPY user-scripts/build-cross-compile-cabal.sh $BASE/
RUN ./build-cross-compile-cabal.sh

COPY user-scripts/add-bindir-links.sh $BASE/
RUN ./add-bindir-links.sh

COPY user-scripts/update-cabal-install.sh $BASE/
RUN ./update-cabal-install.sh

COPY user-scripts/README $HOME/
RUN cat $HOME/README

# $END-BUILD-ALL$

WORKDIR $HOME

#
# Now to add add some PATHs
#
ENV GHC_HOST=$HOME/.ghc/android-host \
    PATH=$HOME/.cabal/bin:$HOME/.ghc/android-14/arm-linux-androideabi-4.8/bin:$PATH \
    PLATFORM_PREFIX=$HOME/.ghc/android-14/arm-linux-androideabi-4.8
