# PCP Qt

A Matrix client for old devices — a **NeoChat rewrite** with the goal of
being **runnable on old devices** and, in the end, also **more feature rich**.

- License: **GPL-3.0-only** (`LICENSE`, SPDX headers).
- Authors: **https://pcp.chat contributors**.
- Upstream: [NeoChat](https://invent.kde.org/network/neochat) (KDE),
  via [Spectral](https://gitlab.com/spectral-im/spectral/)
  (`spectral-im/spectral`, first commit Feb 2018).
- Base commit: Spectral tag **464**
  (`8c29382b3eb7a24c5abe3196c78a546329bb75d9`, 2018-10-25,
  "Update org.eu.encom.spectral.appdata.xml").

## History / what this is

At the start, this codebase had the name **Spectral** and it worked on
**Qt 5.10 – Qt 5.11** (qmake, C++14, Qt Quick Controls 2).

This port starts from Spectral tag **464**
(`8c29382`, Oct 2018, still named Spectral,
still Qt 5.10+ per `BUILD.md`) and rebrands the client to
**PCP**.

## First difference: Qt 5.6 + old Android

Our first difference vs upstream is that the client targets **Qt 5.6**, so it
is runnable on **Android 4.0 and older, down to 2.3**:

|                | Upstream (Spectral 464) | PCP Qt      |
|----------------|-------------------------|--------------------------|
| Qt             | 5.10+                   | **5.6** (5.6.3 recommended) |
| QML imports    | QtQuick 2.9, Controls 2.2, Layouts 1.3 | QtQuick 2.6, Controls 1.4, Layouts 1.2 |
| `labs.platform` (Qt ≥ 5.8 only) | used directly (tray icon, StandardPaths) | isolated: tray via lazy `Loader` (`PCP.Compat.TrayIcon`), cache dir via C++ `QStandardPaths` |
| C++            | C++14, Qt-5.10-only `invokeMethod` path | keeps the Qt &lt; 5.10 fallback (`src/imageprovider.cpp`), C++14 with C++11 fallback note in `pcp-qt.pro` |
| Android        | —                       | `android/AndroidManifest.xml`: minSdk 9 (2.3) → target 14 (4.0) |
| Branding       | Spectral / ENCOM        | **PCP**, `chat.pcp.qt`, https://pcp.chat contributors |

## Fork-only changes

Changes that exist only in this fork (not in upstream Spectral/NeoChat):

- **Back button in Settings** (`imports/PCP/Page/SettingForm.ui.qml`):
  upstream has no way back from the Settings page except tapping an
  account avatar — with zero accounts configured that is a dead end.
  The fork adds an explicit Back row returning to the room view.

Details and remaining work (Controls 2 backport on stock Qt 5.6, NDK notes):
[`COMPAT/Qt56.md`](COMPAT/Qt56.md).

## Build

Desktop (Qt 5.6.3):

```sh
qmake pcp-qt.pro
make
```

Android (Qt 5.6 `androiddeployqt`, NDK r10e):

```sh
qmake pcp-qt.pro ANDROID_PACKAGE_SOURCE_DIR=$$PWD/android
make
make install INSTALL_ROOT=android-build
androiddeployqt --input android-libpcp-chat.so-deployment-settings.json \
  --output android-build --deployment bundled
```

Vendored 2018-era deps (no submodule fetch needed):
`include/libqmatrixclient` (Oct 2018), `include/SortFilterProxyModel`
(Oct 2018). Pass `USE_SYSTEM_QMATRIXCLIENT=true` /
`USE_SYSTEM_SORTFILTERPROXYMODEL=true` to use system copies.

## Authors / license

- Authors: https://pcp.chat contributors.
- This program is licensed under GNU General Public License, Version 3 only
  (**GPL-3.0-only**). See `LICENSE` and `AUTHORS`.

Upstream credits: Spectral / Matrique by Black Hat and contributors
(GPL-3.0), libQMatrixClient (now libQuotient), Quaternion models,
SortFilterProxyModel.
