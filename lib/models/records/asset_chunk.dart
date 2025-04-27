class AssetChunk {
  final int index;
  final String key;

  const AssetChunk({required this.index, required this.key});

  factory AssetChunk.fromMap(Map<String, dynamic> map) => AssetChunk(index: map["index"], key: map["key"]);

  Map<String, dynamic> toMap() => {
    "index": index,
    "key": key,
  };
}
