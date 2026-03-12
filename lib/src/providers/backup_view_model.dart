import 'dart:io';
import 'package:flutter/foundation.dart';
import '../data/backup_manager.dart';
import '../data/record_database.dart';
import 'point_view_model.dart';

/// 백업 및 데이터 초기화를 담당하는 ViewModel
class BackupViewModel extends ChangeNotifier {
  final PointViewModel _pointViewModel;

  BackupViewModel(this._pointViewModel);

  /// 현재 메모리에 로드된 전체 기록을 JSON 형식으로 내보냅니다.
  Future<File> exportBackup() async {
    final records = _pointViewModel.records;
    final json = BackupManager().exportToJson(records);
    final fileName = BackupManager().generateFileName();
    return BackupManager().saveToDocuments(json, fileName);
  }

  /// 전달받은 JSON 문자열을 파싱하여 기존 DB를 덮어씁니다.
  Future<int> importBackup(String jsonString) async {
    final imported = BackupManager().importFromJson(jsonString);

    // DB를 초기화하고 파싱된 데이터를 저장합니다.
    final db = RecordDatabase.instance;
    await db.clearAll();
    for (final r in imported) {
      await db.insertRecord(r);
    }

    // 원본 PointViewModel을 DB로부터 다시 로딩하여 메모리 동기화
    await _pointViewModel.loadRecords();
    return imported.length;
  }

  /// 로컬 DB의 모든 거래 내역을 지웁니다.
  Future<void> clearAllData() async {
    await RecordDatabase.instance.clearAll();
    await _pointViewModel.loadRecords();
  }
}
