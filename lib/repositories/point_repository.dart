import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/point_record.dart';
import '../utils/record_database.dart';

/// [PointRecord] 데이터의 영속성을 관리하는 Repository 클래스입니다.
/// SQLite 데이터베이스와 레거시 JSON 파일 시스템과의 상호작용을 캡슐화합니다.
class PointRepository {
  final RecordDatabase _db = RecordDatabase.instance;

  /// 레거시 JSON 데이터 파일 경로를 가져옵니다.
  Future<File> _getLegacyDataFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/wawapoint_records.json');
  }

  /// 모든 기록을 비동기적으로 로드합니다.
  /// 우선 SQLite에서 데이터를 시도하고, 없으면 레거시 JSON 파일에서 마이그레이션합니다.
  Future<List<PointRecord>> getAllRecords() async {
    try {
      final dbRecords = await _db.getAllRecords();
      if (dbRecords.isNotEmpty) {
        return dbRecords;
      }
    } catch (e) {
      // DB 로드 실패 시 로그 등을 남길 수 있습니다.
    }

    // DB가 비어있을 경우 레거시 파일 마이그레이션 시도
    return await _migrateFromLegacy();
  }

  /// 레거시 JSON 파일로부터 데이터를 마이그레이션합니다.
  Future<List<PointRecord>> _migrateFromLegacy() async {
    try {
      final file = await _getLegacyDataFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> list = jsonDecode(content) as List<dynamic>;
        final migrated = list
            .map((e) => PointRecord.fromJson(e as Map<String, dynamic>))
            .toList();

        // SQLite에 데이터 저장
        await _db.clearAll();
        for (final r in migrated) {
          await _db.insertRecord(r);
        }

        // 마이그레이션 완료 후 레거시 파일 삭제
        await file.delete();
        return migrated;
      }
    } catch (e) {
      // 마이그레이션 실패 시 처리
    }
    return [];
  }

  /// 새로운 기록을 추가합니다.
  Future<void> addRecord(PointRecord record) async {
    await _db.insertRecord(record);
  }

  /// 기록을 삭제합니다.
  Future<void> deleteRecord(String id) async {
    await _db.deleteRecord(id);
  }

  /// 기록을 업데이트합니다.
  Future<void> updateRecord(PointRecord record) async {
    await _db.updateRecord(record);
  }

  /// 모든 기록을 덮어씁니다 (주로 재계산 후 정렬된 상태를 저장할 때 사용).
  Future<void> overwriteAllRecords(List<PointRecord> records) async {
    await _db.clearAll();
    for (final r in records) {
      await _db.insertRecord(r);
    }
  }
}
