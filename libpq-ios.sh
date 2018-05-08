#!/bin/bash

set -e

VERSION=9.6.2
IOS=11.3

DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer
SDKROOT=$DEVROOT/SDKs/iPhoneOS${IOS}.sdk

if [ ! -e "$SDKROOT" ]
then
    echo "The iOS SDK ${IOS} doesn't exist, please edit this file and fix the IOS= variable at the top."
    exit 1
fi

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
SDKROOT=$DEVROOT/SDKs/iPhoneSimulator${IOS}.sdk

#Build iPhone Simulator library
./configure --host=i386-apple-darwin --without-readline \
  CC="/usr/bin/gcc" \
  CPPFLAGS="-I$SDKROOT/usr/include/" \
  CFLAGS="$CPPFLAGS -miphoneos-version-min=${IOS} -pipe -no-cpp-precomp -isysroot $SDKROOT" \
  CPP="/usr/bin/cpp $CPPFLAGS" \
  LD=$DEVROOT/usr/bin/ld
make -C src/interfaces/libpq
cp src/interfaces/libpq/libpq.a ./libpq_i386.a

DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer
SDKROOT=$DEVROOT/SDKs/iPhoneOS${IOS}.sdk

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
