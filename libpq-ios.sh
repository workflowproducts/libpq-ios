#!/bin/bash

set -e

VERSION=10.3
IOS=11.3
LIBRESSL=2.7.3
#MAKEFLAGS=-j4

DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer
SDKROOT=$DEVROOT/SDKs/iPhoneOS${IOS}.sdk

if [ ! -e "$SDKROOT" ]
then
    echo "The iOS SDK ${IOS} doesn't exist, please edit this file and fix the IOS= variable at the top."
    exit 1
fi

if [ ! -e "libressl-$LIBRESSL" ]
then
    curl -OL "https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${LIBRESSL}.tar.gz"
    tar -zxf "libressl-${LIBRESSL}.tar.gz"
fi

PREFIX=$(pwd)/libressl-build/
: '
mkdir -p $PREFIX
mkdir -p $PREFIX/i386
mkdir -p $PREFIX/armv7s
mkdir -p $PREFIX/arm64
cd libressl-${LIBRESSL}

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
./configure --host=i386-apple-darwin --prefix="$PREFIX/i386" \
  CC="/usr/bin/gcc" \
  CPPFLAGS="-I$SDKROOT/usr/include/" \
  CFLAGS="$CPPFLAGS -miphoneos-version-min=${IOS} -pipe -no-cpp-precomp -isysroot $SDKROOT" \
  CPP="/usr/bin/cpp $CPPFLAGS" \
  LD=$DEVROOT/usr/bin/ld

make -C crypto clean all install $MAKEFLAGS
make -C ssl clean all install $MAKEFLAGS
make -C include install
cp crypto/.libs/libcrypto.a ./libcrypto_i386.a
cp ssl/.libs/libssl.a ./libssl_i386.a

DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer
SDKROOT=$DEVROOT/SDKs/iPhoneOS${IOS}.sdk

#Build ARMv7s library
./configure --host=arm-apple-darwin --prefix="$PREFIX/armv7s" \
  CC="/usr/bin/gcc" \
  CPPFLAGS="-I$SDKROOT/usr/include/" \
  CFLAGS="$CPPFLAGS -arch armv7s -miphoneos-version-min=${IOS} -pipe -no-cpp-precomp -isysroot $SDKROOT" \
  CPP="/usr/bin/cpp -D__arm__=1 $CPPFLAGS" \
  LD=$DEVROOT/usr/bin/ld

make -C crypto clean all install $MAKEFLAGS
make -C ssl clean all install $MAKEFLAGS
make -C include install
cp crypto/.libs/libcrypto.a ./libcrypto_armv7s.a
cp ssl/.libs/libssl.a ./libssl_armv7s.a

#Build ARM64 library
./configure --host=arm-apple-darwin --prefix="$PREFIX/arm64" \
  CC="/usr/bin/gcc" \
  CPPFLAGS="-I$SDKROOT/usr/include/" \
  CFLAGS="$CPPFLAGS -arch arm64 -miphoneos-version-min=${IOS} -pipe -no-cpp-precomp -isysroot $SDKROOT" \
  CPP="/usr/bin/cpp -D__arm__=1 $CPPFLAGS" \
  LD=$DEVROOT/usr/bin/ld

make -C crypto clean all install $MAKEFLAGS
make -C ssl clean all install $MAKEFLAGS
make -C include install
cp crypto/.libs/libcrypto.a ./libcrypto_arm64.a
cp ssl/.libs/libssl.a ./libssl_arm64.a

lipo -create ./libcrypto_i386.a ./libcrypto_armv7s.a ./libcrypto_arm64.a -output ./libcrypto.a
lipo -create ./libssl_i386.a ./libssl_armv7s.a ./libssl_arm64.a -output ./libssl.a

cp ./libcrypto.a ./libssl.a ../libpq-test/

cd ..
'

if [ ! -e "postgresql-$VERSION" ]
then
    curl -OL "https://ftp.postgresql.org/pub/source/v${VERSION}/postgresql-${VERSION}.tar.gz"
    tar -zxf "postgresql-${VERSION}.tar.gz"
fi

cd postgresql-${VERSION}

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

