import 'package:contacts_plus_plus/models/session.dart';
import 'package:intl/intl.dart';

class SessionMetadata {
  final String sessionHash;
  final SessionAccessLevel accessLevel;
  final bool sessionHidden;
  final bool? isHost;
  final String? broadcastKey;

  SessionMetadata({
    required this.sessionHash,
    required this.accessLevel,
    required this.sessionHidden,
    required this.isHost,
    required this.broadcastKey,
  });

  factory SessionMetadata.fromMap(Map map) {
    return SessionMetadata(
      sessionHash: map["sessionHash"],
      accessLevel: SessionAccessLevel.fromName(map["accessLevel"]),
      sessionHidden: map["sessionHidden"],
      isHost: map["ishost"],
      broadcastKey: map["broadcastKey"],
    );
  }

  Map toMap() {
    return {
      "sessionHash": sessionHash,
      "accessLevel": toBeginningOfSentenceCase(accessLevel.name),
      "sessionHidden": sessionHidden,
      "isHost": isHost,
      "broadcastKey": broadcastKey,
    };
  }
}
