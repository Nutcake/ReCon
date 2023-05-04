class AuthenticationData {
  static const _unauthenticated = AuthenticationData(userId: "", token: "", secretMachineId: "", isAuthenticated: false);
  final String userId;
  final String token;
  final String secretMachineId;
  final bool isAuthenticated;

  const AuthenticationData({
    required this.userId, required this.token, required this.secretMachineId, required this.isAuthenticated
  });
  
  factory AuthenticationData.fromMap(Map map) {
    final userId = map["userId"];
    final token = map["token"];
    final machineId = map["secretMachineId"];
    if (userId == null || token == null || machineId == null) {
      return _unauthenticated;
    }
    return AuthenticationData(userId: userId, token: token, secretMachineId: machineId, isAuthenticated: true);
  }

  factory AuthenticationData.unauthenticated() => _unauthenticated;

  Map<String, String> get authorizationHeader => {
    "Authorization": "neos $userId:$token"
  };

  Map<String, dynamic> toMap() {
    return {
      "userId": userId,
      "token": token,
      "secretMachineId": secretMachineId,
    };
  }
}