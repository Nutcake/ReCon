import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class AssetManifest {
  final String hash;
  final int bytes;

  const AssetManifest({required this.hash, required this.bytes});

  factory AssetManifest.fromMap(Map map) {
    return AssetManifest(hash: map["hash"] ?? "", bytes: map["bytes"] ?? -1);
  }

  factory AssetManifest.fromData(Uint8List data) {
    final digest = sha256.convert(data);
    return AssetManifest(hash: digest.toString().replaceAll("-", "").toLowerCase(), bytes: data.length);
  }

  Map toMap() {
    return {
      "hash": hash,
      "bytes": bytes,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AssetManifest && runtimeType == other.runtimeType && hash == other.hash;

  @override
  int get hashCode => hash.hashCode;
}
