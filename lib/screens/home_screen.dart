import 'package:flutter/material.dart';
import 'package:speaking_hand/services/language_service.dart';
import 'package:speaking_hand/widgets/camera_view.dart';
import 'package:speaking_hand/services/tts_service.dart';
import 'package:translator/translator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isCameraInitialized = false;
  String detectedText = "";
  ValueNotifier<String> translatedText = ValueNotifier('');
  String selectedLanguage = "English";
  bool isListening = false;
  VoidCallback? _translatedTextListener;
  final ValueNotifier<int> toggleCameraNotifier = ValueNotifier(0);
  final translator = GoogleTranslator();
  String selectedLanguageCode = 'en';

  final TextStyle subtitleStyle = const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    shadows: [
      Shadow(blurRadius: 3.0, color: Colors.black, offset: Offset(1.0, 1.0)),
    ],
  );

  void startCamera() {
    setState(() {
      isCameraInitialized = true;
    });
  }

  void onSignDetected(String text) {
    setState(() {
      detectedText = text;
      translateTextTo();
    });
  }

  void translateTextTo() async {
    if (detectedText.isEmpty) return;

    var translation = await translator.translate(
      detectedText,
      from: 'en',
      to: selectedLanguageCode,
    );

    setState(() {
      translatedText.value = translation.text;
    });
  }

  void translateText() async {
    if (detectedText.isEmpty) return;

    final translation = await LanguageService().translateText(
      text: detectedText,
      targetLanguage: selectedLanguage,
    );

    setState(() {
      translatedText.value = translation;
    });
  }

  void toggleCamera() {
    toggleCameraNotifier.value = toggleCameraNotifier.value == 0 ? 1 : 0;
  }

  void toggleSpeaking() {
    if (isListening) {
      _removeTranslatedTextListener();
    } else {
      _addTranslatedTextListener();
    }

    setState(() {
      isListening = !isListening;
    });
  }

  void _addTranslatedTextListener() {
    _translatedTextListener = () {
      final text = translatedText.value.trim();
      if (text.isNotEmpty) {
        _speak(text);
      }
    };
    translatedText.addListener(_translatedTextListener!);
  }

  void _removeTranslatedTextListener() {
    if (_translatedTextListener != null) {
      translatedText.removeListener(_translatedTextListener!);
      _translatedTextListener = null;
    }
  }

  void _speak(String text) {
    TTSService().speak(text, selectedLanguage);
  }

  void showLanguageSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: LanguageService().availableLanguages.map((language) {
              return ListTile(
                title: Text(language),
                onTap: () {
                  setState(() {
                    selectedLanguage = language;
                    selectedLanguageCode =
                        LanguageService().languageCodes[language]!;
                  });
                  translateText();
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ISL Translator')),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                // Camera or start camera button
                isCameraInitialized
                    ? CameraView(
                        onSignDetected: onSignDetected,
                        toggleCameraNotifier: toggleCameraNotifier,
                      )
                    : Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Start Camera'),
                          onPressed: startCamera,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                        ),
                      ),

                // Subtitles at bottom
                if (translatedText.value.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        translatedText.value,
                        style: subtitleStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                // Language selection button
                if (isCameraInitialized)
                  Positioned(
                    left: 20,
                    top: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.language, color: Colors.white),
                        onPressed: showLanguageSelector,
                        tooltip: 'Change Language',
                      ),
                    ),
                  ),

                // Text to speech button
                if (isCameraInitialized)
                  Positioned(
                    left: 20,
                    top: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          isListening ? Icons.volume_up : Icons.volume_off,
                          color: Colors.white,
                        ),
                        onPressed: toggleSpeaking,
                        tooltip: 'Text to Speech',
                      ),
                    ),
                  ),
                if (isCameraInitialized)
                  Positioned(
                    right: 20,
                    top: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.cameraswitch, color: Colors.white),
                        onPressed: toggleCamera,
                        tooltip: 'Toggle Camera',
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Info text at bottom
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: const Text(
              'Make signs to translate to text',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
