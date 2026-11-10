# Real Qt 5.6 toolchain

The Qt 5.6 port is verified with a real Qt 5.6.3 built from source
(`qt-everywhere-opensource-src-5.6.3`), not just API review. This file
documents how to reproduce it. No root needed.

## Layout (on the build machine)

- `/home/user/qt56-toolchain/` — toolchain root (persistent disk, NOT /tmp)
  - `qt-5.6.3.tar.xz` — upstream tarball (`download.qt.io/archive/qt/5.6/5.6.3/single/`)
  - `qt-everywhere-opensource-src-5.6.3/` — extracted sources + 2 small patches (below)
  - `build-qt56.sh` — configure+build+install script used
  - `install/` — the toolchain (`install/bin/qmake` reports `5.6.3`)
  - `app-build/` — PCP Qt built with that qmake
  - `qmltest/` — headless QML harness + farm tests (persistent re-creation
    of the /tmp scratch tests)
  - `build.log`, `install.log`, `app-build.log` — full logs

## Reproduce

```sh
# 1. fetch + extract
curl -o qt-5.6.3.tar.xz https://download.qt.io/archive/qt/5.6/5.6.3/single/qt-everywhere-opensource-src-5.6.3.tar.xz
tar -xf qt-5.6.3.tar.xz
# 2. configure + build + install (COMPAT/toolchain-build.sh)
./configure -prefix $PREFIX -release -opensource -confirm-license \
  -c++std c++11 -no-openssl -no-icu \
  -no-xcb -no-eglfs -no-directfb -no-kms \
  -nomake examples -nomake tests \
  -skip qt3d -skip qtactiveqt -skip qtandroidextras -skip qtcanvas3d \
  -skip qtconnectivity -skip qtdoc -skip qtenginio -skip qtimageformats \
  -skip qtlocation -skip qtmacextras -skip qtmultimedia \
  -skip qtscript -skip qtsensors -skip qtserialport -skip qtsvg \
  -skip qtquickcontrols2 -skip qttools -skip qtwayland -skip qtwebchannel \
  -skip qtwebengine -skip qtwebview -skip qtwebsockets \
  -skip qtwinextras -skip qtx11extras -skip qtxmlpatterns
make -j$(nproc)
make install
# 3. build the app
$PREFIX/bin/qmake pcp-qt.pro && make -j$(nproc)
# 4. run headless (needs a platform plugin; offscreen/minimal ship by default)
QT_QPA_PLATFORM=offscreen ./pcp-chat
```

Notes:

- Host compiler here is GCC 16 (aarch64); `-c++std c++11` keeps the 2017
  codebase compiling. Two Qt-source patches were needed (kept in the source
  tree, both documented at the patch site):
  - `qtbase/qmake/generators/makefile.cpp`: `requires` → `pkgconfigRequires`
    (`requires` is a C++20 keyword).
  - configure `-no-icu`: system ICU is too new for Qt 5.6's `qicucodec`
    (iconv fallback is used instead).
- If you re-run `configure` in an existing tree, delete stale PCH first:
  `find . -type d -name .pch -exec rm -rf {} +`.
- QtMultimedia is skipped on purpose: the app compiles without it
  (`PCP_NO_MULTIMEDIA`, audio playback becomes a warning).
  Same for OpenSSL (`-no-openssl`; `QT_NO_SSL` guards in the vendored lib).
- `make install` provides real QtQuick.Controls 1.4 / Styles /
  QtGraphicalEffects / `Qt.labs.settings` 1.0 — no `Qt.labs.platform`
  on 5.6 (tray icon stays `Loader`-guarded by design).

## Headless QML harness (`qmltest/`)

No X server, no GL, no way to look at the UI — so the QML is verified by
loading it into a real QtQuick engine offscreen and asserting on what came
out. The harness **links the app's own sources** (`qmlcheck.pro` lists them,
including the vendored `libQMatrixClient` and `SortFilterProxyModel`; only
`main.cpp` is left out, since `main()` would collide). That matters: an
earlier version registered hand-written stand-ins for the models, which
carried the same role names *by hand* — so a rename in a real model could not
be caught, and role names are exactly what has broken repeatedly.

```sh
cd /home/user/qt56-toolchain/qmltest
mkdir -p build && cd build
/home/user/qt56-toolchain/install/bin/qmake ../qmlcheck.pro && make -j4

cd ..
export QT_QPA_PLATFORM=offscreen \
       QMLCHECK_IMPORT_PATHS=$PWD/stubs:/home/user/pcp-android-qt/imports \
       QMLCHECK_RCC=$PWD/test.rcc
for f in t_*.qml; do ./build/qmlcheck $f; done     # prints RESULT:PASS per file
```

