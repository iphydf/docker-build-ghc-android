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

# Set the working directory
ENV BASE /home/androidbuilder/ghc-build

# The adding of the patches happens later in the Docker build, just before the
# patched code is built
RUN mkdir -p $BASE/patches

# $BEGIN-BUILD-ALL$

COPY user-scripts/set-env.sh $BASE/

WORKDIR $BASE

#
# These downloads take quite a while and are annoying. I put them here
# at the beginning to get them out of the way. If something breaks in the
# build it would suck if you had to rewind to a Docker image BEFORE
# the downloads had occurred.
#
COPY user-scripts/download-iconv.sh $BASE/
RUN ./download-iconv.sh
COPY user-scripts/download-ncurses.sh $BASE/
RUN ./download-ncurses.sh
COPY user-scripts/download-gmp.sh $BASE/
RUN ./download-gmp.sh
COPY user-scripts/download-ghc.sh $BASE/
RUN ./download-ghc.sh
COPY user-scripts/download-ndk.sh $BASE/
RUN ./download-ndk.sh

#
# Start preparing the environment.
#
COPY user-scripts/unpack-ndk.sh $BASE/
RUN ./unpack-ndk.sh

COPY user-scripts/create-ndk-standalone-toolchain.sh $BASE/
RUN ./create-ndk-standalone-toolchain.sh

COPY user-scripts/unpack-ncurses.sh $BASE/
RUN ./unpack-ncurses.sh

COPY user-scripts/set-env-1.sh $BASE/

#
# From this point on all scripts should include set-env-1.sh which
# itself builds upon set-env.sh
#

COPY patches/iconv-fix-time_t.patch $BASE/patches/
COPY user-scripts/build-iconv.sh $BASE/
RUN ./build-iconv.sh

COPY user-scripts/build-ncurses.sh $BASE/
RUN ./build-ncurses.sh

COPY patches/gmp-android-14-arm-linux-androideabi-4.8-GmpDerivedConstants.h $BASE/patches/
COPY user-scripts/build-gmp.sh $BASE/
RUN ./build-gmp.sh

COPY patches/gsasl-avoid-memxor-conflict.patch $BASE/patches/
COPY user-scripts/build-gsasl.sh $BASE/
RUN ./build-gsasl.sh

COPY user-scripts/build-libidn.sh $BASE/
RUN ./build-libidn.sh

COPY patches/libxml2-no-tests.patch $BASE/patches/
COPY user-scripts/build-libxml2.sh $BASE/
RUN ./build-libxml2.sh

COPY user-scripts/build-nettle.sh $BASE/
RUN ./build-nettle.sh

COPY patches/gnutls-no-atfork.patch $BASE/patches/
COPY user-scripts/build-gnutls30.sh $BASE/
RUN ./build-gnutls30.sh

#
# At last we are ready to build GHC. First we build it for the host
# architecture and then we build the cross-compiler.
#

# This will take a while
COPY user-scripts/build-ghc-host.sh $BASE/
RUN ./build-ghc-host.sh

# This takes a while too
COPY patches/ghc-android.patch $BASE/patches/
COPY user-scripts/build-ghc-cross-compiler.sh $BASE/
RUN ./build-ghc-cross-compiler.sh

COPY user-scripts/build-hsc2hs-wrapper.sh $BASE/
RUN ./build-hsc2hs-wrapper.sh

COPY patches/cabal-wrapper $BASE/patches/
COPY user-scripts/build-cross-compile-cabal.sh $BASE/
RUN ./build-cross-compile-cabal.sh

COPY user-scripts/add-bindir-links.sh $BASE/
RUN ./add-bindir-links.sh

COPY user-scripts/update-cabal-install.sh $BASE/
RUN ./update-cabal-install.sh

#
# Now to add add some PATHs to the .bashrc
#
COPY user-scripts/add-paths-to-bashrc.sh $BASE/
RUN ./add-paths-to-bashrc.sh

#
# Now to clean up the build directory. It takes up a lot of space (3.6G).
#

WORKDIR /home/androidbuilder
RUN rm -rf $BASE

COPY user-scripts/README /home/androidbuilder/
RUN cat README

# $END-BUILD-ALL$
