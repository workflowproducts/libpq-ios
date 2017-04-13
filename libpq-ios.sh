#!/bin/bash

set -e

VERSION=9.6.2

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
##  iOS Compilation
###############################

DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer
SDKROOT=$DEVROOT/SDKs/iPhoneSimulator10.3.sdk

#Build iPhone Simulator library
./configure --host=i386-apple-darwin --without-readline \
  CC="/usr/bin/gcc" \
  CPPFLAGS="-I$SDKROOT/usr/include/" \
  CFLAGS="$CPPFLAGS -miphoneos-version-min=10.3 -pipe -no-cpp-precomp -isysroot $SDKROOT" \
  CPP="/usr/bin/cpp $CPPFLAGS" \
  LD=$DEVROOT/usr/bin/ld
make -C src/interfaces/libpq
cp src/interfaces/libpq/libpq.a ./libpq_i386.a

DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer
SDKROOT=$DEVROOT/SDKs/iPhoneOS10.3.sdk

#Build ARMv7s library
make -C src/interfaces/libpq distclean
./configure --host=arm-apple-darwin --without-readline \
  CC="/usr/bin/gcc" \
  CPPFLAGS="-I$SDKROOT/usr/include/" \
  CFLAGS="$CPPFLAGS -arch armv7s -pipe -no-cpp-precomp -isysroot $SDKROOT" \
  CPP="/usr/bin/cpp -D__arm__=1 $CPPFLAGS" \
  LD=$DEVROOT/usr/bin/ld
make -C src/interfaces/libpq
cp src/interfaces/libpq/libpq.a ./libpq_armv7s.a

#Build ARM64 library
make -C src/interfaces/libpq distclean
./configure --host=arm-apple-darwin --without-readline \
  CC="/usr/bin/gcc" \
  CPPFLAGS="-I$SDKROOT/usr/include/" \
  CFLAGS="$CPPFLAGS -arch arm64 -pipe -no-cpp-precomp -isysroot $SDKROOT" \
  CPP="/usr/bin/cpp -D__arm64__=1 $CPPFLAGS" \
  LD=$DEVROOT/usr/bin/ld
make -C src/interfaces/libpq
cp src/interfaces/libpq/libpq.a ./libpq_arm64.a


lipo -create ./libpq_i386.a ./libpq_armv7s.a ./libpq_arm64.a -output ./libpq.a

cd ..
cp postgresql-${VERSION}/libpq.a libpq-test/libpq.a
