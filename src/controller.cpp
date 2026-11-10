#include "controller.h"

#include "settings.h"
#include "spectralroom.h"
#include "spectraluser.h"

#include "events/eventcontent.h"
#include "events/roommessageevent.h"

#include "csapi/joining.h"
#include "csapi/logout.h"

#include <QClipboard>
#include <QFile>
#include <QFileInfo>
#include <QtCore/QDebug>
#include <QtCore/QDir>
#include <QtCore/QElapsedTimer>
#include <QtCore/QFileInfo>
#include <QtCore/QStandardPaths>
#include <QtCore/QStringBuilder>
#include <QtCore/QTimer>
// FORK-ONLY: QSslSocket::supportsSsl() tells us at runtime whether this
// Qt was built with OpenSSL (guarded for -no-openssl builds).
#ifndef QT_NO_SSL
#include <QtNetwork/QSslSocket>
#endif
#include <QtGui/QCloseEvent>
#include <QtGui/QDesktopServices>
#include <QtGui/QMovie>
#include <QtGui/QPixmap>
#include <QtNetwork/QAuthenticator>
#include <QtNetwork/QNetworkReply>

Controller::Controller(QObject* parent)
    : QObject(parent), notificationsManager(this) {
  QApplication::setQuitOnLastWindowClosed(false);

  connect(&notificationsManager, &NotificationsManager::notificationClicked,
          this, &Controller::notificationClicked);

  Connection::setRoomType<SpectralRoom>();
  Connection::setUserType<SpectralUser>();

  QTimer::singleShot(0, this, SLOT(invokeLogin()));
}

Controller::~Controller() {}

inline QString accessTokenFileName(const AccountSettings& account) {
  QString fileName = account.userId();
  fileName.replace(':', '_');
  return QStandardPaths::writableLocation(
             QStandardPaths::AppLocalDataLocation) +
         '/' + fileName;
}

// FORK-ONLY: single funnel for every login outcome, so the UI can never
// be left showing "Logging in...".
void Controller::setLoginInProgress(bool inProgress) {
  if (m_loginInProgress == inProgress)
    return;
  m_loginInProgress = inProgress;
  emit loginInProgressChanged();
}

void Controller::loginWithCredentials(QString serverAddr, QString user,
                                      QString pass) {
  if (!user.isEmpty() && !pass.isEmpty()) {
    setLoginInProgress(true);
    Connection* m_connection = new Connection(this);
    m_connection->setHomeserver(QUrl(serverAddr));
    m_connection->connectToServer(user, pass, "");
    connect(m_connection, &Connection::connected, [=] {
      AccountSettings account(m_connection->userId());
      account.setKeepLoggedIn(true);
      account.clearAccessToken();  // Drop the legacy - just in case
      account.setHomeserver(m_connection->homeserver());
      account.setDeviceId(m_connection->deviceId());
      account.setDeviceName("PCP");
      if (!saveAccessToken(account, m_connection->accessToken()))
        qWarning() << "Couldn't save access token";
      account.sync();
      addConnection(m_connection);
      setLoginInProgress(false);
      emit loginSucceeded();
    });
    connect(m_connection, &Connection::networkError,
            [=](QString error, QString, int, int) {
              emit errorOccured("Network Error", error);
              setLoginInProgress(false);
              emit loginFailed();
            });
    connect(m_connection, &Connection::loginError,
            [=](QString error, QString) {
              emit errorOccured("Login Failed", error);
              setLoginInProgress(false);
              emit loginFailed();
            });
    // FORK-ONLY: Qt built -no-openssl (as our Qt 5.6.3 is) cannot speak
    // HTTPS at all; the request then never even reaches the network and
    // the job retries silently for ~a minute. Detect that right away
    // instead of leaving the login screen on "Logging in..." forever.
    if (serverAddr.startsWith("https", Qt::CaseInsensitive) &&
#ifndef QT_NO_SSL
        !QSslSocket::supportsSsl()
#else
        true  // QT_NO_SSL: this build can never do https
#endif
    ) {
      emit errorOccured(
          "This build has no HTTPS support",
          "PCP was built against a Qt without OpenSSL, so it "
          "cannot connect to Matrix homeservers over https:// (got: "
          "\"Protocol \\\"https\\\" is unknown\"). Rebuild Qt with OpenSSL "
          "support, or use a plain http:// homeserver for testing.");
      setLoginInProgress(false);
      emit loginFailed();
      m_connection->deleteLater();
      return;
    }
  }
}

void Controller::logout(Connection* conn) {
  if (!conn) {
    qCritical() << "Attempt to logout null connection";
    return;
  }

  SettingsGroup("Accounts").remove(conn->userId());
  QFile(accessTokenFileName(AccountSettings(conn->userId()))).remove();

  auto job = conn->callApi<LogoutJob>();
  connect(job, &LogoutJob::finished, conn, [=] {
    conn->stopSync();
    emit conn->stateChanged();
    emit conn->loggedOut();
  });
  connect(job, &LogoutJob::failure, this, [=] {
    emit errorOccured("Server-side Logout Failed", job->errorString());
  });
}

void Controller::addConnection(Connection* c) {
  Q_ASSERT_X(c, __FUNCTION__, "Attempt to add a null connection");

  m_connections.push_back(c);

  connect(c, &Connection::syncDone, this, [=] {
    c->saveState();
    c->sync(30000);
  });
  connect(c, &Connection::loggedOut, this, [=] { dropConnection(c); });

  using namespace QMatrixClient;

  c->sync(30000);

  emit connectionAdded(c);
}

