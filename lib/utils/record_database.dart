import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/point_record.dart';

/// Simple SQLite wrapper for storing [PointRecord]s.
class RecordDatabase {
  static final RecordDatabase instance = RecordDatabase._init();

  static Database? _database;

  RecordDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('wawapoint.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  FutureOr<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
      CREATE TABLE records (
        id $idType,
        date $textType,
        type $textType,
        amount $realType,
        reason $textType,
        balanceAfter $realType
      )
    ''');
  }

  Future<List<PointRecord>> getAllRecords() async {
    final db = await instance.database;
    final orderBy = 'date DESC';
    final result = await db.query('records', orderBy: orderBy);
    return result.map((json) => PointRecord.fromJson(json)).toList();
  }

  Future<int> insertRecord(PointRecord record) async {
    final db = await instance.database;
    return await db.insert('records', record.toJson());
  }

  Future<int> updateRecord(PointRecord record) async {
    final db = await instance.database;
    return await db.update('records', record.toJson(),
        where: 'id = ?', whereArgs: [record.id]);
  }

  Future<int> deleteRecord(String id) async {
    final db = await instance.database;
    return await db.delete('records', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearAll() async {
    final db = await instance.database;
    return db.delete('records');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
    _database = null;
  }
}
