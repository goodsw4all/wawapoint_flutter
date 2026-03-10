import 'package:flutter/foundation.dart';
import '../viewmodels/point_view_model.dart';

/// 대시보드 화면(DashboardScreen)의 시각적 상태와 애니메이션 로직을 담당하는 ViewModel입니다.
class DashboardViewModel extends ChangeNotifier {
  final PointViewModel pointViewModel;
  
  double _balanceScale = 1.0;
  double _prevBalance = 0.0;

  DashboardViewModel({required this.pointViewModel}) {
    _prevBalance = pointViewModel.currentBalance;
  }

  double get balanceScale => _balanceScale;

  /// 잔액 변화를 감지하고 애니메이션을 트리거해야 하는지 확인합니다.
  bool checkAndTriggerAnimation() {
    if (pointViewModel.currentBalance != _prevBalance) {
      _prevBalance = pointViewModel.currentBalance;
      _triggerBalanceScaleAnimation();
      return true;
    }
    return false;
  }

  void _triggerBalanceScaleAnimation() {
    _balanceScale = 1.1;
    notifyListeners();
    
    Future.delayed(const Duration(milliseconds: 200), () {
      _balanceScale = 1.0;
      notifyListeners();
    });
  }
}
