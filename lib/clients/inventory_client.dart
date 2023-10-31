import 'dart:async';

import 'package:flutter/material.dart';
import 'package:recon/apis/record_api.dart';
import 'package:recon/clients/api_client.dart';
import 'package:recon/models/inventory/resonite_directory.dart';
import 'package:recon/models/records/record.dart';

enum SortMode {
  name,
  date;

  int sortFunction(Record a, Record b, {bool reverse = false}) {
    final func = switch (this) {
      SortMode.name => (Record x, Record y) =>
          x.formattedName.toString().toLowerCase().compareTo(y.formattedName.toString().toLowerCase()),
      SortMode.date => (Record x, Record y) => x.creationTime.compareTo(y.creationTime),
    };
    if (reverse) {
      return func(b, a);
    }
    return func(a, b);
  }

  static const Map<SortMode, IconData> _iconsMap = {
    SortMode.name: Icons.sort_by_alpha,
    SortMode.date: Icons.access_time_outlined
  };

  IconData get icon => _iconsMap[this] ?? Icons.question_mark;
}

class InventoryClient extends ChangeNotifier {
  final ApiClient apiClient;
  final Map<String, Record> _selectedRecords = {};

  Future<ResoniteDirectory>? _currentDirectory;
  SortMode _sortMode = SortMode.name;
  bool _sortReverse = false;

  InventoryClient({required this.apiClient});

  SortMode get sortMode => _sortMode;

  bool get sortReverse => _sortReverse;

  set sortMode(SortMode mode) {
    if (_sortMode != mode) {
      _sortMode = mode;
      notifyListeners();
    }
  }

  set sortReverse(bool reverse) {
    if (_sortReverse != reverse) {
      _sortReverse = reverse;
      notifyListeners();
    }
  }

  List<Record> get selectedRecords => _selectedRecords.values.toList();

  Future<ResoniteDirectory>? get directoryFuture => _currentDirectory?.then(
        (ResoniteDirectory value) {
          value.children.sort(
            (ResoniteDirectory a, ResoniteDirectory b) => _sortMode.sortFunction(a.record, b.record, reverse: _sortReverse),
          );
          return value;
        },
      );

  bool get isAnyRecordSelected => _selectedRecords.isNotEmpty;

  bool isRecordSelected(Record record) => _selectedRecords.containsKey(record.id);

  int get selectedRecordCount => _selectedRecords.length;

  bool get onlyFilesSelected => _selectedRecords.values
      .every((element) => element.recordType != RecordType.link && element.recordType != RecordType.directory);

  void clearSelectedRecords() {
    _selectedRecords.clear();
    notifyListeners();
  }

  Future<void> deleteSelectedRecords() async {
    for (final recordId in _selectedRecords.keys) {
      await RecordApi.deleteRecord(apiClient, recordId: recordId);
    }
    _selectedRecords.clear();
    reloadCurrentDirectory();
  }

  void toggleRecordSelected(Record record) {
    if (_selectedRecords.containsKey(record.id)) {
      _selectedRecords.remove(record.id);
    } else {
      _selectedRecords[record.id] = record;
    }
    notifyListeners();
  }

  Future<List<Record>> _getDirectory(Record record) async {
    ResoniteDirectory? dir;
    try {
      dir = await _currentDirectory;
    } catch (_) {}
    final List<Record> records;
    if (dir == null || record.isRoot) {
      records = await RecordApi.getUserRecordsAt(
        apiClient,
        path: ResoniteDirectory.rootName,
      );
    } else {
      if (record.recordType == RecordType.link) {
        final linkRecord =
            await RecordApi.getUserRecord(apiClient, recordId: record.linkRecordId, user: record.linkOwnerId);
        records = await RecordApi.getUserRecordsAt(apiClient,
            path: "${linkRecord.path}\\${linkRecord.name}", user: linkRecord.ownerId);
      } else {
        records =
            await RecordApi.getUserRecordsAt(apiClient, path: "${record.path}\\${record.name}", user: record.ownerId);
      }
    }
    return records;
  }

  void loadInventoryRoot() {
    final rootRecord = Record.inventoryRoot();
    final rootFuture = _getDirectory(rootRecord).then(
      (records) {
        final rootDir = ResoniteDirectory(
          record: rootRecord,
          children: [],
        );
        rootDir.children.addAll(
          records.map((e) => ResoniteDirectory.fromRecord(record: e, parent: rootDir)).toList(),
        );
        return rootDir;
      },
    );
    _currentDirectory = rootFuture;
  }

  void forceNotify() => notifyListeners();

  Future<void> reloadCurrentDirectory() async {
    final dir = await _currentDirectory;

    if (dir == null) {
      throw "Failed to reload: No directory loaded.";
    }

    _currentDirectory = _getDirectory(dir.record).then(
      (records) {
        final children = records.map((record) => ResoniteDirectory.fromRecord(record: record, parent: dir)).toList();
        final newDir = ResoniteDirectory(record: dir.record, children: children, parent: dir.parent);

        final parentIdx = dir.parent?.children.indexOf(dir) ?? -1;
        if (parentIdx != -1) {
          dir.parent?.children[parentIdx] = newDir;
        }
        return newDir;
      },
    ).onError((error, stackTrace) {
      return dir;
    });
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

    Object? caughtError;

    if (childDir.isLoaded) {
      _currentDirectory = Future.value(childDir);
    } else {
      _currentDirectory = _getDirectory(record).then(
        (records) {
          childDir.children.clear();
          childDir.children
              .addAll(records.map((record) => ResoniteDirectory.fromRecord(record: record, parent: childDir)));
          return childDir;
        },
      ).onError((error, stackTrace) {
        caughtError = error;
        return dir;
      });
    }
    notifyListeners();
    await _currentDirectory;
    // Dirty hack to throw the error here instead of letting the FutureBuilder handle it. This means we can keep showing
    // the previous directory while also being able to display the error as a snackbar.
    if (caughtError != null) {
      throw caughtError!;
    }
  }

  Future<void> navigateUp({int times = 1}) async {
    if (times == 0) return;

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
