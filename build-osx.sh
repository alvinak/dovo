#!/bin/sh
TYPE=Release
#TYPE=Debug

# a top level directory for all PACS related code
BUILD_DIR=`pwd`
DEVSPACE=`cd .. ; pwd`

cd $DEVSPACE
git clone git@github.com:DraconPern/dcmtk.git --branch ci
cd $DEVSPACE/dcmtk
mkdir build-$TYPE
cd build-$TYPE
cmake .. -DDCMTK_WIDE_CHAR_FILE_IO_FUNCTIONS=1 -DCMAKE_INSTALL_PREFIX=$DEVSPACE/dcmtk/$TYPE
make -j8 install

cd $DEVSPACE
git clone --branch=master https://github.com/wxWidgets/wxWidgets.git
cd $DEVSPACE/wxWidgets
git checkout v3.0.2
mkdir build$TYPE
cd build$TYPE
COMMONwxWidgetsFlag="--disable-shared"
if [ "$TYPE" = "Release" ] ; then
  ../configure $COMMONwxWidgetsFlag
elif [ "$TYPE" = "Debug" ] ; then
  ../configure $COMMONwxWidgetsFlag --enable-debug
fi
make -j8

cd $DEVSPACE
wget -c http://downloads.sourceforge.net/project/boost/boost/1.60.0/boost_1_60_0.zip
unzip -n boost_1_60_0.zip
cd $DEVSPACE/boost_1_60_0
./bootstrap.sh
COMMONb2Flag="-j 4 link=static runtime-link=static stage"
BOOSTModule="--with-thread --with-filesystem --with-system --with-date_time --with-regex"
if [ "$TYPE" = "Release" ] ; then
  ./b2 $COMMONb2Flag $BOOSTModule variant=release
elif [ "$TYPE" = "Debug" ] ; then
  ./b2 $COMMONb2Flag $BOOSTModule variant=debug
fi

cd $DEVSPACE
git clone --branch=openjpeg-2.1 https://github.com/uclouvain/openjpeg.git
cd $DEVSPACE/openjpeg
mkdir build-$TYPE
cd build-$TYPE
cmake .. -DBUILD_SHARED_LIBS=OFF -DBUILD_THIRDPARTY=ON -DCMAKE_INSTALL_PREFIX=$DEVSPACE/openjpeg/$TYPE
make -j8 install

cd $DEVSPACE
git clone --branch=master https://github.com/DraconPern/fmjpeg2koj.git
cd $DEVSPACE/fmjpeg2koj
mkdir build-$TYPE
cd build-$TYPE
cmake .. -DBUILD_SHARED_LIBS=OFF -DOPENJPEG=$DEVSPACE/openjpeg/$TYPE -DDCMTK_DIR=$DEVSPACE/dcmtk/$TYPE -DCMAKE_INSTALL_PREFIX=$DEVSPACE/fmjpeg2koj/$TYPE
make -j8 install

cd $BUILD_DIR
mkdir build-$TYPE
cd build-$TYPE
cmake .. -DwxWidgets_CONFIG_EXECUTABLE=$DEVSPACE/wxWidgets/build$TYPE/wx-config -DBOOST_ROOT=$DEVSPACE/boost_1_60_0 -DDCMTK_DIR=$DEVSPACE/dcmtk/$TYPE -DFMJPEG2K=$DEVSPACE/fmjpeg2koj/$TYPE -DOPENJPEG=$DEVSPACE/openjpeg/$TYPE

hdiutil create -volname dovo -srcfolder $BUILD_DIR/build-$TYPE/dovo.app -ov -format UDZO dovo.dmg

echo "If you are getting a fchmodat error, please modify boost/libs/filessystem/src/operations.cpp.  Find the call to fchmodat and disable the #if using '#if 0 &&"
echo "If you are getting macosx-version-min error, in boost/tools/build/src/tools/darwin.jam after feature macosx-version-min add a new line"
echo "feature.extend macosx-version-min : 10.9 ;"
