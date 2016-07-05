#!/bin/bash
# $BEGIN-BUILD-ALL$


cd $BASE

#
# Start preparing the environment.
#

./install-ndk.sh

./create-ndk-standalone-toolchain.sh

#
# Build required libraries for Android.
#

./build-iconv.sh

./build-ncurses.sh

./build-gmp.sh

./build-gsasl.sh

./build-libidn.sh

./build-libxml2.sh

./build-nettle.sh

./build-gnutls30.sh

#
# At last we are ready to build GHC. First we build it for the host
# architecture and then we build the cross-compiler.
#

     user-scripts/download-ghc.sh \
     user-scripts/build-ghc-host.sh \
     user-scripts/build-ghc-cross-compiler.sh \
     $BASE/
./build-ghc.sh

./build-hsc2hs-wrapper.sh

./build-cross-compile-cabal.sh

./add-bindir-links.sh

./update-cabal-install.sh

cat $HOME/README

# $END-BUILD-ALL$
