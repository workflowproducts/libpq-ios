#!/bin/bash

set -e

# edit these version numbers to suit your needs
VERSION=10.3
IOS=11.3
LIBRESSL=2.7.3

# to compile libpq for iOS, we need to use the Xcode SDK by saying -isysroot on the compile line
# there are two SDKs we need to use, the iOS device SDK (arm) and the simulator SDK (x86)
DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer
SDKROOT=$DEVROOT/SDKs/iPhoneOS${IOS}.sdk

# check to see if the SDK version we selected exists
if [ ! -e "$SDKROOT" ]
then
    echo "The iOS SDK ${IOS} doesn't exist, please edit this file and fix the IOS= variable at the top."
    exit 1
fi

# download LibreSSL
if [ ! -e "libressl-$LIBRESSL" ]
then
    curl -OL "https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${LIBRESSL}.tar.gz"
    tar -zxf "libressl-${LIBRESSL}.tar.gz"
fi

# create a staging directory (we need this for include files later on)
PREFIX=$(pwd)/libressl-build/
mkdir -p $PREFIX
mkdir -p $PREFIX/i386
mkdir -p $PREFIX/armv7s
mkdir -p $PREFIX/arm64
cd libressl-${LIBRESSL}

# this cleans everything out of the build directory so we can have a clean build
if [ -e "./Makefile" ]
then
    make distclean
fi

###############################
##  iOS libssl Compilation
###############################

DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer
SDKROOT=$DEVROOT/SDKs/iPhoneSimulator${IOS}.sdk

#Build iPhone Simulator library
# --host=i386-apple-darwin sets the host platform (this tells gcc that we are cross-compiling)
# --prefix="$PREFIX/i386" tells configure that when we run `make install` that's where we want the files to go
# CFLAGS="... -isysroot $SDKROOT" tells gcc where the include files and libraries ares
./configure --host=i386-apple-darwin --prefix="$PREFIX/i386" \
  CC="/usr/bin/gcc" \
  CPPFLAGS="-I$SDKROOT/usr/include/" \
  CFLAGS="$CPPFLAGS -miphoneos-version-min=${IOS} -pipe -no-cpp-precomp -isysroot $SDKROOT" \
  CPP="/usr/bin/cpp $CPPFLAGS" \
  LD=$DEVROOT/usr/bin/ld

# only build the files we need (libcrypto, libssl, include files)
make -C crypto clean all install
make -C ssl clean all install
make -C include install
cp crypto/.libs/libcrypto.a ./libcrypto_i386.a
cp ssl/.libs/libssl.a ./libssl_i386.a

DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer
SDKROOT=$DEVROOT/SDKs/iPhoneOS${IOS}.sdk

#Build ARMv7s library
# --host=arm-apple-darwin is the most important option here (relative to the above commands),
# it tells gcc that we need arm executables isntead of intel
./configure --host=arm-apple-darwin --prefix="$PREFIX/armv7s" \
  CC="/usr/bin/gcc" \
  CPPFLAGS="-I$SDKROOT/usr/include/" \
  CFLAGS="$CPPFLAGS -arch armv7s -miphoneos-version-min=${IOS} -pipe -no-cpp-precomp -isysroot $SDKROOT" \
  CPP="/usr/bin/cpp -D__arm__=1 $CPPFLAGS" \
  LD=$DEVROOT/usr/bin/ld

make -C crypto clean all install
make -C ssl clean all install
make -C include install
cp crypto/.libs/libcrypto.a ./libcrypto_armv7s.a
cp ssl/.libs/libssl.a ./libssl_armv7s.a

#Build ARM64 library
# arm64 is for newer phones
./configure --host=arm-apple-darwin --prefix="$PREFIX/arm64" \
  CC="/usr/bin/gcc" \
  CPPFLAGS="-I$SDKROOT/usr/include/" \
  CFLAGS="$CPPFLAGS -arch arm64 -miphoneos-version-min=${IOS} -pipe -no-cpp-precomp -isysroot $SDKROOT" \
  CPP="/usr/bin/cpp -D__arm__=1 $CPPFLAGS" \
  LD=$DEVROOT/usr/bin/ld

