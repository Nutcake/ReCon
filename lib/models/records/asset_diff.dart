
import 'package:contacts_plus_plus/models/records/resonite_db_asset.dart';

class AssetDiff extends ResoniteDBAsset{
  final Diff state;
  final bool isUploaded;

  const AssetDiff({required hash, required bytes, required this.state, required this.isUploaded}) : super(hash: hash, bytes: bytes);

  factory AssetDiff.fromMap(Map map) {
    return AssetDiff(
      hash: map["hash"],
      bytes: map["bytes"],
      state: Diff.fromInt(map["state"]),
      isUploaded: map["isUploaded"],
    );
  }
}

enum Diff {
  added,
  unchanged,
  removed;

  factory Diff.fromInt(int? idx) {
    return Diff.values[idx ?? 1];
  }

  factory Diff.fromString(String? text) {
    return Diff.values.firstWhere((element) => element.name.toLowerCase() == text?.toLowerCase(),
      orElse: () => Diff.unchanged,
    );
  }
}