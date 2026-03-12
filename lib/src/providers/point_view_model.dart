import 'package:flutter/foundation.dart';
import '../models/point_record.dart';
import '../data/point_manager.dart';
import '../repositories/point_repository.dart';

/// 앱의 전역적인 포인트 상태와 거래 기록을 관리하는 ViewModel입니다.
/// 가계부의 원장(SSOT: Single Source of Truth) 역할을 수행합니다.
class PointViewModel extends ChangeNotifier {
  final PointRepository _repository = PointRepository();
  final List<PointRecord> _records = [];
  double _currentBalance = 0.0;

  /// 읽기 전용 거래 기록 목록
  List<PointRecord> get records => List.unmodifiable(_records);
  /// 현재 잔액 (원화 기준)
  double get currentBalance => _currentBalance;

  /// 포맷팅된 현재 잔액 문자열 (예: 1,000원)
  String get formattedBalance =>
      PointManager().formatKRW(_currentBalance);

  /// 포맷팅된 현재 포인트 문자열 (예: 1,000 P)
  String get formattedPoints =>
      PointManager().formatPoints(PointManager().krwToPoints(_currentBalance));

  /// 현재 잔액의 포인트 환산값
  double get currentPoints =>
      PointManager().krwToPoints(_currentBalance);

  // ───────────────────────── Persistence ──────────────────────────

  /// 모든 기록을 로드하고 현재 잔액을 계산합니다.
  Future<void> loadRecords() async {
    // 환산율 로드
    await PointManager().load();

    try {
      final loadedRecords = await _repository.getAllRecords();
      _records
        ..clear()
        ..addAll(loadedRecords);
      _calculateBalance();
      notifyListeners();
    } catch (e) {
      // 로드 실패 시 처리 로직
      if (kDebugMode) print('Load records failed: $e');
    }
  }

  /// 모든 기록을 Repository에 저장합니다.
  Future<void> _saveRecords() async {
    try {
      await _repository.overwriteAllRecords(_records);
    } catch (e) {
      if (kDebugMode) print('Save records failed: $e');
    }
  }

  // ───────────────────────── Business Logic ──────────────────────────

  /// 전체 기록을 바탕으로 현재 잔액을 다시 계산합니다.
  void _calculateBalance() {
    if (_records.isNotEmpty) {
      final sorted = [..._records]
        ..sort((a, b) => b.date.compareTo(a.date));
      _currentBalance = sorted.first.balanceAfter;
    } else {
      _currentBalance = 0.0;
    }
  }

  /// 포인트 수입을 추가합니다.
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
    await _repository.addRecord(record);
  }

  /// 지출(원화)을 추가합니다. 잔액이 부족하면 false를 반환합니다.
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
    await _repository.addRecord(record);
    return true;
  }

  /// 특정 기록을 삭제합니다.
  Future<void> deleteRecord(PointRecord record) async {
    _records.removeWhere((r) => r.id == record.id);
    await recalculateAllBalances(); // 잔액 재계산 및 전체 저장
  }

  /// 기존 기록을 수정합니다.
  Future<void> updateRecord(
    PointRecord record, {
    required double newAmount,
    required String newReason,
  }) async {
    final idx = _records.indexWhere((r) => r.id == record.id);
    if (idx == -1) return;
    _records[idx].amount = newAmount;
    _records[idx].reason = newReason;
    await recalculateAllBalances(); // 잔액 재계산 및 전체 저장
  }

  /// 모든 기록의 잔액(balanceAfter)을 처음부터 다시 계산하고 영속 저장소에 반영합니다.
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

  /// 기록된 잔액들 중 오류가 있는지 검증합니다.
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
