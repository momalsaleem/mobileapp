
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:nav_aif_fyp/pages/page_one.dart';
import 'package:nav_aif_fyp/main.dart';

// Global TTS preference
class TTSPreference {
  static bool enabled = false;
  static String language = 'en'; // 'en' or 'ur'
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
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  final FlutterTts flutterTts = FlutterTts();
  String selectedLanguage = "English";

  @override
  void initState() {
    super.initState();
    _initTTS();
  }

  Future<void> _initTTS() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);

    // Speak both options when page loads and TTS is enabled
    if (TTSPreference.enabled) {
      await _speakLanguages();
    }
  }

  Future<void> _speakLanguages() async {
    // Speak both options — in English and Urdu
    await flutterTts.speak("Select your language. Urdu, or Bilingual.");
    await Future.delayed(const Duration(seconds: 3));
    await flutterTts.setLanguage("ur-PK");
    await flutterTts.speak("اپنی زبان منتخب کریں۔ اردو یا دو لسانی۔");
    await flutterTts.setLanguage("en-US"); // Reset to English
  }

  Future<void> _speakSelection(String language) async {
    if (!TTSPreference.enabled) return;

    if (language == "Urdu") {
      await flutterTts.setLanguage("en-US");
      await flutterTts.speak("You selected Urdu.");
      await flutterTts.setLanguage("ur-PK");
      await flutterTts.speak("آپ نے اردو منتخب کی ہے۔");
    } else if (language == "Bilingual") {
      await flutterTts.setLanguage("en-US");
      await flutterTts.speak("You selected Bilingual.");
      await flutterTts.setLanguage("ur-PK");
      await flutterTts.speak("آپ نے دو لسانی منتخب کی ہے۔");
    }
    await flutterTts.setLanguage("en-US");
  }

  Widget _buildLanguageOption(String language) {
    final bool isSelected = selectedLanguage == language;
    return GestureDetector(
      onTap: () async {
        setState(() {
          selectedLanguage = language;
          if (language == "Bilingual") {
            TTSPreference.enabled = true;
            TTSPreference.language = 'en'; // Default to English for Bilingual
          } else if (language == "Urdu") {
            TTSPreference.enabled = true;
            TTSPreference.language = 'ur';
          } else {
            TTSPreference.enabled = false;
            TTSPreference.language = 'en';
          }
        });
        await _speakSelection(language);
      },
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
                setState(() {
                  selectedLanguage = value!;
                });
                _speakSelection(language);
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
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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

            // Language Options
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildLanguageOption("Urdu"),
                    const SizedBox(height: 12),
                    _buildLanguageOption("Bilingual"),
                  ],
                ),
              ),
            ),

            // Save Button
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
                  onPressed: () async {
                    if (selectedLanguage == "Bilingual") {
                      TTSPreference.enabled = true;
                      TTSPreference.language = 'en';
                    } else if (selectedLanguage == "Urdu") {
                      TTSPreference.enabled = true;
                      TTSPreference.language = 'ur';
                    } else {
                      TTSPreference.enabled = false;
                      TTSPreference.language = 'en';
                    }
                    if (TTSPreference.enabled) {
                      if (TTSPreference.language == 'ur') {
                        await flutterTts.setLanguage("ur-PK");
                        await flutterTts.speak("آپ کی ترجیح محفوظ کی جا رہی ہے۔");
                        await flutterTts.setLanguage("en-US");
                      } else {
                        await flutterTts.setLanguage("en-US");
                        await flutterTts.speak("Saving your preference.");
                      }
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NameInputPage(),
                      ),
                    );
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
