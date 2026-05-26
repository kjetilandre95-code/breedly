import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgesteroneUnitProvider extends ChangeNotifier {
  static const _prefsKey = 'preferred_progesterone_unit';

  String _preferredUnit = 'ng/mL';

  String get preferredUnit => _preferredUnit;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _preferredUnit = prefs.getString(_prefsKey) ?? _preferredUnit;
    notifyListeners();
  }

  Future<void> setUnit(String unit) async {
    if (_preferredUnit == unit) return;
    _preferredUnit = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, unit);
    notifyListeners();
  }
}
