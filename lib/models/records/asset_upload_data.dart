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
  String toString() => toBeginningOfSentenceCase(super.toString());
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
  final DateTime createdOn;

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
        createdOn: DateTime.parse(map["createdOn"]).toUtc(),
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
        "chunks": chunks.map(
          (e) => e.toMap(),
        ),
        "createdOn": createdOn,
      };
}
