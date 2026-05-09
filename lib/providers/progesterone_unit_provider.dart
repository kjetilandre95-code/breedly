import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgesteroneUnitProvider extends ChangeNotifier {
  static const String _storageKey = 'preferred_progesterone_unit';
  static const String defaultUnit = 'ng/mL';

  String _preferredUnit = defaultUnit;
  bool _isLoaded = false;

  String get preferredUnit => _preferredUnit;
  bool get isLoaded => _isLoaded;

  ProgesteroneUnitProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _preferredUnit = prefs.getString(_storageKey) ?? defaultUnit;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setUnit(String unit) async {
    if (unit != 'ng/mL' && unit != 'nmol/L') return;
    _preferredUnit = unit;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, unit);
  }
}
