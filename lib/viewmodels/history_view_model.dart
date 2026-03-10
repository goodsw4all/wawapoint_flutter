import 'package:flutter/foundation.dart';
import '../models/point_record.dart';
import '../utils/point_manager.dart';

enum TimePeriod { week, month, year }

extension TimePeriodExt on TimePeriod {
  String get label {
    switch (this) {
      case TimePeriod.week:
        return '주간';
      case TimePeriod.month:
        return '월간';
      case TimePeriod.year:
        return '연간';
    }
  }
}

/// 기록 화면(HistoryScreen)의 상태와 비즈니스 로직을 담당하는 ViewModel입니다.
class HistoryViewModel extends ChangeNotifier {
  TimePeriod _selectedPeriod = TimePeriod.month;
  TimePeriod get selectedPeriod => _selectedPeriod;

  void setPeriod(TimePeriod period) {
    if (_selectedPeriod != period) {
      _selectedPeriod = period;
      notifyListeners();
    }
  }

  /// 지정된 기간에 따라 기록을 필터링합니다.
  List<PointRecord> getFilteredRecords(List<PointRecord> records) {
    final now = DateTime.now();
    final DateTime start;
    switch (_selectedPeriod) {
      case TimePeriod.week:
        start = now.subtract(const Duration(days: 7));
        break;
      case TimePeriod.month:
        start = DateTime(now.year, now.month - 1, now.day);
        break;
      case TimePeriod.year:
        start = DateTime(now.year - 1, now.month, now.day);
        break;
    }
    return records.where((r) => r.date.isAfter(start)).toList();
  }

  /// 총 수입을 계산합니다.
  double calculateTotalIncome(List<PointRecord> records) {
    final pm = PointManager();
    return records
        .where((r) => r.type == TransactionType.income)
        .fold(0.0, (s, r) => s + pm.pointsToKRW(r.amount));
  }

  /// 총 지출을 계산합니다.
  double calculateTotalExpense(List<PointRecord> records) {
    return records
        .where((r) => r.type == TransactionType.expense)
        .fold(0.0, (s, r) => s + r.amount);
  }

  /// 차트 표시를 위해 지출 데이터를 날짜별로 그룹화합니다.
  Map<DateTime, double> groupExpensesByDay(List<PointRecord> filteredRecords) {
    final Map<DateTime, double> grouped = {};
    final expenseRecords =
        filteredRecords.where((r) => r.type == TransactionType.expense);
    
    for (final r in expenseRecords) {
      final day = DateTime(r.date.year, r.date.month, r.date.day);
      grouped[day] = (grouped[day] ?? 0) + r.amount;
    }
    return grouped;
  }
}
