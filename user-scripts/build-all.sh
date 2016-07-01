#!/bin/bash
# $BEGIN-BUILD-ALL$


cd $BASE

#
# These downloads take quite a while and are annoying. I put them here
# at the beginning to get them out of the way. If something breaks in the
# build it would suck if you had to rewind to a Docker image BEFORE
# the downloads had occurred.
#
./download-iconv.sh
./download-ncurses.sh
./download-gmp.sh
./download-ghc.sh
./download-ndk.sh

#
# Start preparing the environment.
#
./unpack-ndk.sh

./create-ndk-standalone-toolchain.sh

./unpack-ncurses.sh


#
# From this point on all scripts should include set-env-1.sh which
# itself builds upon set-env.sh
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

# This will take a while
./build-ghc-host.sh

# This takes a while too
./build-ghc-cross-compiler.sh

./build-hsc2hs-wrapper.sh

./build-cross-compile-cabal.sh

./add-bindir-links.sh

./update-cabal-install.sh

#
# Now to add add some PATHs to the .bashrc
#
./add-paths-to-bashrc.sh

#
# Now to clean up the build directory. It takes up a lot of space (3.6G).
#

cd /home/androidbuilder
rm -rf $BASE

cat README

# $END-BUILD-ALL$
