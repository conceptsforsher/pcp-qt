// GPL-3.0-only
// Copyright (C) 2026 https://pcp.chat contributors
// Based on Spectral (GPL-3.0). See README.md.
//
// FORK-ONLY: applies the application palette for the app's own light/dark
// theme.
//
// Controls 1 Labels default to SystemPalette.windowText, i.e. they follow the
// *desktop's* colour scheme rather than PSettings.darkTheme. On a
// dark-themed desktop that is white, while this app paints its own light
// backgrounds from PPalette - so every default-coloured label came out white
// on white: the room list rendered avatars with invisible names, and the same
// would happen in the user list, the directories and the settings page.
//
// Setting the palette once fixes all of them at once, instead of colouring
// two dozen call sites. main.qml calls apply() at startup and again whenever
// the user flips the setting.
#ifndef THEMEPALETTE_H
#define THEMEPALETTE_H

#include <QColor>
#include <QGuiApplication>
#include <QObject>
#include <QPalette>

// NB: deliberately no Q_OBJECT and no signals - only the Q_INVOKABLE below
// needs moc, and keeping the class in a header listed in the .pro makes that
// reliable (qmake decides which files to moc when it generates the Makefile,
// so a new Q_OBJECT class inside an existing .cpp is silently skipped).
class ThemePalette : public QObject {
  Q_OBJECT

 public:
  explicit ThemePalette(QObject* parent = nullptr) : QObject(parent) {}

  Q_INVOKABLE void apply(bool dark)
  {
    // Same colours as PCP.Style's PPalette, so the fallback palette
    // and the QML palette agree.
    const QColor window = dark ? QColor("#303030") : QColor("#fafafa");
    const QColor text = dark ? QColor("#f5f5f5") : QColor("#212121");
    const QColor muted = dark ? QColor("#bdbdbd") : QColor("#757575");
    const QColor base = dark ? QColor("#242424") : QColor("#ffffff");

    QPalette p;
    p.setColor(QPalette::Window, window);
    p.setColor(QPalette::WindowText, text);
    p.setColor(QPalette::Base, base);
    p.setColor(QPalette::AlternateBase, window);
    p.setColor(QPalette::Text, text);
    p.setColor(QPalette::BrightText, QColor("#ff5252"));
    p.setColor(QPalette::Button, window);
    p.setColor(QPalette::ButtonText, text);
    p.setColor(QPalette::Light, window.lighter(110));
    p.setColor(QPalette::Midlight, window.lighter(105));
    p.setColor(QPalette::Dark, window.darker(110));
    p.setColor(QPalette::Mid, window.darker(105));
    p.setColor(QPalette::Shadow, QColor("#000000"));
    p.setColor(QPalette::Link, QColor("#498882"));
    p.setColor(QPalette::LinkVisited, QColor("#498882"));
    p.setColor(QPalette::Highlight, QColor("#498882"));
    p.setColor(QPalette::HighlightedText,
               dark ? QColor("#212121") : QColor("#ffffff"));
    // NB: no QPalette::PlaceholderText - that role only arrived in Qt 5.12.
    p.setColor(QPalette::ToolTipBase, text);
    p.setColor(QPalette::ToolTipText, window);

    p.setColor(QPalette::Disabled, QPalette::WindowText, muted);
    p.setColor(QPalette::Disabled, QPalette::Text, muted);
    p.setColor(QPalette::Disabled, QPalette::ButtonText, muted);
    p.setColor(QPalette::Disabled, QPalette::HighlightedText, muted);

    QGuiApplication::setPalette(p);
  }
};

#endif  // THEMEPALETTE_H