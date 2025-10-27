import 'package:flutter/material.dart';
import '../services/language_service.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = LanguageService.currentLanguage;

  String get currentLanguage => _currentLanguage;

  void setLanguage(String languageCode) {
    if (_currentLanguage != languageCode) {
      _currentLanguage = languageCode;
      LanguageService.setLanguage(languageCode);
      print('🔄 LanguageProvider: notifyListeners() appelé');
      notifyListeners(); // Cette ligne force le rafraîchissement de l'UI
    }
  }
}
