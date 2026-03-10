import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/point_record.dart';
import '../utils/point_manager.dart';
import '../utils/record_database.dart';

class PointViewModel extends ChangeNotifier {
  final List<PointRecord> _records = [];
  double _currentBalance = 0.0;

  List<PointRecord> get records => List.unmodifiable(_records);
  double get currentBalance => _currentBalance;

  String get formattedBalance =>
      PointManager().formatKRW(_currentBalance);

  String get formattedPoints =>
      PointManager().formatPoints(PointManager().krwToPoints(_currentBalance));

  double get currentPoints =>
      PointManager().krwToPoints(_currentBalance);

  // ───────────────────────── Persistence ──────────────────────────

  /// legacy JSON file used before SQLite migration.
  Future<File> _getLegacyDataFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/wawapoint_records.json');
  }

  Future<void> loadRecords() async {
    await PointManager().load();

    // first try loading from database
    try {
      final dbRecords = await RecordDatabase.instance.getAllRecords();
      _records
        ..clear()
        ..addAll(dbRecords);
      _calculateBalance();
      if (dbRecords.isNotEmpty) {
        notifyListeners();
        return;
      }
    } catch (_) {
      // ignore, we'll try legacy file
    }

    // if db was empty, attempt migration from old json file
    try {
      final file = await _getLegacyDataFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> list = jsonDecode(content) as List<dynamic>;
        final migrated = list
            .map((e) => PointRecord.fromJson(e as Map<String, dynamic>))
            .toList();

        // populate both in-memory list and sqlite
        _records.clear();
        _records.addAll(migrated);
        _records.sort((a, b) => b.date.compareTo(a.date));
        _calculateBalance();

        final db = RecordDatabase.instance;
        await db.clearAll();
        for (final r in migrated) {
          await db.insertRecord(r);
        }

        // optionally remove legacy file so we don't migrate twice
        await file.delete();
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _saveRecords() async {
    try {
      // write to sqlite instead of file; keep the json file for backwards
      // compatibility or debugging but it's no longer authoritative.
      final db = RecordDatabase.instance;
      await db.clearAll();
      for (final r in _records) {
        await db.insertRecord(r);
      }
    } catch (_) {}
  }

  // ───────────────────────── Business Logic ──────────────────────────

  void _calculateBalance() {
    if (_records.isNotEmpty) {
      final sorted = [..._records]
        ..sort((a, b) => b.date.compareTo(a.date));
      _currentBalance = sorted.first.balanceAfter;
    } else {
      _currentBalance = 0.0;
    }
  }

  Future<void> addPointIncome(int points, String reason) async {
    final amount = points.toDouble();
    final krw = PointManager().pointsToKRW(amount);
    final newBalance = _currentBalance + krw;

    final record = PointRecord(
      date: DateTime.now(),
      type: TransactionType.income,
      amount: amount,
      reason: reason,
      balanceAfter: newBalance,
    );

    _records.insert(0, record);
    _currentBalance = newBalance;
    notifyListeners();
    await _saveRecords();
  }

  Future<bool> addExpense(double krw, String reason) async {
    if (!PointManager().canAfford(_currentBalance, krw)) {
      return false;
    }

    final newBalance = _currentBalance - krw;

    final record = PointRecord(
      date: DateTime.now(),
      type: TransactionType.expense,
      amount: krw,
      reason: reason,
      balanceAfter: newBalance,
    );

    _records.insert(0, record);
    _currentBalance = newBalance;
    notifyListeners();
    await _saveRecords();
    return true;
  }

  Future<void> deleteRecord(PointRecord record) async {
    _records.removeWhere((r) => r.id == record.id);
    await recalculateAllBalances();
    notifyListeners();
    await _saveRecords();
  }

  Future<void> updateRecord(
    PointRecord record, {
    required double newAmount,
    required String newReason,
  }) async {
    final idx = _records.indexWhere((r) => r.id == record.id);
    if (idx == -1) return;
    _records[idx].amount = newAmount;
    _records[idx].reason = newReason;
    await recalculateAllBalances();
    notifyListeners();
    await _saveRecords();
  }

  Future<void> recalculateAllBalances() async {
    final sorted = [..._records]
      ..sort((a, b) => a.date.compareTo(b.date));

    double balance = 0.0;
    for (final r in sorted) {
      if (r.type == TransactionType.income) {
        balance += PointManager().pointsToKRW(r.amount);
      } else {
        balance -= r.amount;
      }
      r.balanceAfter = balance;
    }

    _records
      ..clear()
      ..addAll(sorted.reversed);

    _calculateBalance();
    notifyListeners();
    await _saveRecords();
  }

  List<String> validateBalances() {
    final issues = <String>[];
    final sorted = [..._records]
      ..sort((a, b) => a.date.compareTo(b.date));

    double expected = 0.0;
    for (int i = 0; i < sorted.length; i++) {
      final r = sorted[i];
      if (r.type == TransactionType.income) {
        expected += PointManager().pointsToKRW(r.amount);
      } else {
        expected -= r.amount;
      }
      if ((r.balanceAfter - expected).abs() > 0.01) {
        issues.add(
          '거래 #${i + 1} (${r.reason}): 잔액 불일치 (예상: ${expected.toStringAsFixed(0)}원, 실제: ${r.balanceAfter.toStringAsFixed(0)}원)',
        );
      }
    }
    return issues;
  }

}
