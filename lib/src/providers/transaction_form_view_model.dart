import 'package:flutter/foundation.dart';
import '../models/point_record.dart';
import '../utils/point_manager.dart';
import '../viewmodels/point_view_model.dart';

/// 거래 입력 화면(TransactionFormScreen)의 폼 상태 및 저장 로직을 담당하는 ViewModel입니다.
class TransactionFormViewModel extends ChangeNotifier {
  final TransactionType transactionType;
  final PointViewModel pointViewModel;

  String _amount = '';
  String _reason = '';

  TransactionFormViewModel({
    required this.transactionType,
    required this.pointViewModel,
  });

  String get amount => _amount;
  String get reason => _reason;
  bool get isIncome => transactionType == TransactionType.income;

  void setAmount(String value) {
    _amount = value;
    notifyListeners();
  }

  void setReason(String value) {
    _reason = value;
    notifyListeners();
  }

  /// 입력값이 유효한지 확인합니다.
  bool get isValid {
    final v = double.tryParse(_amount) ?? 0;
    return v > 0 && _reason.trim().isNotEmpty;
  }

  /// 금액을 1단계(수입 1P, 지출 1,000원) 증가시킵니다.
  void increaseAmount() {
    final v = double.tryParse(_amount) ?? 0;
    final step = isIncome ? 1.0 : 1000.0;
    _amount = (v + step).toStringAsFixed(0);
    notifyListeners();
  }

  /// 금액을 1단계(수입 1P, 지출 1,000원) 감소시킵니다.
  void decreaseAmount() {
    final v = double.tryParse(_amount) ?? 0;
    final step = isIncome ? 1.0 : 1000.0;
    final newV = (v - step).clamp(0, double.infinity);
    _amount = newV.toStringAsFixed(0);
    notifyListeners();
  }

  /// 거래 내용을 저장합니다.
  Future<bool> save() async {
    if (!isValid) return false;

    final v = double.tryParse(_amount) ?? 0;
    final trimmedReason = _reason.trim();

    if (isIncome) {
      await pointViewModel.addPointIncome(v.toInt(), trimmedReason);
      return true;
    } else {
      return await pointViewModel.addExpense(v, trimmedReason);
    }
  }

  /// 현재 입력된 금액에 대한 변환 값(P <-> 원)을 가져옵니다.
  String get conversionHint {
    final v = double.tryParse(_amount) ?? 0;
    if (v <= 0) return '';
    
    final pm = PointManager();
    return isIncome
        ? pm.formatKRW(pm.pointsToKRW(v))
        : pm.formatPoints(pm.krwToPoints(v));
  }
}
