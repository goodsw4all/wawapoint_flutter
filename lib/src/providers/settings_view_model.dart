import 'package:flutter/foundation.dart';
import '../data/point_manager.dart';

/// 앱의 설정(포인트 환산율 등)을 관리하는 ViewModel
class SettingsViewModel extends ChangeNotifier {
  double _pointRate = 2500.0;

  /// 현재 설정된 포인트당 원화 환산율
  double get pointRate => _pointRate;

  /// 포맷팅된 환산율 문자열
  String get formattedRate => _pointRate.toStringAsFixed(0);

  /// 영속 저장소에서 설정을 로드합니다.
  Future<void> load() async {
    await PointManager().load();
    _pointRate = PointManager().pointToKRWRate;
    notifyListeners();
  }

  /// 포인트 환산율을 새 값으로 업데이트하고 저장합니다.
  Future<bool> setRate(double rate) async {
    if (rate <= 0) return false;
    await PointManager().setRate(rate);
    _pointRate = rate;
    notifyListeners();
    return true;
  }
}
