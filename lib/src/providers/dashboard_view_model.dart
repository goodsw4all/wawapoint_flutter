import 'package:flutter/foundation.dart';
import 'point_view_model.dart';

/// 대시보드 화면(DashboardScreen)의 시각적 상태와 애니메이션 로직을 담당하는 ViewModel입니다.
class DashboardViewModel extends ChangeNotifier {
  final PointViewModel pointViewModel;
  
  /// 대시보드 잔액 텍스트의 스케일 값 (애니메이션용)
  double _balanceScale = 1.0;
  /// 이전 잔액 (변경 감지용)
  double _prevBalance = 0.0;

  DashboardViewModel({required this.pointViewModel}) {
    _prevBalance = pointViewModel.currentBalance;
    // PointViewModel의 변경사항을 직접 리스닝하여 애니메이션 트리거
    pointViewModel.addListener(_onPointModelChanged);
  }

  /// 현재 잔액 텍스트의 크기 배율
  double get balanceScale => _balanceScale;

  /// PointViewModel의 잔액 변화를 감지하여 애니메이션을 실행합니다.
  void _onPointModelChanged() {
    if (pointViewModel.currentBalance != _prevBalance) {
      _prevBalance = pointViewModel.currentBalance;
      _triggerBalanceScaleAnimation();
    }
  }

  /// 잔액이 변할 때 텍스트가 커졌다가 작아지는 효과를 줍니다.
  void _triggerBalanceScaleAnimation() {
    _balanceScale = 1.2; // 조금 더 눈에 띄게 강조
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
