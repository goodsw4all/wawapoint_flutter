import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/point_record.dart';

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

class BackupManager {
  static final BackupManager _instance = BackupManager._internal();
  factory BackupManager() => _instance;
  BackupManager._internal();

  String generateFileName() {
    final dateStr = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
    return 'WaWaPoint_Backup_$dateStr.json';
  }

  String exportToJson(List<PointRecord> records) {
    final backup = BackupData(
      version: '1.0',
      exportDate: DateTime.now(),
      records: records,
    );
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(backup.toJson());
  }

  Future<File> saveToDocuments(String jsonString, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    return file.writeAsString(jsonString);
  }

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

  List<PointRecord> importFromJson(String jsonString) {
    final Map<String, dynamic> json =
        jsonDecode(jsonString) as Map<String, dynamic>;
    final backup = BackupData.fromJson(json);
    return backup.records;
  }
}
