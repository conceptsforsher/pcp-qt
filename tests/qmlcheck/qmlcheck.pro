# qmlcheck.pro — the headless QML harness, built from the REAL app sources.
#
# Test-only. The point of this file is that the harness links exactly the
# C++ the app ships (models, enums, ImageItem, EmojiModel, libQMatrixClient,
# SortFilterProxyModel) instead of hand-written stand-ins. The hand-written
# QML stubs for the models carried the same role names *by hand*, so a rename
# in a real model could not be caught here - and role names are exactly what
# has been breaking (a role called "name" loses to Item.name, the DisplayRole
# text is what the timeline renders, and so on).
#
# Only main.cpp is left out: it owns the crash handler, the screenshot
# shortcut, the palette bridge and the OAuth start-up, none of which the
# harness needs (and main() would collide with the harness's own). The type
# registrations in qmlcheck.cpp are copied from it.
#
# NB: sources are referenced RELATIVELY on purpose. Both vendored .pri files
# set object_parallel_to_source, and for absolute paths qmake then writes the
# .o files *next to the sources* - straight into the app's source tree, where
# the release build keeps its own objects. Building the harness would
# overwrite those and the next app link would pick up harness objects (this
# happened; the app has to be rebuilt afterwards). With relative paths qmake
# mirrors the structure under build/ instead.
#
# Build (out-of-source, so the harness never touches the app tree):
#   cd build && \
#     ${QT56_ROOT:-$HOME/qt56-toolchain}/install/bin/qmake ../qmlcheck.pro && make -j4
# Run (import paths are relative to the CWD, and the app is three levels up
# from build/ - see the note on -frtti below for why the bare `qmake` on PATH
# must not be used):
#   QT_QPA_PLATFORM=offscreen \
#   QMLCHECK_IMPORT_PATHS=${QT56_ROOT:-$HOME/qt56-toolchain}/qmltest/stubs:${PCP_QT:-$HOME/pcp-android-qt}/imports \
#   QMLCHECK_RCC=${QT56_ROOT:-$HOME/qt56-toolchain}/qmltest/test.rcc ./qmlcheck t_*.qml
#
# Tests that step through several states need a longer event loop than the
# default 60ms settle, or they stop part-way and still report RESULT:PASS:
#   QMLCHECK_WAIT_MS=1200 ./qmlcheck t_copytoken.qml
QT += quick widgets network dbus

qtHaveModule(multimedia) {
    QT += multimedia
} else {
    DEFINES += PCP_NO_MULTIMEDIA
}

CONFIG += c++14 console link_pkgconfig
CONFIG -= app_bundle

# The Qt 5.6.3 build in this toolchain carries DWARF 5, which the distro's
# default binutils cannot parse ("bad subsection length" / "'comprehension'
# seems corrupted"). gold copes.
QMAKE_LFLAGS += -fuse-ld=gold

TARGET = qmlcheck

APP = ../../pcp-android-qt

# The two vendored libraries, built from source exactly as the app does.
include($$APP/include/libqmatrixclient/libqmatrixclient.pri)
include($$APP/include/SortFilterProxyModel/SortFilterProxyModel.pri)

# Belt and braces: qmlcheck.cpp uses dynamic_cast, so RTTI must be on. It is
# on with the toolchain qmake named in the header comment above - the flag you
# saw was NOT from the vendored .pri files (they set no -fno-rtti) but from the
# *system* /usr/bin/qmake, which is a different Qt entirely: building with it
# silently produced moc files that then failed to compile against the 5.6.3
# headers. If RTTI ever goes missing again, check which qmake ran first.
QMAKE_CXXFLAGS += -frtti

INCLUDEPATH += $$APP/src

HEADERS += \
    qmlcheck.cpp \
    rolemodel.h \
    testroom.h \
    $$APP/src/controller.h \
    $$APP/src/roomlistmodel.h \
    $$APP/src/imageprovider.h \
    $$APP/src/messageeventmodel.h \
    $$APP/src/emojimodel.h \
    $$APP/src/spectralroom.h \
    $$APP/src/spectraluser.h \
    $$APP/src/userlistmodel.h \
    $$APP/src/publicroomlistmodel.h \
    $$APP/src/userdirectorylistmodel.h \
    $$APP/src/imageitem.h \
    $$APP/src/accountlistmodel.h \
    $$APP/src/utils.h \
    $$APP/src/themepalette.h \
    $$APP/src/notifications/manager.h

# main.cpp is deliberately absent - see the header comment.
SOURCES += \
    qmlcheck.cpp \
    $$APP/src/controller.cpp \
    $$APP/src/roomlistmodel.cpp \
    $$APP/src/imageprovider.cpp \
    $$APP/src/messageeventmodel.cpp \
    $$APP/src/emojimodel.cpp \
    $$APP/src/spectralroom.cpp \
    $$APP/src/spectraluser.cpp \
    $$APP/src/userlistmodel.cpp \
    $$APP/src/publicroomlistmodel.cpp \
    $$APP/src/userdirectorylistmodel.cpp \
    $$APP/src/imageitem.cpp \
    $$APP/src/accountlistmodel.cpp \
    $$APP/src/utils.cpp     $$APP/src/notifications/managerlinux.cpp