import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 포인트 환산 및 포맷팅을 관리하는 유틸리티 클래스 (싱글톤)
/// 
/// 포인트와 원화(KRW) 간의 변환 비율을 관리하고, UI에 표시될 포맷팅을 제공합니다.
class PointManager {
  static final PointManager _instance = PointManager._internal();
  factory PointManager() => _instance;
  PointManager._internal();

  double _pointToKRWRate = 2500.0;

  double get pointToKRWRate => _pointToKRWRate;

  /// SharedPreferences에서 저장된 포인트-원화 환산율을 불러옵니다.
  /// (기본값: 1포인트 = 2500원)
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _pointToKRWRate = prefs.getDouble('pointToKRWRate') ?? 2500.0;
  }

  /// 새로운 커스텀 환산율을 지정하고 로컬 저장소에 저장합니다.
  Future<void> setRate(double rate) async {
    if (rate <= 0) return;
    _pointToKRWRate = rate;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('pointToKRWRate', rate);
  }

  /// 포인트를 원화(KRW) 가치로 환산합니다.
  double pointsToKRW(double points) => points * _pointToKRWRate;

  /// 원화(KRW)를 포인트 가치로 기산합니다.
  double krwToPoints(double krw) => krw / _pointToKRWRate;

  /// 주어진 잔액으로 해당 지출(비용)을 감당할 수 있는지 검사합니다.
  bool canAfford(double balance, double expense) => balance >= expense;

  /// 숫자를 한국 원화 형식 포맷(예: "1,000원")으로 변환합니다.
  String formatKRW(double amount) =>
      '${NumberFormat('#,###').format(amount)}원';

  /// 숫자를 포인트 형식 포맷(예: "1,000 P")으로 변환합니다.
  String formatPoints(double points) =>
      '${NumberFormat('#,###.##').format(points)} P';
}
