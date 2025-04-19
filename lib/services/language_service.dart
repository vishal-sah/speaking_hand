import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LanguageService {
  // List of supported languages
  final List<String> availableLanguages = [
    'English',
    'Hindi',
    'Bengali',
    'Tamil',
    'Telugu',
    'Marathi',
    'Bangla',
    'Nepali',
    'Urdu',
    'Gujarati',
    'Kannada',
    'Malayalam',
    'Punjabi',
    'Spanish',
    'French',
    'German',
    'Chinese',
    'Japanese',
    'Russian',
    'Arabic',
  ];

  // Language code mapping for translation API
  final Map<String, String> languageCodes = {
    'English': 'en',
    'Hindi': 'hi',
    'Bengali': 'bn',
    'Tamil': 'ta',
    'Telugu': 'te',
    'Marathi': 'mr',
    'Bangla': 'bn', 
    'Nepali': 'ne',
    'Urdu': 'ur',
    'Gujarati': 'gu',
    'Kannada': 'kn',
    'Malayalam': 'ml',
    'Punjabi': 'pa',
    'Spanish': 'es',
    'French': 'fr',
    'German': 'de',
    'Chinese': 'zh',
    'Japanese': 'ja',
    'Russian': 'ru',
    'Arabic': 'ar',
  };

  // Singleton pattern
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  // Method to translate text from English to the target language
  Future<String> translateText({
    required String text,
    required String targetLanguage,
  }) async {
    // If target language is English or text is empty, return the original text
    if (targetLanguage == 'English' || text.isEmpty) {
      return text;
    }

    try {
      // Get the language code for the target language
      final targetCode = languageCodes[targetLanguage];

      if (targetCode == null) {
        debugPrint('Target language code not found for: $targetLanguage');
        return text;
      }

      // Use a third-party translation API (Google Translate API in this example)
      // Note: In a production app, you'd need an API key and proper authentication
      final response = await http.post(
        Uri.parse('https://translation.googleapis.com/language/translate/v2'),
        headers: {
          'Content-Type': 'application/json',
          // Include API key in actual implementation
          // 'Authorization': 'Bearer YOUR_API_KEY',
        },
        body: jsonEncode({
          'q': text,
          'source': 'en',
          'target': targetCode,
          // 'format': 'text',
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String translatedText = data['data']['translations'][0]['translatedText'];
        return translatedText;
      } else {
        debugPrint('Translation API error: ${response.statusCode}, ${response.body}');

        // Return mock translation for development/testing
        return _getMockTranslation(text, targetLanguage);
      }
    } catch (e) {
      debugPrint('Error during translation: $e');

      // Return mock translation if real translation fails
      return _getMockTranslation(text, targetLanguage);
    }
  }

  // Generate a mock translation for development/testing
  String _getMockTranslation(String text, String targetLanguage) {
    // For demonstration/testing, just add a prefix with the target language
    return '[$targetLanguage] $text';
  }
}
