#!/bin/bash
# Generates a .qrc embedding the static Qt's QML module tree so the app
# links QtQuick/Controls/etc. into the binary (single-file deployment).
# Usage: gen-static-qml-qrc.sh <static-qt-prefix> <build-dir>
# Run BEFORE qmake; pcp-qt.pro picks up $build-dir/qt56-static-qml.qrc.
set -e
STATIC_PREFIX="$1"
BUILDDIR="$2"
if [ -z "$STATIC_PREFIX" ] || [ -z "$BUILDDIR" ]; then
  echo "usage: $0 <static-qt-prefix> <build-dir>" >&2
  exit 1
fi
OUT="$BUILDDIR/qt56-static-qml.qrc"
{
  echo '<RCC>'
  echo '<qresource prefix="/qt56qml">'
  cd "$STATIC_PREFIX/qml" && find . -type f | sort | while read -r f; do
    p="$STATIC_PREFIX/qml/${f#./}"
    # Minimal XML escaping for paths.
    p=${p//&/&amp;}
    p=${p//</&lt;}
    p=${p//>/&gt;}
    echo "    <file>$p</file>"
  done
  echo '</qresource>'
  echo '</RCC>'
} > "$OUT"
echo "wrote $OUT"
