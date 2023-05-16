
enum UploadState {
  uploadingChunks,
  finalizing,
  uploaded,
  failed,
  unknown;

  factory UploadState.fromString(String? text) {
    return UploadState.values.firstWhere((element) => element.name.toLowerCase() == text?.toLowerCase(),
      orElse: () => UploadState.unknown,
    );
  }
}

class AssetUploadData {
  final String signature;
  final String variant;
  final String ownerId;
  final int totalBytes;
  final int chunkSize;
  final int totalChunks;
  final UploadState uploadState;

  const AssetUploadData({
      required this.signature,
      required this.variant,
      required this.ownerId,
      required this.totalBytes,
      required this.chunkSize,
      required this.totalChunks,
      required this.uploadState,
  });

  factory AssetUploadData.fromMap(Map map) {
    return AssetUploadData(
      signature: map["signature"],
      variant: map["variant"] ?? "",
      ownerId: map["ownerId"] ?? "",
      totalBytes: map["totalBytes"] ?? -1,
      chunkSize: map["chunkSize"] ?? -1,
      totalChunks: map["totalChunks"] ?? -1,
      uploadState: UploadState.fromString(map["uploadStat"]),
    );
  }
}