make -C crypto clean all install
make -C ssl clean all install
make -C include install
cp crypto/.libs/libcrypto.a ./libcrypto_arm64.a
cp ssl/.libs/libssl.a ./libssl_arm64.a

# these commands take our individual static libraries and puts them into one multi-arch library
lipo -create ./libcrypto_i386.a ./libcrypto_armv7s.a ./libcrypto_arm64.a -output ./libcrypto.a
lipo -create ./libssl_i386.a ./libssl_armv7s.a ./libssl_arm64.a -output ./libssl.a

// put them where the Xcode project will find them
cp ./libcrypto.a ./libssl.a ../libpq-test/

cd ..

# download postgres
if [ ! -e "postgresql-$VERSION" ]
then
    curl -OL "https://ftp.postgresql.org/pub/source/v${VERSION}/postgresql-${VERSION}.tar.gz"
    tar -zxf "postgresql-${VERSION}.tar.gz"
fi

cd postgresql-${VERSION}

# this cleans everything out of the build directory so we can have a clean build
if [ -e "./src/Makefile.global" ]
then
    make -C ./src/interfaces/libpq distclean
fi

chmod u+x ./configure
###############################
##  iOS libpq Compilation
###############################

DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer
SDKROOT=$DEVROOT/SDKs/iPhoneSimulator${IOS}.sdk

#Build iPhone Simulator library
# the important differences between this and libressl above,
# are that we are specifying where libressl is so gcc can find it (-L$PREFIX/.../lib, -I$PREFIX/.../include)
# other than that these options are exactly the same
./configure --host=i386-apple-darwin --without-readline --with-openssl \
  CC="/usr/bin/gcc -L$PREFIX/i386/lib" \
  CPPFLAGS="-I$SDKROOT/usr/include/ -I$PREFIX/i386/include" \
  CFLAGS="$CPPFLAGS -miphoneos-version-min=${IOS} -pipe -no-cpp-precomp -isysroot $SDKROOT" \
  CPP="/usr/bin/cpp $CPPFLAGS" \
  LD="$DEVROOT/usr/bin/ld -L$PREFIX/i386/lib"
make -C src/interfaces/libpq
cp src/interfaces/libpq/libpq.a ./libpq_i386.a

DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer
SDKROOT=$DEVROOT/SDKs/iPhoneOS${IOS}.sdk

#Build ARMv7s library
make -C src/interfaces/libpq distclean
./configure --host=arm-apple-darwin --without-readline --with-openssl \
  CC="/usr/bin/gcc -L$PREFIX/armv7s/lib" \
  CPPFLAGS="-I$SDKROOT/usr/include/ -I$PREFIX/armv7s/include" \
  CFLAGS="$CPPFLAGS -arch armv7s -pipe -no-cpp-precomp -isysroot $SDKROOT " \
  CPP="/usr/bin/cpp -D__arm__=1 $CPPFLAGS" \
  LD="$DEVROOT/usr/bin/ld -L$PREFIX/armv7s/lib"
make -C src/interfaces/libpq
cp src/interfaces/libpq/libpq.a ./libpq_armv7s.a

#Build ARM64 library
make -C src/interfaces/libpq distclean
./configure --host=arm-apple-darwin --without-readline --with-openssl \
  CC="/usr/bin/gcc -L$PREFIX/arm64/lib" \
  CPPFLAGS="-I$SDKROOT/usr/include/ -I$PREFIX/arm64/include" \
  CFLAGS="$CPPFLAGS -arch arm64 -pipe -no-cpp-precomp -isysroot $SDKROOT" \
  CPP="/usr/bin/cpp -D__arm64__=1 $CPPFLAGS" \
  LD="$DEVROOT/usr/bin/ld -L$PREFIX/arm64/lib"
make -C src/interfaces/libpq
cp src/interfaces/libpq/libpq.a ./libpq_arm64.a


lipo -create ./libpq_i386.a ./libpq_armv7s.a ./libpq_arm64.a -output ./libpq.a

cd ..
cp postgresql-${VERSION}/libpq.a libpq-test/libpq.a

