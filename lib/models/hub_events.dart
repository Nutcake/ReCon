enum EventType {
  undefined,
  invocation,
  streamItem,
  completion,
  streamInvocation,
  cancelInvocation,
  ping,
  close;
}

enum EventTarget {
  unknown,
  debug,
  messageSent,
  receiveMessage,
  messagesRead,
  receiveSessionUpdate,
  removeSession,
  sendStatusToUser,
  receiveStatusUpdate;

  factory EventTarget.parse(String? text) {
    if (text == null) return EventTarget.unknown;
    return EventTarget.values.firstWhere(
          (element) => element.name.toLowerCase() == text.toLowerCase(),
      orElse: () => EventTarget.unknown,
    );
  }
}