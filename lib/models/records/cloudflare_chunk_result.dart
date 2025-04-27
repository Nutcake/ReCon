class CloudflareChunkResult {
  final String eTag;
  final String checksumCRC32;

  const CloudflareChunkResult({required this.eTag, required this.checksumCRC32});

  factory CloudflareChunkResult.fromMap(Map<String, dynamic> map) => CloudflareChunkResult(
        eTag: map["ETag"],
        checksumCRC32: map["ChecksumCRC32"],
      );
}
