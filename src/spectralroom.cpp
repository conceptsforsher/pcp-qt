#include "spectralroom.h"

#include "connection.h"
#include "user.h"

#include "csapi/content-repo.h"
#include "csapi/leaving.h"
#include "csapi/typing.h"
#include "events/typingevent.h"
#include "events/reactionevent.h"
#include "powerlevels.h"

#include <QFileDialog>
#include <QMetaObject>
#include <QMimeDatabase>

#include "utils.h"

SpectralRoom::SpectralRoom(Connection* connection, QString roomId,
                           JoinState joinState)
    : Room(connection, std::move(roomId), joinState) {
  connect(this, &Room::avatarChanged, this,
          &SpectralRoom::inheritedAvatarChanged);
  // Forward base-class typing notifications to our own signal so the
  // hasUsersTyping/usersTyping Q_PROPERTY bindings update.
  connect(this, &Room::typingChanged, this, &SpectralRoom::typingChanged);
  connect(this, &SpectralRoom::notificationCountChanged, this,
          &SpectralRoom::countChanged);
  connect(this, &SpectralRoom::highlightCountChanged, this,
          &SpectralRoom::countChanged);
  connect(this, &Room::addedMessages, this, [=] { setBusy(false); });
}

void SpectralRoom::chooseAndUploadFile() {
  auto localFile = QFileDialog::getOpenFileUrl(Q_NULLPTR, tr("Save File as"));
  if (!localFile.isEmpty()) {
    UploadContentJob* job =
        connection()->uploadFile(localFile.toLocalFile(), getMIME(localFile));
    if (isJobRunning(job)) {
      setHasFileUploading(true);
      connect(job, &BaseJob::uploadProgress, this,
              [=](qint64 bytesSent, qint64 bytesTotal) {
                if (bytesTotal != 0) {
                  setFileUploadingProgress(bytesSent * 100 / bytesTotal);
                }
              });
      connect(job, &BaseJob::success, this,
              [=] { postFile(localFile, job->contentUri()); });
      connect(job, &BaseJob::finished, this, [=] {
        setHasFileUploading(false);
        setFileUploadingProgress(0);
      });
    } else {
      qDebug() << "Failed transfer.";
    }
  }
}

void SpectralRoom::postFile(const QUrl& localFile, const QUrl& mxcUrl) {
  const QString mime = getMIME(localFile);
  const QString fileName = localFile.fileName();
  QString msgType = "m.file";
  if (mime.startsWith("image")) msgType = "m.image";
  if (mime.startsWith("video")) msgType = "m.video";
  if (mime.startsWith("audio")) msgType = "m.audio";
  QJsonObject json{QJsonObject{{"msgtype", msgType},
                               {"body", fileName},
                               {"filename", fileName},
                               {"url", mxcUrl.url()}}};
  postJson("m.room.message", json);
}

QString SpectralRoom::getMIME(const QUrl& fileUrl) const {
  return QMimeDatabase().mimeTypeForFile(fileUrl.toLocalFile()).name();
}

void SpectralRoom::saveFileAs(QString eventId) {
  auto fileName = QFileDialog::getSaveFileName(Q_NULLPTR, tr("Save File as"),
                                               fileNameToDownload(eventId));
  if (!fileName.isEmpty()) downloadFile(eventId, QUrl::fromLocalFile(fileName));
}

void SpectralRoom::acceptInvitation() { connection()->joinRoom(id()); }

void SpectralRoom::forget() { connection()->forgetRoom(id()); }

bool SpectralRoom::hasUsersTyping() {
  QList<User*> users = usersTyping();
  if (users.isEmpty()) return false;
  int count = users.length();
  if (users.contains(localUser())) count--;
  return count != 0;
}

QString SpectralRoom::getUsersTyping() {
  QString usersTypingStr;
  QList<User*> users = usersTyping();
  users.removeOne(localUser());
  for (User* user : users) {
    usersTypingStr += user->displayname() + " ";
  }
  usersTypingStr += users.count() < 2 ? "is" : "are";
  usersTypingStr += " typing.";
  return usersTypingStr;
}

void SpectralRoom::sendTypingNotification(bool isTyping) {
  connection()->callApi<SetTypingJob>(BackgroundRequest, localUser()->id(),
                                      id(), isTyping, 10000);
}

QString SpectralRoom::lastEvent() {
  if (timelineSize() == 0) return "";
  // NOTE (PCP Qt, fork-only): skip edit events (mirrors
  // upstream handling) so the preview shows real messages.
  auto it = messageEvents().rbegin();
  while (it != messageEvents().rend() && utils::isEditEvent(**it)) ++it;
  if (it == messageEvents().rend()) return "";
  const RoomEvent* lastEvent = it->get();
  return user(lastEvent->senderId())->displayname() + ": " +
         utils::removeReply(utils::eventToString(
             utils::editedVersion(*lastEvent, this), this));
}

bool SpectralRoom::isEventHighlighted(const RoomEvent* e) const {
  return highlights.contains(e);
}

void SpectralRoom::checkForHighlights(const QMatrixClient::TimelineItem& ti) {
  auto localUserId = localUser()->id();
  if (ti->senderId() == localUserId) return;
  if (auto* e = ti.viewAs<RoomMessageEvent>()) {
    const auto& text = e->plainBody();
    if (text.contains(localUserId) ||
        text.contains(roomMembername(localUserId)))
      highlights.insert(e);
  }
}

