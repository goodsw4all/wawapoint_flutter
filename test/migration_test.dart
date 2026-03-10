import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wawapoint/viewmodels/point_view_model.dart';
import 'package:wawapoint/viewmodels/backup_view_model.dart';
import 'package:wawapoint/utils/record_database.dart';
import 'package:wawapoint/utils/point_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // initialize sqflite ffi implementation for desktop tests
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  SharedPreferences.setMockInitialValues({});

  // provide a fake path_provider implementation that returns a temp directory
  PathProviderPlatform.instance = _FakePathProvider();

  group('SQLite migration', () {
    // ensure the database path is unique per test run; sqflite ffi uses in-memory by default,
    // but we still clear between tests in tearDown.
    tearDown(() async {
      // clear db and delete any legacy files after each test
      await RecordDatabase.instance.clearAll();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/wawapoint_records.json');
      if (await file.exists()) {
        await file.delete();
      }
    });

    test('importBackup stores data in database', () async {
      final vm = PointViewModel();
      final backupVM = BackupViewModel(vm);

      // create a fake backup with two records
      final records = [
        {
          'id': '1',
          'date': DateTime.now().toIso8601String(),
          'type': 'income',
          'amount': 5,
          'reason': 'test',
          'balanceAfter': 100
        }
      ];
      final backup = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'records': records
      };
      final jsonStr = const JsonEncoder.withIndent('  ').convert(backup);

      final count = await backupVM.importBackup(jsonStr);
      expect(count, records.length);

      final dbRecords = await RecordDatabase.instance.getAllRecords();
      expect(dbRecords, hasLength(records.length));
      expect(vm.records, hasLength(records.length));
    });

    test('automatic migration from legacy file', () async {
      // prepare legacy json file
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/wawapoint_records.json');
      final sample = [
        {
          'id': '2',
          'date': DateTime.now().toIso8601String(),
          'type': 'expense',
          'amount': 3,
          'reason': 'legacy',
          'balanceAfter': 50
        }
      ];
      await file.writeAsString(jsonEncode(sample));

      final vm = PointViewModel();
      await vm.loadRecords();

      expect(vm.records, hasLength(1));
      final dbRecords = await RecordDatabase.instance.getAllRecords();
      expect(dbRecords, hasLength(1));
      expect(await file.exists(), isFalse, reason: 'legacy file should be deleted');
    });
  });
}

class _FakePathProvider extends PathProviderPlatform {
  @override
  Future<String> getApplicationDocumentsPath() async {
    final dir = Directory.systemTemp.createTempSync('wawapoint_test');
    return dir.path;
  }

  @override
  Future<String> getTemporaryPath() async {
    final dir = Directory.systemTemp.createTempSync('wawapoint_test');
    return dir.path;
  }
}
