import 'package:flutter/foundation.dart';
import 'point_view_model.dart';

/// 대시보드 화면(DashboardScreen)의 시각적 상태와 애니메이션 로직을 담당하는 ViewModel입니다.
class DashboardViewModel extends ChangeNotifier {
  final PointViewModel pointViewModel;
  
  double _balanceScale = 1.0;
  double _prevBalance = 0.0;

  DashboardViewModel({required this.pointViewModel}) {
    _prevBalance = pointViewModel.currentBalance;
    // PointViewModel의 변경사항을 직접 리스닝하여 애니메이션 트리거
    pointViewModel.addListener(_onPointModelChanged);
  }

  double get balanceScale => _balanceScale;

  void _onPointModelChanged() {
    if (pointViewModel.currentBalance != _prevBalance) {
      _prevBalance = pointViewModel.currentBalance;
      _triggerBalanceScaleAnimation();
    }
  }

  void _triggerBalanceScaleAnimation() {
    _balanceScale = 1.2; // 조금 더 눈에 띄게 변경
    notifyListeners();
    
    Future.delayed(const Duration(milliseconds: 200), () {
      _balanceScale = 1.0;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    pointViewModel.removeListener(_onPointModelChanged);
    super.dispose();
  }
}
