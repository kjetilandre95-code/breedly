import 'package:flutter/foundation.dart';

class ProgesteroneUnitProvider extends ChangeNotifier {
  String _preferredUnit = 'ng/mL';

  String get preferredUnit => _preferredUnit;

  Future<void> setUnit(String unit) async {
    if (_preferredUnit == unit) return;
    _preferredUnit = unit;
    notifyListeners();
  }
}
