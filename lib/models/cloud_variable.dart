import 'package:recon/auxiliary.dart';

class CloudVariable {
  final String ownerId;
  final String path;
  final String value;
  final String partitionKey;
  final String rowKey;
  final DateTime timestamp;
  final String eTag;

  const CloudVariable({
    required this.ownerId,
    required this.path,
    required this.value,
    required this.partitionKey,
    required this.rowKey,
    required this.timestamp,
    required this.eTag,
  });

  factory CloudVariable.fromMap(Map map) {
    return CloudVariable(
      ownerId: map["ownerId"],
      path: map["path"],
      value: map["value"],
      partitionKey: map["partitionKey"],
      rowKey: map["rowKey"],
      timestamp: DateTime.tryParse(map["timestamp"]) ?? DateTimeX.epoch,
      eTag: map["eTag"],
    );
  }
}
