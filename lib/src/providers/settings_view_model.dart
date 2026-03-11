import 'package:flutter/foundation.dart';
import '../data/point_manager.dart';

class SettingsViewModel extends ChangeNotifier {
  double _pointRate = 2500.0;

  double get pointRate => _pointRate;

  String get formattedRate => _pointRate.toStringAsFixed(0);

  Future<void> load() async {
    await PointManager().load();
    _pointRate = PointManager().pointToKRWRate;
    notifyListeners();
  }

  Future<bool> setRate(double rate) async {
    if (rate <= 0) return false;
    await PointManager().setRate(rate);
    _pointRate = rate;
    notifyListeners();
    return true;
  }
}
