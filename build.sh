#!/bin/bash

set -e

sudo yum -y groupinstall "Development Tools"
sudo yum -y install gperf zlib-devel

mkdir -p ~/tmp/{usr,etc,var,libs,install,downloads,tar}

wget -P ~/tmp/downloads \
         http://downloads.sourceforge.net/freetype/freetype-2.9.tar.bz2 \
         http://www.freedesktop.org/software/fontconfig/release/fontconfig-2.12.6.tar.bz2 \
         https://cmake.org/files/v3.10/cmake-3.10.1.tar.gz \
         http://xmlsoft.org/sources/libxml2-2.9.7.tar.gz \
         http://poppler.freedesktop.org/poppler-0.62.0.tar.xz \
         https://poppler.freedesktop.org/poppler-data-0.4.8.tar.gz \
&& ls ~/tmp/downloads/*.tar.* | xargs -i tar xf {} -C ~/tmp/libs/

pushd .

####################################
#cd ~/tmp/libs/cmake*
#./configure
#make
#sudo make install

####################################


####################################
cd ~/tmp/libs/freetype*
sed -ri "s:.*(AUX_MODULES.*valid):\1:" modules.cfg &&

sed -r "s:.*(#.*SUBPIXEL_RENDERING) .*:\1:" \
    -i include/freetype/config/ftoption.h  &&

./configure --prefix=/home/ec2-user/tmp/usr --disable-static
make
make install 

####################################
cd ~/tmp/libs/libxml*
PKG_CONFIG_PATH=~/tmp/usr/lib/pkgconfig/:$PKG_CONFIG_PATH \
./configure --prefix=/home/ec2-user/tmp/usr --disable-static --with-history --without-python
make
make install

####################################
cd ~/tmp/libs/fontconfig*
export FONTCONFIG_PKG=`pwd`

PKG_CONFIG_PATH=~/tmp/usr/lib/pkgconfig/:$PKG_CONFIG_PATH \
./configure --prefix=/home/ec2-user/tmp/usr        \
            --sysconfdir=/home/ec2-user/tmp/etc    \
            --localstatedir=/home/ec2-user/tmp/var \
            --disable-docs       \
            --enable-libxml2 
make
make install

####################################
cd ~/tmp/libs/poppler-0*
#PKG_CONFIG_PATH=~/tmp/usr/lib/pkgconfig/:$FONTCONFIG_PKG:$PKG_CONFIG_PATH \
#./configure --prefix=/var/task      \
#            --sysconfdir=/var/task/etc           \
#            --enable-build-type=release \
#            --enable-cmyk               \
#            --enable-xpdf-headers && make
mkdir -p build
cd build
PKG_CONFIG_PATH=~/tmp/usr/lib/pkgconfig/:$FONTCONFIG_PKG:$PKG_CONFIG_PATH \
cmake .. -DCMAKE_BUILD_TYPE=Release   \
       -DCMAKE_INSTALL_PREFIX=/home/ec2-user/tmp/usr  \
       -DSYSCONFDIR=/var/task/etc \
       -DSPLASH_CMYK=ON \
       -DTESTDATADIR=$PWD/testfiles \
       -DENABLE_XPDF_HEADERS=ON     \
       -DENABLE_LIBOPENJPEG=none  \
       -DENABLE_CMS=none  \
       -DENABLE_DCTDECODER=none \
&& make &&
make install DESTDIR="/home/ec2-user/tmp/install"

cd ~/tmp/libs/poppler-data*
make prefix=/home/ec2-user/tmp/usr install

unset FONTCONFIG_PKG
popd

tar -C ~/tmp/install/var/task \
    --exclude='include' \
    --exclude='share'   \
    -zcvf ~/tmp/tar/poppler.tar.gz .

# aws s3 cp ~/tmp/tar/poppler.tar.gz s3://"${S3BUCKET}"/poppler.tar.gz
