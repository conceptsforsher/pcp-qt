#ifndef CONTROLLER_H
#define CONTROLLER_H

#include "connection.h"
#include "notifications/manager.h"
#include "settings.h"
#include "user.h"

#include <QApplication>
#ifdef PCP_NO_MULTIMEDIA
// Audio playback disabled (QtMultimedia missing at build time).
#else
#include <QMediaPlayer>
#endif
#include <QMenu>
#include <QObject>
#include <QSystemTrayIcon>

using namespace QMatrixClient;

class Controller : public QObject {
  Q_OBJECT
  Q_PROPERTY(int accountCount READ accountCount NOTIFY connectionAdded NOTIFY
                 connectionDropped)
  // FORK-ONLY: login progress as a property. The UI used to rely on signal
  // ordering (button text/reset), which could leave it stuck on
  // "Logging in..." if a signal was missed. A property binding cannot
  // desynchronise.
  Q_PROPERTY(bool loginInProgress READ loginInProgress NOTIFY
                 loginInProgressChanged)
  Q_PROPERTY(bool quitOnLastWindowClosed READ quitOnLastWindowClosed WRITE
                 setQuitOnLastWindowClosed NOTIFY quitOnLastWindowClosedChanged)

 public:
  explicit Controller(QObject* parent = nullptr);
  ~Controller();

  // All the Q_INVOKABLEs.
  Q_INVOKABLE void loginWithCredentials(QString, QString, QString);

  QVector<Connection*> connections() { return m_connections; }

  // All the non-Q_INVOKABLE functions.
  void addConnection(Connection* c);
  void dropConnection(Connection* c);

  // All the Q_PROPERTYs.
  int accountCount() { return m_connections.count(); }
  bool loginInProgress() const { return m_loginInProgress; }

  bool quitOnLastWindowClosed() {
    return QApplication::quitOnLastWindowClosed();
  }
  void setQuitOnLastWindowClosed(bool value) {
    if (quitOnLastWindowClosed() != value) {
      QApplication::setQuitOnLastWindowClosed(value);
      emit quitOnLastWindowClosedChanged();
    }
  }

  Q_INVOKABLE QColor color(QString userId);
  Q_INVOKABLE void setColor(QString userId, QColor newColor);

  // FORK-ONLY: the access token of one account, for the NeoChat 2fa6ad22
  // copy-token port in SettingAccountDelegate.qml.
  //
  // This exists because Connection::accessToken() is a plain (non-invokable,
  // non-Q_PROPERTY) getter in this libQMatrixClient revision, so QML cannot
  // read `connection.accessToken` at all - the field came out empty rather
  // than showing the token. Going through Controller keeps the QML free of a
  // per-connection helper object.
  //
  // Returns an empty string (not "undefined") for a null connection, so the
  // caller can test it with a plain length check.
  Q_INVOKABLE QString accessTokenOf(Connection* conn);

 private:
  QClipboard* m_clipboard = QApplication::clipboard();
  NotificationsManager notificationsManager;
  QVector<Connection*> m_connections;

  QByteArray loadAccessToken(const AccountSettings& account);
  bool saveAccessToken(const AccountSettings& account,
                       const QByteArray& accessToken);
  void loadSettings();
  void saveSettings() const;

 private slots:
  void invokeLogin();

 signals:
  void busyChanged();
  void errorOccured(QString error, QString detail);
  // FORK-ONLY: explicit login outcome so the UI can never be left
  // saying "Logging in..." (upstream never fixed this dead end).
  void loginSucceeded();
  void loginFailed();
  void loginInProgressChanged();
  void connectionAdded(Connection* conn);
  void connectionDropped(Connection* conn);
  void initiated();
  void notificationClicked(const QString roomId, const QString eventId);
  void quitOnLastWindowClosedChanged();

 public slots:
  void logout(Connection* conn);
  void joinRoom(Connection* c, const QString& alias);
  void createRoom(Connection* c, const QString& name, const QString& topic);
  void createDirectChat(Connection* c, const QString& userID);
  void copyToClipboard(const QString& text);
  // FORK-ONLY: mark-all-as-read ported from Sep 2019.
  void markAllMessagesAsRead(Connection* conn);
  void playAudio(QUrl localFile);
  void postNotification(const QString& roomId, const QString& eventId,
                        const QString& roomName, const QString& senderName,
                        const QString& text, const QImage& icon,
                        const QUrl& iconPath);

  static QImage safeImage(QImage image);

 private:
  // FORK-ONLY: loginInProgress backing store.
  bool m_loginInProgress = false;
  void setLoginInProgress(bool inProgress);
};

#endif  // CONTROLLER_H