void SpectralRoom::onAddNewTimelineEvents(timeline_iter_t from) {
  std::for_each(from, messageEvents().cend(),
                [this](const TimelineItem& ti) { checkForHighlights(ti); });
}

void SpectralRoom::onAddHistoricalTimelineEvents(rev_iter_t from) {
  std::for_each(from, messageEvents().crend(),
                [this](const TimelineItem& ti) { checkForHighlights(ti); });
}

void SpectralRoom::countChanged() {
  if (displayed() && !hasUnreadMessages()) {
    resetNotificationCount();
    resetHighlightCount();
  }
}

void SpectralRoom::sendReply(QString userId, QString eventId,
                             QString replyContent, QString sendContent) {
  QJsonObject json{
      {"msgtype", "m.text"},
      {"body", "> <" + userId + "> " + replyContent + "\n\n" + sendContent},
      {"format", "org.matrix.custom.html"},
      {"m.relates_to",
       QJsonObject{{"m.in_reply_to", QJsonObject{{"event_id", eventId}}}}},
      {"formatted_body",
       "<mx-reply><blockquote><a href=\"https://matrix.to/#/" + id() + "/" +
           eventId + "\">In reply to</a> <a href=\"https://matrix.to/#/" +
           userId + "\">" + userId + "</a><br>" + replyContent +
           "</blockquote></mx-reply>" + sendContent}};
  postJson("m.room.message", json);
}

QDateTime SpectralRoom::lastActiveTime() {
  if (timelineSize() == 0) return QDateTime();
  return messageEvents().rbegin()->get()->timestamp();
}

float SpectralRoom::orderForTag(QString name) {
  // NOTE (PCP Qt): TagRecord::order became Omittable<float>
  // in the Dec 2018 lib; omitted order sorts as 0.
  const auto order = tag(name).order;
  return order.omitted() ? 0.0f : order.value();
}

int SpectralRoom::savedTopVisibleIndex() const {
  return firstDisplayedMarker() == timelineEdge()
             ? 0
             : firstDisplayedMarker() - messageEvents().rbegin();
}

int SpectralRoom::savedBottomVisibleIndex() const {
  return lastDisplayedMarker() == timelineEdge()
             ? 0
             : lastDisplayedMarker() - messageEvents().rbegin();
}

void SpectralRoom::saveViewport(int topIndex, int bottomIndex) {
  if (topIndex == -1 || bottomIndex == -1 ||
      (bottomIndex == savedBottomVisibleIndex() &&
       (bottomIndex == 0 || topIndex == savedTopVisibleIndex())))
    return;
  if (bottomIndex == 0) {
    setFirstDisplayedEventId({});
    setLastDisplayedEventId({});
    return;
  }
  setFirstDisplayedEvent(maxTimelineIndex() - topIndex);
  setLastDisplayedEvent(maxTimelineIndex() - bottomIndex);
}

void SpectralRoom::getPreviousContent(int limit) {
  setBusy(true);
  Room::getPreviousContent(limit);
}

QVariantList SpectralRoom::getUsers(const QString& prefix) {
  auto userList = users();
  QVariantList matchedList;
  for (auto u : userList)
    if (u->displayname(this).toLower().startsWith(prefix.toLower()))
      matchedList.append(QVariant::fromValue(u));

  return matchedList;
}

// NOTE (PCP Qt, fork-only): backported from Jul 2019.
void SpectralRoom::toggleReaction(const QString& eventId,
                                  const QString& reaction) {
  if (eventId.isEmpty() || reaction.isEmpty())
    return;

  const auto eventIt = findInTimeline(eventId);
  if (eventIt == timelineEdge())
    return;

  const auto& evt = **eventIt;

  QStringList redactEventIds;  // What if there are multiple reaction events?

  const auto& annotations = relatedEvents(evt, EventRelation::Annotation());
  if (!annotations.isEmpty()) {
    for (const auto& a : annotations) {
      if (auto e = eventCast<const ReactionEvent>(a)) {
        if (e->relation().key != reaction)
          continue;

        if (e->senderId() == localUser()->id()) {
          redactEventIds.push_back(e->id());
          break;
        }
      }
    }
  }

  if (!redactEventIds.isEmpty()) {
    for (auto redactEventId : redactEventIds) {
      redactEvent(redactEventId);
    }
    return;
  }

  postEvent(new ReactionEvent(EventRelation::annotate(eventId, reaction)));
}

// NOTE (PCP Qt, fork-only): minimal power-level backport.
QJsonObject SpectralRoom::powerLevelsContent() const {
  const auto* plEvt =
      getStateEvent(QStringLiteral("m.room.power_levels"));
  return plEvt ? plEvt->contentJson() : QJsonObject();
}

int SpectralRoom::powerLevelForUser(const QString& userId) const {
  return powerlevels::userLevel(powerLevelsContent(), userId);
}

bool SpectralRoom::canSendEvent(const QString& eventType) const {
  const auto content = powerLevelsContent();
  return powerlevels::userLevel(content, localUser()->id()) >=
         powerlevels::requiredForEvent(content, eventType);
}

bool SpectralRoom::canSendState(const QString& eventType) const {
  const auto content = powerLevelsContent();
  return powerlevels::userLevel(content, localUser()->id()) >=
         powerlevels::requiredForState(content, eventType);
}

bool SpectralRoom::canKick(const QString& userId) const {
  const auto content = powerLevelsContent();
  const auto own = powerlevels::userLevel(content, localUser()->id());
  return own >= powerlevels::kickLevel(content) &&
         own > powerlevels::userLevel(content, userId);
}
