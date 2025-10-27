import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleTranslateService {
  static const String _apiKey =
      'AIzaSyA2sk9nVrvS9OoB6hDAAngqS2KjRkOCZ9Y'; // Remplacez par votre vraie clé
  static const String _baseUrl =
      'https://translation.googleapis.com/language/translate/v2';

  // Traduire un texte
  static Future<String> translateText(
      String text, String targetLanguage) async {
    try {
      // Si le texte est vide ou si c'est la langue source, retourner le texte original
      if (text.isEmpty || targetLanguage == 'fr') {
        return text;
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'q': text,
          'target': targetLanguage,
          'source': 'fr', // Langue source fixée au français
          'format': 'text',
          'key': _apiKey,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translatedText =
            data['data']['translations'][0]['translatedText'];
        print('✅ Traduit: "$text" → "$translatedText" ($targetLanguage)');
        return translatedText;
      } else {
        print(
            '❌ Erreur Google Translate: ${response.statusCode} - ${response.body}');
        return text; // Retourne le texte original en cas d'erreur
      }
    } catch (e) {
      print('❌ Erreur de traduction: $e');
      return text;
    }
  }

  // Codes de langue supportés
  static Map<String, String> get supportedLanguages {
    return {
      'fr': 'Français',
      'en': 'English',
      'es': 'Español',
      'de': 'Deutsch',
      'ar': 'العربية',
      'zh': '中文',
    };
  }

  // Obtenir le code de langue pour l'API Google
  static String getGoogleLanguageCode(String appLanguageCode) {
    final Map<String, String> languageMap = {
      'fr': 'fr',
      'en': 'en',
      'es': 'es',
      'de': 'de',
      'ar': 'ar',
      'zh': 'zh-CN', // Chinois simplifié
    };
    return languageMap[appLanguageCode] ?? 'fr';
  }
}
