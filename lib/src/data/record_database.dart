import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/point_record.dart';

/// [PointRecord] 데이터를 로컬 SQLite 데이터베이스에 영구 저장하는 래퍼 클래스
class RecordDatabase {
  static final RecordDatabase instance = RecordDatabase._init();

  static Database? _database;

  RecordDatabase._init();

  /// 데이터베이스 인스턴스를 반환하며, 초기화되지 않은 경우 생성합니다.
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

  /// 데이터베이스가 처음 만들어질 때 테이블 스키마를 정의합니다.
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

  /// DB에 저장된 모든 기록을 최신순으로 가져와서 반환합니다.
  Future<List<PointRecord>> getAllRecords() async {
    final db = await instance.database;
    final orderBy = 'date DESC';
    final result = await db.query('records', orderBy: orderBy);
    return result.map((json) => PointRecord.fromJson(json)).toList();
  }

  /// 새 기록을 데이터베이스 테이블에 삽입합니다.
  Future<int> insertRecord(PointRecord record) async {
    final db = await instance.database;
    return await db.insert('records', record.toJson());
  }

  /// 기존 기록의 내용을 갱신합니다.
  Future<int> updateRecord(PointRecord record) async {
    final db = await instance.database;
    return await db.update('records', record.toJson(),
        where: 'id = ?', whereArgs: [record.id]);
  }

  /// 주어진 ID를 가진 기록을 테이블에서 삭제합니다.
  Future<int> deleteRecord(String id) async {
    final db = await instance.database;
    return await db.delete('records', where: 'id = ?', whereArgs: [id]);
  }

  /// 테이블의 모든 데이터를 삭제합니다.
  Future<int> clearAll() async {
    final db = await instance.database;
    return db.delete('records');
  }

  /// 데이터베이스 연결을 안전하게 종료합니다.
  Future<void> close() async {
    final db = await instance.database;
    db.close();
    _database = null;
  }
}
