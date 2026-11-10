#!/bin/bash
# Builds the real Qt 5.6.3 toolchain used to verify PCP Qt.
# See COMPAT/TOOLCHAIN.md. No root needed.
# Usage: QT56_PREFIX=$HOME/qt56-toolchain/install ./COMPAT/toolchain-build.sh
set -e
PREFIX="${QT56_PREFIX:-$HOME/qt56-toolchain/install}"
SRC_DIR="${QT56_SRC:-$HOME/qt56-toolchain/qt-everywhere-opensource-src-5.6.3}"

cd "$SRC_DIR"

./configure -prefix "$PREFIX" \
  -release -opensource -confirm-license \
  -c++std c++11 \
  -no-openssl -no-icu -no-sql-mysql \
  -no-xcb -no-eglfs -no-directfb -no-kms \
  -nomake examples -nomake tests \
  -skip qt3d -skip qtactiveqt -skip qtandroidextras -skip qtcanvas3d \
  -skip qtconnectivity -skip qtdoc -skip qtenginio -skip qtimageformats \
  -skip qtlocation -skip qtmacextras -skip qtmultimedia \
  -skip qtscript -skip qtsensors -skip qtserialport -skip qtsvg \
  -skip qtquickcontrols2 -skip qttools -skip qtwayland -skip qtwebchannel \
  -skip qtwebengine -skip qtwebview -skip qtwebsockets \
  -skip qtwinextras -skip qtx11extras -skip qtxmlpatterns

make -j"$(nproc)"
make install
"$PREFIX/bin/qmake" -query QT_VERSION
