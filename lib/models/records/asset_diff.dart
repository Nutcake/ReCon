import 'package:recon/models/records/asset_manifest.dart';

class AssetDiff extends AssetManifest {
  final Diff state;
  final bool? isUploaded;

  const AssetDiff({required super.hash, required super.bytes, required this.state, required this.isUploaded});

  factory AssetDiff.fromMap(Map map) {
    return AssetDiff(
      hash: map["hash"],
      bytes: map["bytes"],
      state: Diff.fromInt(map["state"]),
      isUploaded: map["isUploaded"],
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || super == other;

  @override
  int get hashCode => hash.hashCode;
}

enum Diff {
  added,
  unchanged,
  removed;

  factory Diff.fromInt(int? idx) {
    return Diff.values[idx ?? 1];
  }

  factory Diff.fromString(String? text) {
    return Diff.values.firstWhere(
      (element) => element.name.toLowerCase() == text?.toLowerCase(),
      orElse: () => Diff.unchanged,
    );
  }
}