Notes:

- `-fuse-ld=gold` is set in `qmlcheck.pro`: this Qt carries DWARF 5, which the
  distro's default `ld` cannot parse.
- **Always use `/home/user/qt56-toolchain/install/bin/qmake`, never a bare
  `qmake`.** `/usr/bin/qmake` is a different Qt, and the damage is not obvious:
  it regenerates a `Makefile` with that Qt's flags (including `-fno-rtti`, so
  `qmlcheck.cpp`'s `dynamic_cast` stops compiling) *and* leaves `moc_*.cpp`
  files behind that the next 5.6.3 build then fails on with
  `QT_WARNING_DISABLE_DEPRECATED does not name a type`. Recovery is
  `make clean` in `build/` before re-running the toolchain qmake. If RTTI
  errors appear, check which qmake ran first — `qmlcheck.pro` keeps an explicit
  `-frtti` as a second line of defence.
- The import paths are resolved against the **current directory**, not against
  `qmlcheck.pro`, so from `build/` the app is three levels up:
  ```
  cd build && \
  QT_QPA_PLATFORM=offscreen \
  QMLCHECK_IMPORT_PATHS=/home/user/qt56-toolchain/qmltest/stubs:/home/user/pcp-android-qt/imports \
  QMLCHECK_RCC=/home/user/qt56-toolchain/qmltest/test.rcc \
  ./qmlcheck t_delegates.qml
  ```
  A relative `stubs:../../pcp-android-qt/imports` (as the comment in
  `qmlcheck.pro` suggests) silently loads nothing — every test then reports
  `module "PCP.Setting" is not installed` and `RESULT:FAIL`.
- Sources are referenced **relatively** on purpose. Both vendored `.pri` files
  set `object_parallel_to_source`, and for absolute paths qmake writes the
  `.o` files *next to the sources* — into the app's source tree, where the
  release build keeps its own objects. Building the harness would then
  overwrite those and the next app link would pick up harness objects.
- `testroom.h` builds a **real** connection and room: a `/sync` response goes
  through libQMatrixClient's `SyncData::parseJson()` and the connection's
  `onSyncSuccess()`, so the Connection creates a real `SpectralRoom` and
  `MessageEventModel`/`UserListModel`/`RoomListModel` run the app's actual
  `DisplayRole`, author and event-type logic. The homeserver is pointed at a
  closed loopback port because `connectWithToken()` also fetches
  `/capabilities`; the harness never reaches the network.
- `mxc://` image requests go to a null provider: the real `ImageProvider`
  downloads, and it runs on Qt's pixmap reader thread with a *blocking*
  `invokeMethod` on the connection, which is a crash waiting for teardown.
  `ImageItem` itself is the real C++ type, so property-type mistakes are still
  caught.
- `test.rcc` is regenerated whenever `js/util.js` changes (from the repo root):
  `/home/user/qt56-static/install/bin/rcc --binary --output qmltest/test.rcc res.qrc`
  `--binary` matters: the default output fails to register on this Qt. So does
  the *toolchain's* rcc: `/usr/bin/rcc` is Qt 5.15, and a bundle it writes is
  rejected at registration time with `RCC-REGISTER-FAILED`, after which every
  test that reads `qrc:/js/…` fails with "Script unavailable" rather than with
  anything pointing at the rcc.
- Where a real object cannot be injected (a role named `name` is shadowed by
  `Item.name`, a role called `time` would need a live room), tests use
  `rolemodel.h` — a plain test fixture, not a stub of app code. Its role names
  are read off the real models, so it cannot drift.
- The default event-loop wait is 60ms, enough for bindings/Layouts/delegates to
  settle. A test that *steps through several states* needs
  `QMLCHECK_WAIT_MS=1200` (published to QML as `harnessWaitMs`), or it stops
  part-way and still prints `RESULT:PASS` — a truncated run that looks green.
  `t_copytoken.qml` guards against this itself by counting ticks.
