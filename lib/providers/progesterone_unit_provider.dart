import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgesteroneUnitProvider extends ChangeNotifier {
  static const _preferenceKey = 'preferred_progesterone_unit';
  String _preferredUnit = 'ng/mL';

  ProgesteroneUnitProvider() {
    _load();
  }

  String get preferredUnit => _preferredUnit;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_preferenceKey);
    if (saved == null || saved == _preferredUnit) return;
    _preferredUnit = saved;
    notifyListeners();
  }

  Future<void> setUnit(String unit) async {
    if (unit == _preferredUnit) return;
    _preferredUnit = unit;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferenceKey, unit);
  }
}
