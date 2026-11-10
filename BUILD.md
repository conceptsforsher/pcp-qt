# Build instructions

PCP Qt targets **Qt 5.6** (5.6.3 recommended), desktop and
Android (4.0 down to 2.3). See `README.md` and `COMPAT/Qt56.md`.

## Desktop (Qt 5.6.3)

```sh
git clone https://github.com/pcp-chat/pcp-qt
cd pcp-qt
# deps are vendored under include/ (2018-era snapshots); no submodule
# fetch needed. To use system copies instead:
#   qmake USE_SYSTEM_QMATRIXCLIENT=true USE_SYSTEM_SORTFILTERPROXYMODEL=true
qmake pcp-qt.pro
make
```

## Android (Qt 5.6 `androiddeployqt`, NDK r10e)

- minSdk 9 (Android 2.3), targetSdk 14 (Android 4.0): `android/AndroidManifest.xml`
- For old NDKs with GCC 4.8, switch `CONFIG += c++14` to `c++11` in
  `pcp-qt.pro` (see comment there).

```sh
qmake pcp-qt.pro ANDROID_PACKAGE_SOURCE_DIR=$$PWD/android
make
make install INSTALL_ROOT=android-build
androiddeployqt --input android-libpcp-chat.so-deployment-settings.json \
  --output android-build --deployment bundled
```
