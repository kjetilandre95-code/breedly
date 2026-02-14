import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'selectedLanguage';
  Box<dynamic>? _settingsBox;
  
  Locale _currentLocale = const Locale('no');

  LanguageProvider() {
    _initializeLanguage();
  }

  Future<void> _initializeLanguage() async {
    try {
      _settingsBox = await Hive.openBox('settings');
      final savedLanguage = _settingsBox!.get(_languageKey, defaultValue: 'no') as String;
      _currentLocale = Locale(savedLanguage);
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing language: $e');
    }
  }

  Locale get currentLocale => _currentLocale;

  List<Locale> get supportedLocales => const [
    Locale('no'),
    Locale('sv'),
    Locale('da'),
    Locale('fi'),
    Locale('en'),
  ];

  String get currentLanguageName {
    switch (_currentLocale.languageCode) {
      case 'sv':
        return 'Svenska';
      case 'da':
        return 'Dansk';
      case 'fi':
        return 'Suomi';
      case 'en':
        return 'English';
      case 'no':
      default:
        return 'Norsk';
    }
  }

  Future<void> setLanguage(String languageCode) async {
    _currentLocale = Locale(languageCode);
    if (_settingsBox != null && _settingsBox!.isOpen) {
      await _settingsBox!.put(_languageKey, languageCode);
    }
    notifyListeners();
  }
}
