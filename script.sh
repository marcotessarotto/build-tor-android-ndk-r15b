
#export ANDROID_NDK_HOME=/media/marco/b86dd8d0-f4cb-485d-85bd-dcb7bcae334b/downloads-archive/android-ndk-r15b

if test -z $ANDROID_NDK_HOME; then echo "ANDROID_NDK_HOME is not exported, do so by something close to this: export ANDROID_NDK_HOME=/path/to/android-ndk-r15b"; exit; fi

#export WORK_DIR=/media/marco/b86dd8d0-f4cb-485d-85bd-dcb7bcae334b/git/buildtorandroid/

export WORK_DIR=`pwd`


export ANDROID_NDK_ROOT=$ANDROID_NDK_HOME
export NDK_ROOT=$ANDROID_NDK_ROOT
export NDK=$ANDROID_NDK_ROOT

export ORIGINAL_PATH=$PATH


export PATH=$PATH:$ANDROID_NDK_HOME
  

rm -Rf native
mkdir native
mkdir native/lib

cd native

# BUILD openssl1.1.0f
echo "BUILD OPENSSL - see also https://github.com/marcotessarotto/build-openssl-android/blob/master/README.md"
 

wget https://www.openssl.org/source/openssl-1.1.0f.tar.gz

. ../setenv-android.sh

tar -xvzf openssl-1.1.0f.tar.gz 
cd openssl-1.1.0f

./config shared no-ssl2 no-ssl3 no-comp no-hw no-engine --openssldir=/usr/local/ssl/android-16/
 
make depend

make all
 
cd ..


cp ./openssl-1.1.0f/*.a lib/
cp -R ./openssl-1.1.0f/include/openssl ./include
 

  
echo "BUILD libevent" 
rm -Rf libevent
 
git clone https://github.com/marcotessarotto/libevent
cd libevent 

  

$NDK/build/tools/make-standalone-toolchain.sh --platform=android-16 --toolchain=arm-linux-androideabi-4.9 --install-dir=`pwd`/android-toolchain-arm
export TOOLCHAIN_PATH=`pwd`/android-toolchain-arm/bin
export TOOL=arm-linux-androideabi
export NDK_TOOLCHAIN_BASENAME=${TOOLCHAIN_PATH}/${TOOL}
export CC="$NDK_TOOLCHAIN_BASENAME-gcc -D__ANDROID_API__=16 "
export CXX="$NDK_TOOLCHAIN_BASENAME-g++ -D__ANDROID_API__=16 "
export LINK=${CXX}
export LD=$NDK_TOOLCHAIN_BASENAME-ld
export AR=$NDK_TOOLCHAIN_BASENAME-ar
export RANLIB=$NDK_TOOLCHAIN_BASENAME-ranlib
export STRIP=$NDK_TOOLCHAIN_BASENAME-strip
export ARCH_FLAGS="-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16"
export ARCH_LINK="-march=armv7-a -Wl,--fix-cortex-a8"
export CPPFLAGS=" ${ARCH_FLAGS} -fpic -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing -finline-limit=64 "
export CXXFLAGS=" ${ARCH_FLAGS} -fpic -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing -finline-limit=64 -frtti -fexceptions "
export CFLAGS=" ${ARCH_FLAGS} -fpic -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing -finline-limit=64 "
export LDFLAGS=" ${ARCH_LINK} "

./autogen.sh

./configure --host=arm-linux-androideabi 

make
# all tests should pass successfully


cp .libs/libevent.a ../lib
cp -R include/* ../include
cd ..

 

#Build Tor
echo "BUILD TOR" 
git clone https://github.com/torproject/tor
cd tor/


echo "SETTING UP CROSS COMPILER"
# export needed variables
export NDK_TOOLCHAIN=$NDK_ROOT/my-android-toolchain

# remove the old toolchain
rm -rf $NDK_TOOLCHAIN
# create the toolchain
$NDK_ROOT/build/tools/make-standalone-toolchain.sh --platform=android-16 --install-dir=$NDK_TOOLCHAIN

# export needed variables for crosscompile
export PATH="$NDK_TOOLCHAIN/bin/:$PATH"

export HOST=arm-linux-androideabi

export CC=$HOST-gcc
export CXX=$HOST-g++
export AR=$HOST-ar
export LD=$HOST-ld
export AS=$HOST-as
export NM=$HOST-nm
export STRIP=$HOST-strip
export RANLIB=$HOST-ranlib
export OBJDUMP=$HOST-objdump


export CPPFLAGS="--sysroot=$NDK_TOOLCHAIN/sysroot -I$NDK_TOOLCHAIN/sysroot/usr/include -I$NDK_TOOLCHAIN/include -I../include -L../lib "
export LDFLAGS="-L$NDK_TOOLCHAIN/sysroot/usr/lib -L$NDK_TOOLCHAIN/lib"

 
export CC="$HOST-gcc -D__ANDROID_API__=16  "

export CXX="$HOST-g++ -D__ANDROID_API__=16  "

./autogen.sh

./configure --host=arm-linux-eabi --disable-asciidoc --prefix=$NDK_TOOLCHAIN --with-openssl-dir=../lib --enable-static-openssl --with-libevent-dir=../lib --enable-static-libevent

make



cd ..



exit






	#Build JTorControl
	cd libs
	git clone git://git.torproject.org/git/jtorctl
#        git clone https://gitweb.torproject.org/tor.git
	cd jtorctl
	mkdir bin
	javac net/freehaven/tor/control/TorControlConnection.java -d bin
	cd bin
	jar cvf jtorctrl.jar *
	cp jtorctrl.jar ../..
	cd ../../..

	#BUILD privoxy
	mkdir native/privoxy
	cd native/privoxy
	wget http://sourceforge.net/projects/ijbswa/files/Sources/3.0.12%20%28stable%29/privoxy-3.0.12-stable-src.tar.gz/download
	tar xzvf download
	cd privoxy-3.0.12-stable
	autoheader
	autoconf
	#need to disable setpgrp check in configure
	export ac_cv_func_setpgrp_void=yes
 	./configure --host=arm-linux-eabi --build=$BUILD --prefix=$NDK_TOOLCHAIN --disable-pthread
	make clean
	make
	cd ../../..

	mkdir assets
	cp native/privoxy/privoxy-3.0.12-stable/privoxy assets
	cp native/tor/src/or/tor assets






























