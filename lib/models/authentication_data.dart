class AuthenticationData {
  static const _unauthenticated = AuthenticationData(userId: "", token: "", secretMachineId: "", isAuthenticated: false);
  final String userId;
  final String token;
  final String secretMachineId;
  final bool isAuthenticated;

  const AuthenticationData({
    required this.userId, required this.token, required this.secretMachineId, required this.isAuthenticated
  });
  
  factory AuthenticationData.fromJson(Map json) {
    final userId = json["userId"];
    final token = json["token"];
    final machineId = json["secretMachineId"];
    if (userId == null || token == null || machineId == null) {
      return _unauthenticated;
    }
    return AuthenticationData(userId: userId, token: token, secretMachineId: machineId, isAuthenticated: true);
  }

  factory AuthenticationData.unauthenticated() => _unauthenticated;
}