import 'package:intl/intl.dart';
import 'package:recon/models/records/asset_chunk.dart';

enum UploadState {
  uploadingChunks,
  finalizing,
  uploaded,
  failed,
  unknown;

  factory UploadState.fromString(String? text) {
    return UploadState.values.firstWhere(
      (element) => element.name.toLowerCase() == text?.toLowerCase(),
      orElse: () => UploadState.unknown,
    );
  }

  @override
  String toString() => toBeginningOfSentenceCase(name);
}

class AssetUploadData {
  final String hash;
  final String? variant;
  final String id;
  final String ownerId;
  final int totalBytes;
  final int chunkSize;
  final int totalChunks;
  final UploadState uploadState;
  final String uploadKey;
  final String uploadEndpoint;
  final bool isDirectUpload;
  final int maxUploadConcurrency;
  final List<AssetChunk> chunks;
  final String createdOn; // This is a string to prevent truncation of millisecond data which breaks asset upload HMAC checks

  const AssetUploadData({
    required this.hash,
    required this.variant,
    required this.id,
    required this.ownerId,
    required this.totalBytes,
    required this.chunkSize,
    required this.totalChunks,
    required this.uploadState,
    required this.uploadKey,
    required this.uploadEndpoint,
    required this.isDirectUpload,
    required this.maxUploadConcurrency,
    required this.chunks,
    required this.createdOn,
  });

  static String _fixTimeNotation(String s) {
    // the server sends the createdOn time string with trailing zeroes trimmed, but expects it back with those trimmed zeroes intact for the HMAC verification,
    // so we add back the trimmed zeroes here so the server is happy :3
    final m = RegExp(r'^(.+T\d{2}:\d{2}:\d{2})(?:\.(\d+))?(Z|[+-]\d{2}:\d{2})?$').firstMatch(s);
    if (m == null) return s;
    final frac = (m[2] ?? '').padRight(7, '0');
    return '${m[1]}.$frac${m[3] ?? ''}';
  }

  factory AssetUploadData.fromMap(Map<String, dynamic> map) => AssetUploadData(
        hash: map["hash"],
        variant: map["variant"],
        id: map["id"],
        ownerId: map["ownerId"],
        totalBytes: map["totalBytes"],
        chunkSize: map["chunkSize"],
        totalChunks: map["totalChunks"],
        uploadState: UploadState.fromString(map["uploadState"]),
        uploadKey: map["uploadKey"],
        uploadEndpoint: map["uploadEndpoint"],
        isDirectUpload: map["isDirectUpload"],
        maxUploadConcurrency: map["maxUploadConcurrency"],
        chunks: (map["chunks"] as List?)?.cast<Map<String, dynamic>>().map(AssetChunk.fromMap).toList() ?? [],
        createdOn: _fixTimeNotation(map["createdOn"]),
      );

  Map<String, dynamic> toMap() => {
        "hash": hash,
        "variant": variant,
        "id": id,
        "ownerId": ownerId,
        "totalBytes": totalBytes,
        "chunkSize": chunkSize,
        "totalChunks": totalChunks,
        "uploadState": uploadState.toString(),
        "uploadKey": uploadKey,
        "uploadEndpoint": uploadEndpoint,
        "isDirectUpload": isDirectUpload,
        "maxUploadConcurrency": maxUploadConcurrency,
        "chunks": chunks.map((e) => e.toMap()).toList(),
        "createdOn": createdOn,
      };
}
