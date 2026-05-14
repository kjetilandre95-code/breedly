import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgesteroneUnitProvider extends ChangeNotifier {
  static const _prefsKey = 'preferred_progesterone_unit';

  String _preferredUnit = 'ng/mL';

  String get preferredUnit => _preferredUnit;

  ProgesteroneUnitProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == 'ng/mL' || saved == 'nmol/L') {
      _preferredUnit = saved!;
      notifyListeners();
    }
  }

  Future<void> setUnit(String unit) async {
    if (unit != 'ng/mL' && unit != 'nmol/L') return;
    if (_preferredUnit == unit) return;
    _preferredUnit = unit;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, unit);
  }
}
