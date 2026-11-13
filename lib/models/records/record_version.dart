class RecordVersion {
  final int globalVersion;
  final int localVersion;
  final String? lastModifyingUserId;
  final String? lastModifyingMachineId;

  const RecordVersion({
    required this.globalVersion,
    required this.localVersion,
    required this.lastModifyingUserId,
    required this.lastModifyingMachineId,
  });

  factory RecordVersion.fromMap(Map<String, dynamic> map) => RecordVersion(
        globalVersion: map['globalVersion'],
        localVersion: map['localVersion'],
        lastModifyingUserId: map['lastModifyingUserId'],
        lastModifyingMachineId: map['lastModifyingMachineId'],
      );

  Map<String, dynamic> toMap() => {
    "globalVersion": globalVersion,
    "localVersion": localVersion,
    "lastModifyingUserId": lastModifyingUserId,
    "lastModifyingMachineId": lastModifyingMachineId,
  };
}
