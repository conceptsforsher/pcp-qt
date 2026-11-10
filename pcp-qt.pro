# PCP Qt — pcp-qt.pro
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 https://pcp.chat contributors
#
# Based on Spectral tag 464 (Oct 2018, Qt 5.10/5.11 era, qmake, C++14),
# itself a descendant of Matrique. See README.md and COMPAT/Qt56.md.
#
# First difference vs upstream: buildable on Qt 5.6, targeting
# Android 4.0 (API 14) down to Android 2.3 (API 9).

QT += quick widgets

# QtMultimedia is only used for voice-message playback. If the module is
# missing (minimal builds), playback becomes a no-op warning instead of a
# hard build error.
qtHaveModule(multimedia) {
    QT += multimedia
} else {
    DEFINES += PCP_NO_MULTIMEDIA
    message("QtMultimedia not found - audio playback will be disabled.")
}

unix:!mac:!android {
    QT += dbus
}

mac {
    QT += macextras
}

android {
    QT += androidextras
    # androiddeployqt (Qt 5.6) packages everything under android/.
    ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android
    # Let androiddeployqt auto-detect all Qt dependencies (QML imports, plugins, libs).
    # The platform plugin (libqtforandroid.so) is auto-detected via the
    # platform plugin's dependencies. No explicit ANDROID_DEPLOYMENT_DEPENDENCIES
    # needed — explicit list REPLACES auto-detection (causing missing libs).
}

# Qt 5.6 + GCC 4.9 (desktop) / NDK r10e (Android) understand C++14 well
# enough for this codebase. If your old NDK only has GCC 4.8, switch to:
#   CONFIG -= c++14
#   CONFIG += c++11
CONFIG += c++14
CONFIG += object_parallel_to_source
CONFIG += link_pkgconfig

TARGET = pcp-chat

isEmpty(USE_SYSTEM_SORTFILTERPROXYMODEL) {
    USE_SYSTEM_SORTFILTERPROXYMODEL = false
}
isEmpty(USE_SYSTEM_QMATRIXCLIENT) {
    USE_SYSTEM_QMATRIXCLIENT = false
}

$$USE_SYSTEM_QMATRIXCLIENT {
    PKGCONFIG += QMatrixClient
} else {
    message("Falling back to built-in libQMatrixClient.")
    include(include/libqmatrixclient/libqmatrixclient.pri)
}
$$USE_SYSTEM_SORTFILTERPROXYMODEL {
    PKGCONFIG += SortFilterProxyModel
} else {
    message("Falling back to built-in SortFilterProxyModel.")
    include(include/SortFilterProxyModel/SortFilterProxyModel.pri)
}

DEFINES += QT_DEPRECATED_WARNINGS

RESOURCES += \
    res.qrc

QML_IMPORT_PATH += $$PWD/imports/
QML_DESIGNER_IMPORT_PATH += imports/

unix:!mac:!android:isEmpty(PREFIX) {
    message("Install PREFIX not set; using /usr/local. You can change this with 'qmake PREFIX=...'")
    PREFIX = /usr/local
}
unix:!mac:!android:isEmpty(BINDIR) {
    message("Install BINDIR not set; using PREFIX/bin. You can change this with 'qmake BINDIR=...'")
    BINDIR = $$PREFIX/bin
}
unix:!mac:!android:target.path = $$BINDIR
mac:target.path = $$PREFIX/bin
win32:target.path = $$PREFIX
!isEmpty(target.path): INSTALLS += target

unix:!mac:!android {
    metainfo.files = $$PWD/chat.pcp.qt.appdata.xml
    metainfo.path = $$PREFIX/share/metainfo
    desktop.files = $$PWD/chat.pcp.qt.desktop
    desktop.path = $$PREFIX/share/applications
    icons.files = $$PWD/icons/hicolor/*
    icons.path = $$PREFIX/share/icons/hicolor
    INSTALLS += metainfo desktop icons
}

win32 {
    RC_ICONS = assets/img/icon.ico
}

mac {
    ICON = assets/img/icon.icns
}

HEADERS += \
    src/controller.h \
    src/roomlistmodel.h \
    src/imageprovider.h \
    src/messageeventmodel.h \
    src/emojimodel.h \
    src/spectralroom.h \
    src/userlistmodel.h \
    src/publicroomlistmodel.h \
    src/userdirectorylistmodel.h \
    src/imageitem.h \
    src/accountlistmodel.h \
    src/spectraluser.h \
    src/notifications/manager.h \
    src/utils.h \
    src/themepalette.h

SOURCES += src/main.cpp \
    src/controller.cpp \
    src/roomlistmodel.cpp \
    src/imageprovider.cpp \
    src/messageeventmodel.cpp \
    src/emojimodel.cpp \
    src/spectralroom.cpp \
    src/userlistmodel.cpp \
    src/publicroomlistmodel.cpp \
    src/userdirectorylistmodel.cpp \
    src/imageitem.cpp \
    src/accountlistmodel.cpp \
    src/spectraluser.cpp \
    src/utils.cpp

unix:!mac:!android {
    SOURCES += src/notifications/managerlinux.cpp
}

android {
    # No D-Bus / desktop notifications on Android 2.3-4.x; the stub manager
    # above keeps the build green, in-app banners are the fallback.
    SOURCES += src/notifications/managerandroid.cpp
}

win32 {
    HEADERS += src/notifications/wintoastlib.h
    SOURCES += src/notifications/managerwin.cpp \
        src/notifications/wintoastlib.cpp
}

mac {
    QMAKE_LFLAGS += -framework Foundation -framework Cocoa
    SOURCES += src/notifications/managermac.mm
}

# Static Qt build (single-file binary, e.g. the linux-arm64 release):
# qmake sets CONFIG+=static automatically when the Qt itself is static,
# so this block is inert for the normal shared-toolchain builds.
# Before running qmake, generate the embedded-QML resource with:
#   COMPAT/gen-static-qml-qrc.sh <static-qt-prefix> <build-dir>
static {
    DEFINES += PCP_STATIC_QT
    QTPLUGIN += qminimal qoffscreen qxcb \
        qtquick2plugin windowplugin qtquickcontrolsplugin \
        qquicklayoutsplugin modelsplugin qtgraphicaleffectsprivate \
        qmlsettingsplugin
    RESOURCES += $$OUT_PWD/qt56-static-qml.qrc
}