void Controller::dropConnection(Connection* c) {
  Q_ASSERT_X(c, __FUNCTION__, "Attempt to drop a null connection");
  m_connections.removeOne(c);

  emit connectionDropped(c);
  c->deleteLater();
}

void Controller::invokeLogin() {
  using namespace QMatrixClient;
  const auto accounts = SettingsGroup("Accounts").childGroups();
  for (const auto& accountId : accounts) {
    AccountSettings account{accountId};
    if (!account.homeserver().isEmpty()) {
      auto accessToken = loadAccessToken(account);

      auto c = new Connection(account.homeserver(), this);
      auto deviceName = account.deviceName();
      connect(c, &Connection::connected, this, [=] {
        c->loadState();
        addConnection(c);
      });
      connect(c, &Connection::loginError,
              [=](QString error, QString) {
                emit errorOccured("Login Failed", error);
              });
      connect(c, &Connection::networkError,
              [=](QString error, QString, int, int) {
                emit errorOccured("Network Error", error);
              });
      c->connectWithToken(account.userId(), accessToken, account.deviceId());
    }
  }
  emit initiated();
}

QByteArray Controller::loadAccessToken(const AccountSettings& account) {
  QFile accountTokenFile{accessTokenFileName(account)};
  if (accountTokenFile.open(QFile::ReadOnly)) {
    if (accountTokenFile.size() < 1024) return accountTokenFile.readAll();

    qWarning() << "File" << accountTokenFile.fileName() << "is"
               << accountTokenFile.size()
               << "bytes long - too long for a token, ignoring it.";
  }
  qWarning() << "Could not open access token file"
             << accountTokenFile.fileName();

  return {};
}

bool Controller::saveAccessToken(const AccountSettings& account,
                                 const QByteArray& accessToken) {
  // (Re-)Make a dedicated file for access_token.
  QFile accountTokenFile{accessTokenFileName(account)};
  accountTokenFile.remove();  // Just in case

  auto fileDir = QFileInfo(accountTokenFile).dir();
  if (!((fileDir.exists() || fileDir.mkpath(".")) &&
        accountTokenFile.open(QFile::WriteOnly))) {
    emit errorOccured("Token", "Cannot save access token.");
  } else {
    accountTokenFile.write(accessToken);
    return true;
  }
  return false;
}

void Controller::joinRoom(Connection* c, const QString& alias) {
  // NOTE (PCP Qt, fork-only): upstream never guarded against a
  // null connection (e.g. tapping + with no account). Refuse cleanly instead
  // of crashing.
  if (!c) {
    emit errorOccured("Join Room Failed",
                      "No active account — please log in first.");
    return;
  }
  JoinRoomJob* joinRoomJob = c->joinRoom(alias);
  joinRoomJob->connect(joinRoomJob, &JoinRoomJob::failure, [=] {
    emit errorOccured("Join Room Failed", joinRoomJob->errorString());
  });
}

void Controller::createRoom(Connection* c, const QString& name,
                            const QString& topic) {
  if (!c) {
    emit errorOccured("Create Room Failed",
                      "No active account — please log in first.");
    return;
  }
  CreateRoomJob* createRoomJob =
      c->createRoom(Connection::PublishRoom, "", name, topic, QStringList());
  createRoomJob->connect(createRoomJob, &CreateRoomJob::failure, [=] {
    emit errorOccured("Create Room Failed", createRoomJob->errorString());
  });
}

void Controller::createDirectChat(Connection* c, const QString& userID) {
  if (!c) {
    emit errorOccured("Create Direct Chat Failed",
                      "No active account — please log in first.");
    return;
  }
  CreateRoomJob* createRoomJob = c->createDirectChat(userID);
  createRoomJob->connect(createRoomJob, &CreateRoomJob::failure, [=] {
    emit errorOccured("Create Direct Chat Failed",
                      createRoomJob->errorString());
  });
}

void Controller::copyToClipboard(const QString& text) {
  m_clipboard->setText(text);
}

// FORK-ONLY: see the declaration - Connection::accessToken() is not reachable
// from QML in this libQMatrixClient revision.
QString Controller::accessTokenOf(Connection* conn) {
  if (!conn) return QString();
  return QString::fromLatin1(conn->accessToken());
}

void Controller::playAudio(QUrl localFile) {
#ifdef PCP_NO_MULTIMEDIA
  Q_UNUSED(localFile);
  qWarning() << "Audio playback is disabled (built without QtMultimedia)";
#else
  QMediaPlayer* player = new QMediaPlayer;
  player->setMedia(localFile);
  player->play();
  connect(player, &QMediaPlayer::stateChanged, [=] { player->deleteLater(); });
#endif
}

QImage Controller::safeImage(QImage image) {
  if (image.isNull()) return QImage();
  return image;
}

QColor Controller::color(QString userId) {
  return QColor(SettingsGroup("UI/Color").value(userId, "#498882").toString());
}

void Controller::setColor(QString userId, QColor newColor) {
  SettingsGroup("UI/Color").setValue(userId, newColor.name());
}

void Controller::postNotification(const QString& roomId, const QString& eventId,
                                  const QString& roomName,
                                  const QString& senderName,
                                  const QString& text, const QImage& icon,
                                  const QUrl& iconPath) {
  notificationsManager.postNotification(roomId, eventId, roomName, senderName,
                                        text, icon, iconPath);
}

// FORK-ONLY: mark-all-as-read ported from Sep 2019.
void Controller::markAllMessagesAsRead(Connection* conn) {
  if (!conn) {
    qCritical() << "Attempt to mark all as read on null connection";
    return;
  }
  for (auto room : conn->roomMap().values()) {
    room->markAllMessagesAsRead();
  }
}
