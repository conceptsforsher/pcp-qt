#ifndef Utils_H
#define Utils_H

#include "room.h"

#include <QObject>
#include <QRegExp>
#include <QString>

#include <events/redactionevent.h>
#include <events/roomavatarevent.h>
#include <events/roomcreateevent.h>
#include <events/roommemberevent.h>
#include <events/simplestateevents.h>
#include <events/stateevent.h>

namespace utils {
const QRegExp removeReplyRegex{"> <.*>.*\\n\\n"};

QString removeReply(const QString& text);

// NOTE (PCP Qt, fork-only): message edits (m.replace).
// True if the event itself is an edit of another event.
inline bool isEditEvent(const QMatrixClient::RoomEvent& evt) {
  const auto relates = evt.fullJson()
                           .value(QStringLiteral("content"))
                           .toObject()
                           .value(QStringLiteral("m.relates_to"))
                           .toObject();
  return relates.value(QStringLiteral("rel_type")).toString() ==
         QStringLiteral("m.replace");
}

// If the event was edited, return the latest replacement; else the event.
inline const QMatrixClient::RoomEvent& editedVersion(
    const QMatrixClient::RoomEvent& evt, QMatrixClient::Room* room) {
  if (!room) return evt;
  const auto& replacements = room->relatedEvents(evt.id(), "m.replace");
  if (replacements.isEmpty()) return evt;
  return *replacements.back();
}

template <typename BaseEventT>
QString eventToString(const BaseEventT& evt,
                      QMatrixClient::Room* room = nullptr,
                      Qt::TextFormat format = Qt::PlainText) {
  bool prettyPrint = (format == Qt::RichText);

  using namespace QMatrixClient;
  return visit(
      evt,
      [room, prettyPrint](const RoomMessageEvent& e) {
        using namespace MessageEventContent;

        if (prettyPrint && e.hasTextContent() &&
            e.mimeType().name() != "text/plain") {
          static const QRegExp userPillRegExp(
              "<a href=\"https://matrix.to/#/@.*:.*\">(.*)</a>");
          QString formattedStr(
              static_cast<const TextContent*>(e.content())->body);
          formattedStr.replace(userPillRegExp,
                               "<b class=\"user-pill\">\\1</b>");
          return formattedStr;
        }
        if (e.hasFileContent()) {
          auto fileCaption = e.content()->fileInfo()->originalName;
          if (fileCaption.isEmpty())
            fileCaption = prettyPrint && room ? room->prettyPrint(e.plainBody())
                                              : e.plainBody();
          if (fileCaption.isEmpty()) return QObject::tr("a file");
        }
        return prettyPrint && room ? room->prettyPrint(e.plainBody())
                                   : e.plainBody();
      },
      [room](const RoomMemberEvent& e) {
        // FIXME: Rewind to the name that was at the time of this event
        QString subjectName =
            room ? room->roomMembername(e.userId()) : e.userId();
        // The below code assumes senderName output in AuthorRole
        switch (e.membership()) {
          case MembershipType::Invite:
            if (e.repeatsState())
              return QObject::tr("reinvited %1 to the room").arg(subjectName);
            FALLTHROUGH;
          case MembershipType::Join: {
            if (e.repeatsState())
              return QObject::tr("joined the room (repeated)");
            if (!e.prevContent() ||
                e.membership() != e.prevContent()->membership) {
              return e.membership() == MembershipType::Invite
                         ? QObject::tr("invited %1 to the room")
                               .arg(subjectName)
                         : QObject::tr("joined the room");
            }
            QString text{};
            if (e.isRename()) {
              if (e.displayName().isEmpty())
                text = QObject::tr("cleared their display name");
              else
                text = QObject::tr("changed their display name to %1")
                           .arg(e.displayName());
            }
            if (e.isAvatarUpdate()) {
              if (!text.isEmpty()) text += " and ";
              if (e.avatarUrl().isEmpty())
                text += QObject::tr("cleared the avatar");
              else
                text += QObject::tr("updated the avatar");
            }
            return text;
          }
          case MembershipType::Leave:
            if (e.prevContent() &&
                e.prevContent()->membership == MembershipType::Ban) {
              return (e.senderId() != e.userId())
                         ? QObject::tr("unbanned %1").arg(subjectName)
                         : QObject::tr("self-unbanned");
            }
            return (e.senderId() != e.userId())
                       ? QObject::tr("has kicked %1 from the room")
                             .arg(subjectName)
                       : QObject::tr("left the room");
          case MembershipType::Ban:
            return (e.senderId() != e.userId())
                       ? QObject::tr("banned %1 from the room ")
                             .arg(subjectName)
                       : QObject::tr(" self-banned from the room ");
          case MembershipType::Knock:
            return QObject::tr("knocked");
          default:;
        }
        return QObject::tr("made something unknown");
      },
      [](const RoomAliasesEvent& e) {
        return QObject::tr("set aliases to: %1").arg(e.aliases().join(","));
      },
      [](const RoomCanonicalAliasEvent& e) {
        return (e.alias().isEmpty())
                   ? QObject::tr("cleared the room main alias")
                   : QObject::tr("set the room main alias to: %1")
                         .arg(e.alias());
      },
      [](const RoomNameEvent& e) {
        return (e.name().isEmpty())
                   ? QObject::tr("cleared the room name")
                   : QObject::tr("set the room name to: %1").arg(e.name());
      },
      [](const RoomTopicEvent& e) {
        return (e.topic().isEmpty())
                   ? QObject::tr("cleared the topic")
                   : QObject::tr("set the topic to: %1").arg(e.topic());
      },
      [](const RoomAvatarEvent&) {
        return QObject::tr("changed the room avatar");
      },
      [](const EncryptionEvent&) {
        return QObject::tr("activated End-to-End Encryption");
      },
      // FORK-ONLY: the state events a room is *created* with. libQMatrixClient
      // 2019 has no typed class for any of them (only RoomCreateEvent among the
      // five), so they reached the trailing fallback and every one rendered as a
      // grey "Unknown Event" bubble at the top of every new room - five of them
      // in a Synapse-created room. They are administrative: no user wants to see
      // them in a timeline, and the delegate now hides them outright (see
      // MessageDelegate's hiddenStateRow). These strings are the safety net for
      // anything that still reaches here, so an unrecognised event reads as what
      // it is rather than as "Unknown Event".
      [](const RoomCreateEvent&) {
        return QObject::tr("created the room");
      },
      [](const StateEventBase&) {
        return QObject::tr("changed the room's settings");
      },
      QObject::tr("Unknown Event"));
};
}  // namespace utils

#endif
