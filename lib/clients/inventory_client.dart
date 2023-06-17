import 'package:contacts_plus_plus/apis/record_api.dart';
import 'package:contacts_plus_plus/clients/api_client.dart';
import 'package:contacts_plus_plus/models/inventory/neos_path.dart';
import 'package:contacts_plus_plus/models/records/record.dart';
import 'package:flutter/material.dart';

class InventoryClient extends ChangeNotifier {
  final ApiClient apiClient;

  Future<NeosDirectory>? _currentDirectory;

  Future<NeosDirectory>? get directoryFuture => _currentDirectory;

  InventoryClient({required this.apiClient});

  Future<List<Record>> _getDirectory(Record record) async {
    NeosDirectory? dir;
    try {
      dir = await _currentDirectory;
    } catch(_) {}
    final List<Record> records;
    if (dir == null || record.isRoot) {
      records = await RecordApi.getUserRecordsAt(
        apiClient,
        path: NeosDirectory.rootName,
      );
    } else {
      if (record.recordType == RecordType.link) {
        final linkRecord = await RecordApi.getUserRecord(apiClient, recordId: record.linkRecordId, user: record.linkOwnerId);
        records = await RecordApi.getUserRecordsAt(apiClient, path: "${linkRecord.path}\\${record.name}", user: linkRecord.ownerId);
      } else {
        records = await RecordApi.getUserRecordsAt(
          apiClient,
          path: "${record.path}\\${record.name}",
          user: record.ownerId
        );
      }
    }
    return records;
  }

  void loadInventoryRoot() {
    final rootRecord = Record.inventoryRoot();
    final rootFuture = _getDirectory(rootRecord).then(
      (records) {
        final rootDir = NeosDirectory(
          record: rootRecord,
          children: [],
        );
        rootDir.children.addAll(
          records.map((e) => NeosDirectory.fromRecord(record: e, parent: rootDir)).toList(),
        );
        return rootDir;
      },
    );
    _currentDirectory = rootFuture;
    notifyListeners();
  }

  Future<void> navigateTo(Record record) async {
    final dir = await _currentDirectory;

    if (dir == null) {
      throw "Failed to open: No directory loaded.";
    }

    if (record.recordType != RecordType.directory && record.recordType != RecordType.link) {
      throw "Failed to open: Record is not a directory.";
    }

    final childDir = dir.findChildByRecord(record);
    if (childDir == null) {
      throw "Failed to open: Record is not a child of current directory.";
    }

    if (childDir.isLoaded) {
      _currentDirectory = Future.value(childDir);
    } else {
      _currentDirectory = _getDirectory(record).then(
        (records) {
          childDir.children.clear();
          childDir.children.addAll(records.map((record) => NeosDirectory.fromRecord(record: record, parent: childDir)));
          return childDir;
        },
      );
    }
    notifyListeners();
  }

  Future<void> navigateUp({int times = 1}) async {
    var dir = await _currentDirectory;
    if (dir == null) {
      throw "Failed to navigate up: No directory loaded.";
    }
    if (dir.record.isRoot) {
      throw "Failed navigate up: Already at root";
    }

    for (int i = 0; i < times; i++) {
      dir = dir?.parent;
    }

    _currentDirectory = Future.value(dir);
    notifyListeners();
  }
}
