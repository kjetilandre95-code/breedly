import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgesteroneUnitProvider extends ChangeNotifier {
  static const String _prefKey = 'preferred_progesterone_unit';

  String _preferredUnit = 'ng/mL';

  String get preferredUnit => _preferredUnit;

  ProgesteroneUnitProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _preferredUnit = prefs.getString(_prefKey) ?? _preferredUnit;
    notifyListeners();
  }

  Future<void> setUnit(String unit) async {
    if (_preferredUnit == unit) return;
    _preferredUnit = unit;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, unit);
  }
}
