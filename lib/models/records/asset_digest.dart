import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:recon/models/records/resonite_db_asset.dart';

class AssetDigest {
  final Uint8List data;
  final ResoniteDBAsset asset;
  final String name;
  final String dbUri;

  AssetDigest({required this.data, required this.asset, required this.name, required this.dbUri});

  static Future<AssetDigest> fromData(Uint8List data, String filename) async {
    final asset = ResoniteDBAsset.fromData(data);

    return AssetDigest(
      data: data,
      asset: asset,
      name: basenameWithoutExtension(filename),
      dbUri: "resdb:///${asset.hash}${extension(filename)}",
    );
  }
}
