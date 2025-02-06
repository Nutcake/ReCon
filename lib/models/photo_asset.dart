import 'dart:math';

class PhotoAsset {
  final String locationName;
  final List<String> userIds;
  final DateTime timestamp;
  final String imageUri;

  PhotoAsset({required this.locationName, required this.userIds, required this.timestamp, required this.imageUri});

  factory PhotoAsset.fromTags(List<String> tags) {
    final userIds = <String>[];
    final parsedTags = Map<String, String>.fromEntries(
      tags.map((e) {
        final delimIdx = e.indexOf(":");
        if (delimIdx == -1) return null;
        final key = e.substring(0, delimIdx);
        final value = e.substring(min(delimIdx + 1, e.length));
        if (key == "user") {
          userIds.add(value);
          return null;
        }
        return MapEntry(key, value);
      }).nonNulls,
    );
    return PhotoAsset(
      locationName: parsedTags["location_name"]!,
      userIds: userIds,
      timestamp: DateTime.parse(parsedTags["timestamp"]!),
      imageUri: parsedTags["texture_asset"]!,
    );
  }
}
