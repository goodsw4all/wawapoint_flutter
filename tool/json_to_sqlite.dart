/// Standalone Dart script that converts a WaWaPoint JSON backup file
/// into a SQLite database file (`wawapoint.db`).
///
/// Usage:
///   dart run tool/json_to_sqlite.dart path/to/backup.json [output.db]
///
/// If [output.db] is omitted, `wawapoint.db` is created in the current
/// directory.
library;

import 'dart:convert';
import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/json_to_sqlite.dart <backup.json> [output.db]');
    exit(1);
  }

  final jsonPath = args[0];
  final dbPath = File(args.length > 1 ? args[1] : 'wawapoint.db').absolute.path;

  // ── 1. Read & parse JSON ──────────────────────────────────────────
  final file = File(jsonPath);
  if (!file.existsSync()) {
    stderr.writeln('File not found: $jsonPath');
    exit(1);
  }

  final content = file.readAsStringSync();
  final Map<String, dynamic> backup = jsonDecode(content) as Map<String, dynamic>;
  final List<dynamic> records = backup['records'] as List<dynamic>;

  // ── 2. Initialise sqflite FFI (runs without Flutter engine) ───────
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;

  // Remove existing db so we start fresh
  final dbFile = File(dbPath);
  if (dbFile.existsSync()) dbFile.deleteSync();

  final db = await factory.openDatabase(
    dbPath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE records (
            id          TEXT PRIMARY KEY,
            date        TEXT NOT NULL,
            type        TEXT NOT NULL,
            amount      REAL NOT NULL,
            reason      TEXT NOT NULL,
            balanceAfter REAL NOT NULL
          )
        ''');
      },
    ),
  );

  // ── 3. Insert records inside a single transaction ─────────────────
  int inserted = 0;
  await db.transaction((txn) async {
    for (final r in records) {
      final map = r as Map<String, dynamic>;
      await txn.insert('records', {
        'id': map['id'] as String,
        'date': map['date'] as String,
        'type': map['type'] as String,
        'amount': (map['amount'] as num).toDouble(),
        'reason': map['reason'] as String,
        'balanceAfter': (map['balanceAfter'] as num).toDouble(),
      });
      inserted++;
    }
  });

  await db.close();

  stdout.writeln('✅ $inserted records → $dbPath (${File(dbPath).lengthSync()} bytes)');
}
