
import 'dart:math';

import 'package:collection/collection.dart';

class PhotoAsset {
  final String locationName;
  final List<String> userIds;
  final DateTime timestamp;
  final String imageUri;

  PhotoAsset({required this.locationName, required this.userIds, required this.timestamp, required this.imageUri});

  factory PhotoAsset.fromTags(List<String> tags) {
    final List<String> userIds = [];
    Map<String, String> parsedTags = Map.fromEntries(tags.map((e) {
      final delimIdx = e.indexOf(":");
      if (delimIdx == -1) return null;
      final key = e.substring(0, delimIdx);
      final value = e.substring(min(delimIdx+1, e.length));
      if (key == "user") {
        userIds.add(value);
        return null;
      }
      return MapEntry(key, value);
    }).whereNotNull());
    return PhotoAsset(
      locationName: parsedTags["location_name"]!,
      userIds: userIds,
      timestamp: DateTime.parse(parsedTags["timestamp"]!),
      imageUri: parsedTags["texture_asset"]!,
    );
  }
}