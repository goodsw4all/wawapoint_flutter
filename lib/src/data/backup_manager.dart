import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/point_record.dart';

/// 공유 및 복원을 위한 백업 데이터 모델
/// 
/// 백업 파일 포맷의 버전을 관리하고 내보내기 당시의 기록 목록을 담습니다.
class BackupData {
  final String version;
  final DateTime exportDate;
  final List<PointRecord> records;

  BackupData({
    required this.version,
    required this.exportDate,
    required this.records,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'exportDate': exportDate.toIso8601String(),
        'records': records.map((r) => r.toJson()).toList(),
      };

  factory BackupData.fromJson(Map<String, dynamic> json) => BackupData(
        version: json['version'] as String,
        exportDate: DateTime.parse(json['exportDate'] as String),
        records: (json['records'] as List<dynamic>)
            .map((r) => PointRecord.fromJson(r as Map<String, dynamic>))
            .toList(),
      );
}

/// JSON 파일 기반 데이터 백업 및 복원 기능 매니저 (싱글톤)
///
/// 파일 시스템 접근과 JSON 직렬화/역직렬화 책임을 가집니다.
class BackupManager {
  static final BackupManager _instance = BackupManager._internal();
  factory BackupManager() => _instance;
  BackupManager._internal();

  /// 백업 생성 일시 기반 고유 파일명 생성
  String generateFileName() {
    final dateStr = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
    return 'WaWaPoint_Backup_$dateStr.json';
  }

  /// 트랜잭션 기록 목록을 예쁘게 인덴트된 JSON 문자열로 직렬화
  String exportToJson(List<PointRecord> records) {
    final backup = BackupData(
      version: '1.0',
      exportDate: DateTime.now(),
      records: records,
    );
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(backup.toJson());
  }

  /// 앱 내부 문서 디렉토리에 백업 파일(JSON) 임시 저장
  Future<File> saveToDocuments(String jsonString, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    return file.writeAsString(jsonString);
  }

  /// 외부에서 읽어들인 JSON 백업 파일의 구조가 올바른지 유효성 검증
  ({bool isValid, int recordCount, DateTime? exportDate}) validateBackupData(
      String jsonString) {
    try {
      final Map<String, dynamic> json =
          jsonDecode(jsonString) as Map<String, dynamic>;
      final backup = BackupData.fromJson(json);
      return (
        isValid: true,
        recordCount: backup.records.length,
        exportDate: backup.exportDate,
      );
    } catch (_) {
      return (isValid: false, recordCount: 0, exportDate: null);
    }
  }

  /// JSON 문자열 파싱하여 `PointRecord` 도메인 객체 리스트로 복원
  List<PointRecord> importFromJson(String jsonString) {
    final Map<String, dynamic> json =
        jsonDecode(jsonString) as Map<String, dynamic>;
    final backup = BackupData.fromJson(json);
    return backup.records;
  }
}
