import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  // Language code mapping for TTS
  final Map<String, String> _ttsLanguageCodes = {
    'English': 'en-US',
    'Hindi': 'hi-IN',
    'Bengali': 'bn-IN',
    'Tamil': 'ta-IN',
    'Telugu': 'te-IN',
    'Marathi': 'mr-IN',
    'Urdu': 'ur-PK',
    'Gujarati': 'gu-IN',
    'Kannada': 'kn-IN',
    'Malayalam': 'ml-IN',
    'Punjabi': 'pa-IN',
    'Spanish': 'es-ES',
    'French': 'fr-FR',
    'German': 'de-DE',
    'Chinese': 'zh-CN',
    'Japanese': 'ja-JP',
    'Russian': 'ru-RU',
    'Arabic': 'ar-SA',
  };

  // Singleton pattern
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  Future<void> _initTTS() async {
    if (_isInitialized) return;

    try {
      // Set initial configuration
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5); // Slower rate for better understanding
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // Listen to TTS events
      _flutterTts.setStartHandler(() {
        debugPrint('TTS started');
      });

      _flutterTts.setCompletionHandler(() {
        debugPrint('TTS completed');
      });

      _flutterTts.setErrorHandler((error) {
        debugPrint('TTS error: $error');
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize TTS: $e');
    }
  }

  Future<void> speak(String text, String language) async {
    await _initTTS();

    try {
      // Get the language code for TTS
      final languageCode = _ttsLanguageCodes[language] ?? 'en-US';

      // Check if language is supported
      final availableLanguages = await _flutterTts.getLanguages;

      // Print available languages for debugging
      debugPrint('Available TTS languages: $availableLanguages');

      if (availableLanguages is List &&
          !availableLanguages.contains(languageCode)) {
        debugPrint('Language not supported: $languageCode, falling back to en-US');
        await _flutterTts.setLanguage('en-US');
      } else {
        await _flutterTts.setLanguage(languageCode);
      }

      // Stop any ongoing speech
      await _flutterTts.stop();

      // Speak the text
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  Future<void> stop() async {
    if (!_isInitialized) return;

    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
    }
  }
}