- Qt 5.6 JS/QML traps hit while writing tests, all verified rather than assumed:
  - `new Date().getTime()` saturates at `2147483647` (32-bit int), so elapsed-time
    budgets are useless; count timer ticks instead.
  - `String.prototype.repeat` does not exist ("Property 'repeat' of object • is
    not a function") — build the string in a loop.
  - `item.children.concat(item.data)` throws: `children` is a QObjectList
    wrapper without `concat`. Append into a plain array by index.
  - A `Timer` is a QObject, so it is in `data`, **not** `children`; and
    `toString()` on one prints only its address, so match on
    `restart`/`interval`/`triggered` rather than the class name (it is
    `QQmlTimer`, not `QQuickTimer`).
  - `timer.triggered()` called from JS reaches only handlers registered from JS,
    not an inline `onTriggered`. To exercise an inline handler, set
    `interval = 1; restart()` and let the loop run.
  - A Controls 1 `TextField` reports its type as plain `TextField` and wraps a
    real `TextInput` in `TextInputWithHandles`; matching on `QQuickTextInput`
    finds nothing. Locate such fields by position among read-only fields.
  - A component created inline resolves an unqualified name against the **file's**
    context (root's properties/ids), not along the visual parent chain — so test
    roles go on the root item, and never on the delegate itself (that shadows the
    roles). A JS array model cannot supply them at all: keys are only exposed as
    `model.<key>`, leaving `connection` undefined.

## Verification results (this toolchain)

- `qmake pcp-qt.pro && make` — clean, `pcp-chat` links.
- App startup headless: all QML loads (login/room/setting pages, dialogs,
  menus, drawer), models init, `Model timeline reset` reached. First paint
  needs GL (absent on headless CI) — identical for any QtQuick app.
- QML farm tests (delegates, room/account delegates, component kit) under
  the real 5.6 QML engine — zero errors/warnings.
- Bugs the real toolchain caught (all fixed in repo): missing
  `QDateTime`/`QPainterPath` includes, `QT_NO_SSL` guards,
  `qmlWarning`/`qmlInfo` shims for Qt < 5.9, `QImage::byteCount` fallback,
  `typingChanged` NOTIFY re-declaration, direct `<QObject>` includes for
  moc, `LocalStorage.transaction()` V4 crash (settings use
  `Qt.labs.settings`, which 5.6 ships), CheckBox binding inversion,
  TextArea width loop, null `currentRoom` guard.

## Android note (working, CI-proven)

APKs build on x86_64 CI (`.github/workflows/android.yml`, green): Qt 5.6.3
for Android (armeabi-v7a, NDK r10e GCC 4.9, android-9 sysroot) + SDK
platforms android-10/14/16 + build-tools 24.0.3. Key ingredients:

- SDK Tools **r25.2.5** (last version with `android update project` and
  `tools/ant/` templates; newer tools dropped both).
- JDK 17 for `sdkmanager`, JDK 8 for the Qt + ant builds (Qt's bundled
  jar needs `-source 6`).
- `androiddeployqt` lives in skipped `qttools` — build it on the host
  with system Qt (`g++ main.cpp -lQt5Core`).
- A local APK build on aarch64 dev boxes is not supported (NDK r10e host
  tools are x86_64-only, no qemu).
- Result: 9.6 MB debug APK with `lib/armeabi-v7a/libpcp-chat.so`
  plus Qt 5.6 Core/Gui/Network/Qml/Quick/Widgets.
- `android/AndroidManifest.xml` declares minSdk 9 / targetSdk 14.

## HTTPS / OpenSSL (why logins looked "forever loading")

Qt 5.6 built with `-no-openssl` **cannot speak HTTPS at all**: every
`QNetworkReply` fails locally with

    err 301  "Protocol \"https\" is unknown"

Matrix homeservers are HTTPS-only, so every login died before the first
packet. `BaseJob` then retried that job silently for ~a minute and
nothing reached the UI — hence a login button stuck on "Logging in...".
Spectral/NeoChat never showed this because its Qt linked OpenSSL.

Fix: `COMPAT/build-qt56-ssl.sh` builds OpenSSL **1.0.2u** (Qt 5.6 does
*not* support 1.1.x — `struct x509_st` became opaque and
`qsslcertificate_openssl.cpp` stops compiling; 1.1 support came with
Qt 5.9) and reconfigures the static Qt 5.6.3 with `-openssl-linked`.

Two gotchas baked into the script:

1. `./configure` only passes `-I`/`-L` to its own feature tests, never to
   the library build, so the OpenSSL include/lib path must be injected
   into `qtbase/src/network/ssl/ssl.pri` by hand.
2. `OPENSSL_LIBS=...` must be an **environment** variable; passing it as
   a configure argument makes configure bail with "unknown argument".

Verified: `QSslSocket::supportsSsl() == true` and a live request to
`https://matrix.org/_matrix/client/versions` returns HTTP 200 from a
binary built with this toolchain.
