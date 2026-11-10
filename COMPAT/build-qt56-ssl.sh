#!/bin/bash
# Builds OpenSSL 1.0.2u + a static Qt 5.6.3 that has HTTPS support.
#
# WHY THIS EXISTS
# ---------------
# Matrix homeservers are HTTPS-only. A Qt built with -no-openssl cannot
# speak https:// at all: QNetworkReply fails with
#   err 301 "Protocol \"https\" is unknown"
# before any packet leaves the host, so logins silently never happen.
#
# Qt 5.6 supports ONLY OpenSSL 1.0.x. In OpenSSL 1.1+ struct x509_st is
# opaque and qtbase/src/network/ssl/qsslcertificate_openssl.cpp (which
# dereferences it) fails with "invalid use of incomplete type 'X509'".
# 1.1.x support landed in Qt 5.9. Hence 1.0.2u, not 1.1.1w.
#
# Qt's ./configure only passes -I/-L to its own feature tests, NOT to the
# library build, so the OpenSSL path has to be injected into
# qtbase/src/network/ssl/ssl.pri (patched below).
#
# Usage: build-qt56-ssl.sh
set -e

SSL_VER=1.0.2u
SSL_SRC_DIR=/home/user/openssl10
SSL_PREFIX=/home/user/openssl10/install

QT_SRC_DIR=/home/user/qt56-static/qt-everywhere-opensource-src-5.6.3
QT_PREFIX=/home/user/qt56-static/install

# ---------------------------------------------------------------- OpenSSL
mkdir -p "$SSL_SRC_DIR"
cd "$SSL_SRC_DIR"
if [ ! -d "openssl-$SSL_VER" ]; then
  curl -sL -o "openssl-$SSL_VER.tar.gz" \
    "https://github.com/openssl/openssl/releases/download/OpenSSL_$SSL_VER/openssl-$SSL_VER.tar.gz"
  tar xf "openssl-$SSL_VER.tar.gz"
fi
cd "openssl-$SSL_VER"
if [ ! -f "$SSL_PREFIX/lib/libssl.a" ]; then
  ./config --prefix="$SSL_PREFIX" --openssldir="$SSL_PREFIX/ssl" \
           no-shared no-tests -fPIC
  make -j"$(nproc)"
  make install_sw
fi
"$SSL_PREFIX/bin/openssl" version   # expect: OpenSSL 1.0.2u

# -------------------------------------------------------------- Qt patch
cd "$QT_SRC_DIR"
SSL_PRI=qtbase/src/network/ssl/ssl.pri
if ! grep -q "PCP Qt: Qt 5.6 supports only OpenSSL 1.0.x" "$SSL_PRI"; then
  python3 - "$SSL_PRI" "$SSL_PREFIX" <<'PY'
import sys
path, prefix = sys.argv[1], sys.argv[2]
s = open(path).read()
anchor = "    android:!android-no-sdk: SOURCES += ssl/qsslsocket_openssl_android.cpp\n"
block = anchor + """
    # PCP Qt: Qt 5.6 supports only OpenSSL 1.0.x - in 1.1.x
    # struct x509_st became opaque and qsslcertificate_openssl.cpp (which
    # dereferences it) fails to compile. Point at our own OpenSSL 1.0.2u
    # build: configure only uses -I for its own feature tests, so the path
    # does not reach the library build on its own.
    OPENSSL_PREFIX = %s
    INCLUDEPATH += $$OPENSSL_PREFIX/include
    LIBS_PRIVATE += -L$$OPENSSL_PREFIX/lib -lssl -lcrypto
""" % prefix
assert anchor in s
open(path, "w").write(s.replace(anchor, block, 1))
print("patched", path)
PY
fi

# ------------------------------------------------------------ Qt configure
# -openssl-linked is the static-SSL mode. config.summary must say:
#   OpenSSL .............. yes (linked to the libraries)
OPENSSL_LIBS="-L$SSL_PREFIX/lib -lssl -lcrypto" ./configure \
  -prefix "$QT_PREFIX" -static -release -opensource -confirm-license \
  -c++std c++11 -openssl-linked -I "$SSL_PREFIX/include" \
  -no-icu -no-eglfs -no-directfb -no-kms \
  -nomake examples -nomake tests \
  -skip qt3d -skip qtactiveqt -skip qtandroidextras -skip qtcanvas3d \
  -skip qtconnectivity -skip qtdoc -skip qtenginio -skip qtimageformats \
  -skip qtlocation -skip qtmacextras -skip qtmultimedia -skip qtscript \
  -skip qtsensors -skip qtserialport -skip qtsvg -skip qtquickcontrols2 \
  -skip qttools -skip qtwayland -skip qtwebchannel -skip qtwebengine \
  -skip qtwebview -skip qtwebsockets -skip qtwinextras -skip qtx11extras \
  -skip qtxmlpatterns

grep -m1 "OpenSSL" qtbase/config.summary

make -j"$(nproc)"
make install

# ------------------------------------------------------------------- app
# Embed the static Qt's QML modules, then build the single-file binary.
APP_BUILD=/home/user/qt56-static/app-build
mkdir -p "$APP_BUILD"
/home/user/pcp-android-qt/COMPAT/gen-static-qml-qrc.sh "$QT_PREFIX" "$APP_BUILD"
cd "$APP_BUILD"
"$QT_PREFIX/bin/qmake" /home/user/pcp-android-qt/pcp-qt.pro
make -j"$(nproc)"

# Sanity check: the binary must contain OpenSSL and no dynamic Qt deps.
nm pcp-chat | grep -c SSL_
ldd pcp-chat | grep -c libQt   # expect 0
echo "OK: single-file HTTPS-capable binary at $APP_BUILD/pcp-chat"