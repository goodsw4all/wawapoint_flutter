import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PointManager {
  static final PointManager _instance = PointManager._internal();
  factory PointManager() => _instance;
  PointManager._internal();

  double _pointToKRWRate = 2500.0;

  double get pointToKRWRate => _pointToKRWRate;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _pointToKRWRate = prefs.getDouble('pointToKRWRate') ?? 2500.0;
  }

  Future<void> setRate(double rate) async {
    if (rate <= 0) return;
    _pointToKRWRate = rate;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('pointToKRWRate', rate);
  }

  double pointsToKRW(double points) => points * _pointToKRWRate;

  double krwToPoints(double krw) => krw / _pointToKRWRate;

  bool canAfford(double balance, double expense) => balance >= expense;

  String formatKRW(double amount) =>
      '${NumberFormat('#,###').format(amount)}원';

  String formatPoints(double points) =>
      '${NumberFormat('#,###.##').format(points)} P';
}
