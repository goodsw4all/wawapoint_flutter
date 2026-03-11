import 'dart:io';
import 'package:flutter/foundation.dart';
import '../data/backup_manager.dart';
import '../data/record_database.dart';
import 'point_view_model.dart';

class BackupViewModel extends ChangeNotifier {
  final PointViewModel _pointViewModel;

  BackupViewModel(this._pointViewModel);

  Future<File> exportBackup() async {
    final records = _pointViewModel.records;
    final json = BackupManager().exportToJson(records);
    final fileName = BackupManager().generateFileName();
    return BackupManager().saveToDocuments(json, fileName);
  }

  Future<int> importBackup(String jsonString) async {
    final imported = BackupManager().importFromJson(jsonString);

    // persist to sqlite
    final db = RecordDatabase.instance;
    await db.clearAll();
    for (final r in imported) {
      await db.insertRecord(r);
    }

    // reload PointViewModel from DB
    await _pointViewModel.loadRecords();
    return imported.length;
  }

  Future<void> clearAllData() async {
    await RecordDatabase.instance.clearAll();
    await _pointViewModel.loadRecords();
  }
}
