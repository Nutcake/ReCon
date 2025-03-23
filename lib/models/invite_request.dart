import 'package:recon/models/session.dart';

class InviteRequest {
  final String inviteRequestId;
  final String userIdToInvite;
  final String usernameToInvite;
  final String requestingFromUserId;
  final String requestingFromUsername;
  final String? forSessionId;
  final String? forSessionName;
  final bool? isContactOfHost;
  final String? response;
  final Session? invite;

  InviteRequest({
    required this.inviteRequestId,
    required this.userIdToInvite,
    required this.usernameToInvite,
    required this.requestingFromUserId,
    required this.requestingFromUsername,
    required this.forSessionId,
    required this.forSessionName,
    required this.isContactOfHost,
    required this.response,
    required this.invite,
    
  });

  factory InviteRequest.none() {
    return InviteRequest(
      inviteRequestId: "",
      userIdToInvite: "",
      usernameToInvite: "",
      requestingFromUserId: "",
      requestingFromUsername: "",
      forSessionId: null,
      forSessionName: null,
      isContactOfHost: null,
      response: null,
      invite: null,
    );
  }

  factory InviteRequest.fromMap(Map? map) {
    if (map == null) return InviteRequest.none();
    return InviteRequest(
      inviteRequestId: map["inviteRequestId"],
      userIdToInvite: map["userIdToInvite"],
      usernameToInvite: map["usernameToInvite"],
      requestingFromUserId: map["requestingFromUserId"],
      requestingFromUsername: map["requestingFromUsername"],
      forSessionId: map["forSessionId"],
      forSessionName: map["forSessionName"],
      isContactOfHost: map["isContactOfHost"],
      response: map["response"],
      invite: Session.fromMap(map["invite"]),
    );
  }

  Map toMap({bool shallow = false}) {
    return {
      "inviteRequestId": inviteRequestId,
      "userIdToInvite": userIdToInvite,
      "usernameToInvite": usernameToInvite,
      "requestingFromUserId": requestingFromUserId,
      "requestingFromUsername": requestingFromUsername,
      "forSessionId": forSessionId,
      "forSessionName": forSessionName,
      "isContactOfHost": isContactOfHost,
      "response": response,
      "invite": invite,
    };
  }

  InviteRequest copyWith({
    String? inviteRequestId,
    String? userIdToInvite,
    String? usernameToInvite,
    String? requestingFromUserId,
    String? requestingFromUsername,
    String? forSessionId,
    String? forSessionName,
    bool? isContactOfHost,
    String? response,
    Session? invite,
  }) {
    return InviteRequest(
      inviteRequestId: inviteRequestId ?? this.inviteRequestId,
      userIdToInvite: userIdToInvite ?? this.userIdToInvite,
      usernameToInvite: usernameToInvite ?? this.usernameToInvite,
      requestingFromUserId: requestingFromUserId ?? this.requestingFromUserId,
      requestingFromUsername: requestingFromUsername ?? this.requestingFromUsername,
      forSessionId: forSessionId ?? this.forSessionId,
      forSessionName: forSessionName ?? this.forSessionName,
      isContactOfHost: isContactOfHost ?? this.isContactOfHost,
      response: response ?? this.response,
      invite: invite ?? this.invite,
    );
  }
}
