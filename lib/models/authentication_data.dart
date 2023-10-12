class AuthenticationData {
  static const _unauthenticated = AuthenticationData(
    userId: "",
    token: "",
    secretMachineIdHash: "",
    isAuthenticated: false,
    uid: "",
  );
  final String userId;
  final String token;
  final String secretMachineIdHash;
  final bool isAuthenticated;
  final String uid;

  const AuthenticationData({
    required this.userId,
    required this.token,
    required this.secretMachineIdHash,
    required this.isAuthenticated,
    required this.uid,
  });

  factory AuthenticationData.fromMap(Map map) {
    map = map["entity"];
    final userId = map["userId"];
    final token = map["token"];
    final machineId = map["secretMachineIdHash"];
    final uid = map["uid"];
    if (userId == null || token == null || machineId == null || uid == null) {
      return _unauthenticated;
    }
    return AuthenticationData(userId: userId, token: token, secretMachineIdHash: machineId, isAuthenticated: true, uid: uid);
  }

  factory AuthenticationData.unauthenticated() => _unauthenticated;

  Map<String, String> get authorizationHeader => {
        "Authorization": "res $userId:$token",
      };

  Map<String, dynamic> toMap() {
    return {
      "userId": userId,
      "token": token,
      "secretMachineId": secretMachineIdHash,
      "uid": uid,
    };
  }
}
