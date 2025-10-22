import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:nav_aif_fyp/pages/page_one.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class TTSPreference {
  static bool enabled = false;
  static String language = 'en';
}

class NavAILanguagePage extends StatelessWidget {
  const NavAILanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LanguageSelectionScreen();
  }
}

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  String selectedLanguage = "English";
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initTTS();
    _startListening();
  }

  Future<void> _initTTS() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(
      "Select your language. Say Urdu for Urdu interface, or Bilingual for both languages with voice assistance.",
    );
  }

  void _startListening() {
    _speech.initialize(
      onStatus: (val) {
        if (val == "done" && !_isListening) {
          _startListening();
        }
      },
      onError: (val) {
        debugPrint('Speech Error: $val');
        setState(() => _isListening = false);
      },
    ).then((available) {
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          localeId: 'en-US',
          onResult: (result) {
            String recognized = result.recognizedWords.toLowerCase().trim();
            _processCommand(recognized);
          },
        );
      } else {
        setState(() => _isListening = false);
      }
    });
  }

  void _processCommand(String recognized) {
    debugPrint("🎙 Recognized: $recognized");
    if (recognized.contains('urdu')) {
      _selectLanguageAndNavigate("Urdu");
    } else if (recognized.contains('bilingual')) {
      _selectLanguageAndNavigate("Bilingual");
    }
  }

  void _selectLanguageAndNavigate(String language) {
    _speech.stop();
    setState(() {
      _isListening = false;
      selectedLanguage = language;

      if (language == "Bilingual") {
        TTSPreference.enabled = true;
        TTSPreference.language = 'en';
      } else if (language == "Urdu") {
        TTSPreference.enabled = true;
        TTSPreference.language = 'ur';
      } else {
        TTSPreference.enabled = false;
        TTSPreference.language = 'en';
      }
    });

    _speakSelection(language).then((_) {
      Future.delayed(const Duration(seconds: 2)).then((_) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const NameInputPage()),
          );
        }
      });
    });
  }

  Future<void> _speakSelection(String language) async {
    await flutterTts.setLanguage("en-US");
    if (language == "Urdu") {
      await flutterTts.speak("You selected Urdu language interface.");
    } else if (language == "Bilingual") {
      await flutterTts
          .speak("You selected Bilingual mode with voice assistance enabled.");
    }
  }

  Widget _buildLanguageOption(String language) {
    final bool isSelected = selectedLanguage == language;
    return GestureDetector(
      onTap: () => _selectLanguageAndNavigate(language),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1349EC).withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: const Color(0xFF1349EC), width: 2)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              language,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Radio<String>(
              value: language,
              groupValue: selectedLanguage,
              onChanged: (value) {
                if (value != null) _selectLanguageAndNavigate(value);
              },
              activeColor: const Color(0xFF1349EC),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1b2a),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/', (route) => false);
                    },
                  ),
                  const Expanded(
                    child: Text(
                      "Language",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildLanguageOption("Urdu"),
                    const SizedBox(height: 12),
                    _buildLanguageOption("Bilingual"),
                    const SizedBox(height: 20),
                    if (_isListening)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.mic,
                                size: 16, color: Colors.greenAccent),
                            SizedBox(width: 8),
                            Text(
                              'Listening... Say "Urdu" or "Bilingual"',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1349EC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    _selectLanguageAndNavigate(selectedLanguage);
                  },
                  child: const Text(
                    "Save",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
