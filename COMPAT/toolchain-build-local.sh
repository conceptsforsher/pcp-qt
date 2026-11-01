#!/bin/bash
# Local variant of COMPAT/toolchain-build.sh with the host paths filled in
# (see COMPAT/TOOLCHAIN.md). Kept because a desktop box differs from CI.
# Builds the real Qt 5.6.3 toolchain used to verify Progressive Chat Qt.
# No root needed. Result: $PREFIX/{bin,lib,qml,...} with Qt 5.6.3 for the
# host (aarch64 here; x86_64 works the same).
set -e
SRC=${QT56_ROOT:-$HOME/qt56-toolchain}/qt-everywhere-opensource-src-5.6.3
PREFIX=${QT56_ROOT:-$HOME/qt56-toolchain}/install

cd "$SRC"

# If re-running after a failed attempt, reset qmake cache (keep objects):
#   rm -f .qmake.cache config.cache

./configure -prefix "$PREFIX" \
  -release -opensource -confirm-license \
  -c++std c++11 \
  -no-openssl -no-icu \
  -no-xcb -no-eglfs -no-directfb -no-kms \
  -nomake examples -nomake tests \
  -skip qt3d -skip qtactiveqt -skip qtandroidextras -skip qtcanvas3d \
  -skip qtconnectivity -skip qtdoc -skip qtenginio -skip qtimageformats \
  -skip qtlocation -skip qtmacextras -skip qtmultimedia \
  -skip qtscript -skip qtsensors -skip qtserialport -skip qtsvg \
  -skip qtquickcontrols2 -skip qttools -skip qtwayland -skip qtwebchannel -skip qtwebengine -skip qtwebview -skip qtwebsockets \
  -skip qtwinextras -skip qtx11extras -skip qtxmlpatterns

make -j4
make install
"$PREFIX/bin/qmake" -query QT_VERSION
