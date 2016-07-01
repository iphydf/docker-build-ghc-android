FROM ubuntu:16.04
MAINTAINER iphydf@gmail.com

#
# Install required packages
#
RUN apt-get update
RUN apt-get -y install \
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
ADD root-scripts/create-androidbuilder-user.sh /root/
RUN bash -c ./create-androidbuilder-user.sh

# Log-in to the new user
USER androidbuilder

# Update cabal and install the latest
WORKDIR /home/androidbuilder

# Set the working directory
ENV BASE /home/androidbuilder/ghc-build

# FIXME: Move the adding of the patches until later in the Docker build,
# just before GHC is built
RUN mkdir -p $BASE/patches

ADD user-scripts/set-env.sh $BASE/
WORKDIR $BASE

#
# These downloads take quite a while and are annoying. I put them here
# at the beginning to get them out of the way. If something breaks in the
# build it would suck if you had to rewind to a Docker image BEFORE
# the downloads had occurred.
#
ADD user-scripts/download-iconv.sh $BASE/
RUN ./download-iconv.sh
ADD user-scripts/download-ncurses.sh $BASE/
RUN ./download-ncurses.sh
ADD user-scripts/download-gmp.sh $BASE/
RUN ./download-gmp.sh
ADD user-scripts/download-ghc.sh $BASE/
RUN ./download-ghc.sh
ADD user-scripts/download-ndk.sh $BASE/
RUN ./download-ndk.sh

#
# Start preparing the environment.
#
ADD user-scripts/unpack-ndk.sh $BASE/
RUN ./unpack-ndk.sh

ADD user-scripts/create-ndk-standalone-toolchain.sh $BASE/
RUN ./create-ndk-standalone-toolchain.sh

ADD user-scripts/unpack-ncurses.sh $BASE/
RUN ./unpack-ncurses.sh

ADD user-scripts/set-env-1.sh $BASE/

#
# From this point on all scripts should include set-env-1.sh which
# itself builds upon set-env.sh
#

ADD patches/iconv-fix-time_t.patch $BASE/patches/
ADD user-scripts/build-iconv.sh $BASE/
RUN ./build-iconv.sh

ADD user-scripts/build-ncurses.sh $BASE/
RUN ./build-ncurses.sh

ADD patches/gmp-android-14-arm-linux-androideabi-4.8-GmpDerivedConstants.h $BASE/patches/
ADD user-scripts/build-gmp.sh $BASE/
RUN ./build-gmp.sh

ADD patches/gsasl-avoid-memxor-conflict.patch $BASE/patches/
ADD user-scripts/build-gsasl.sh $BASE/
RUN ./build-gsasl.sh

ADD user-scripts/build-libidn.sh $BASE/
RUN ./build-libidn.sh

ADD patches/libxml2-no-tests.patch $BASE/patches/
ADD user-scripts/build-libxml2.sh $BASE/
RUN ./build-libxml2.sh

ADD user-scripts/build-nettle.sh $BASE/
RUN ./build-nettle.sh

ADD patches/gnutls-no-atfork.patch $BASE/patches/
ADD user-scripts/build-gnutls30.sh $BASE/
RUN ./build-gnutls30.sh

#
# At last we are ready to build GHC. First we build it for the host
# architecture and then we build the cross-compiler.
#

# This will take a while
ADD user-scripts/build-ghc-host.sh $BASE/
RUN ./build-ghc-host.sh

# This takes a while too
ADD patches/ghc-android.patch $BASE/patches/
ADD user-scripts/build-ghc-cross-compiler.sh $BASE/
RUN ./build-ghc-cross-compiler.sh

ADD user-scripts/build-hsc2hs-wrapper.sh $BASE/
RUN ./build-hsc2hs-wrapper.sh

ADD patches/cabal-wrapper $BASE/patches/
ADD user-scripts/build-cross-compile-cabal.sh $BASE/
RUN ./build-cross-compile-cabal.sh

ADD user-scripts/add-bindir-links.sh $BASE/
RUN ./add-bindir-links.sh

ADD user-scripts/update-cabal-install.sh $BASE/
RUN ./update-cabal-install.sh

#
# Now to add add some PATHs to the .bashrc
#
ADD user-scripts/add-paths-to-bashrc.sh $BASE/
RUN ./add-paths-to-bashrc.sh

#
# Now to clean up the build directory. It takes up a lot of space (3.6G).
#

WORKDIR /home/androidbuilder
RUN rm -rf $BASE

# Become root
USER root

#
# Install Java packages
#
RUN apt-get -y install ant openjdk-8-jdk-headless

# Back to non-root
USER androidbuilder

ADD user-scripts/README /home/androidbuilder/
RUN cat README
