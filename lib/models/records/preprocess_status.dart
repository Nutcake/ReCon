import 'package:recon/models/records/asset_diff.dart';

enum RecordPreprocessState {
  preprocessing,
  success,
  failed;

  factory RecordPreprocessState.fromString(String? text) {
    return RecordPreprocessState.values.firstWhere(
      (element) => element.name.toLowerCase() == text?.toLowerCase(),
      orElse: () => RecordPreprocessState.failed,
    );
  }
}

class PreprocessStatus {
  final String id;
  final String ownerId;
  final String recordId;
  final RecordPreprocessState state;
  final double progress;
  final String? failReason;
  final List<AssetDiff> resultDiffs;
  final int attempts;
  final int ttl;

  const PreprocessStatus({
    required this.id,
    required this.ownerId,
    required this.recordId,
    required this.state,
    required this.progress,
    required this.failReason,
    required this.resultDiffs,
    required this.attempts,
    required this.ttl,
  });

  factory PreprocessStatus.fromMap(Map map) {
    return PreprocessStatus(
      id: map["id"],
      ownerId: map["ownerId"],
      recordId: map["recordId"],
      state: RecordPreprocessState.fromString(map["state"]),
      progress: (map["progress"] as num).toDouble(),
      failReason: map["failReason"],
      resultDiffs: (map["resultDiffs"] as List? ?? []).map((e) => AssetDiff.fromMap(e)).toList(),
      attempts: map["attempts"],
      ttl: map["ttl"],
    );
  }
}
