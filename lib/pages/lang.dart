import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:nav_aif_fyp/pages/page_one.dart';
import 'package:nav_aif_fyp/services/preferences_manager.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
  bool _isSpeaking = false;
  bool _bilingualIntroComplete = false;
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeLanguagePage();
  }

  /// Initialize language page with voice system
  Future<void> _initializeLanguagePage() async {
    await _loadPreferences();
    await _initTTS();
    
    // Check if voice mode is enabled
    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    
    if (isVoiceModeEnabled) {
      // Speak bilingual introduction
      await _speakBilingualLanguageIntro();
      // Start listening after introduction
      await _startListening();
    } else {
      // Touch mode - just show status
      setState(() => _statusMessage = 'Touch mode active. Select your language.');
    }
  }

  Future<void> _loadPreferences() async {
    await Lang.init();
    final savedLanguage = await PreferencesManager.getLanguage();
    if (savedLanguage == 'ur') {
      setState(() => selectedLanguage = "Urdu");
    } else {
      setState(() => selectedLanguage = "English");
    }
  }

  Future<void> _initTTS() async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
    await flutterTts.awaitSpeakCompletion(true);

    flutterTts.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
    });

    flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });

    flutterTts.setErrorHandler((message) {
      debugPrint('TTS Error: $message');
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  /// Speak bilingual language introduction
  Future<void> _speakBilingualLanguageIntro() async {
    setState(() => _statusMessage = 'Speaking language options...');

    try {
      // === ENGLISH INTRODUCTION ===
      await flutterTts.setLanguage('en-US');
      await flutterTts.speak(
        'Select your preferred language. '
        'Say English for English interface, or Urdu for Urdu interface. '
        'You can also say: English, or Urdu.',
      );
      await flutterTts.awaitSpeakCompletion(true);
      
      // Pause between languages
      await Future.delayed(const Duration(milliseconds: 1000));

      // === URDU INTRODUCTION ===
      try {
        await flutterTts.setLanguage('ur-PK');
        await flutterTts.speak(
          'اپنی پسندیدہ زبان منتخب کریں۔ '
          'انگریزی انٹرفیس کے لیے انگلش کہیں، یا اردو انٹرفیس کے لیے اردو کہیں۔',
        );
        await flutterTts.awaitSpeakCompletion(true);
      } catch (e) {
        debugPrint('⚠️ Urdu TTS not available: $e');
      }

      // Pause before listening
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _bilingualIntroComplete = true;
        _statusMessage = 'Listening... Say "English" or "Urdu"';
      });

      debugPrint('✅ Language introduction complete');
    } catch (e) {
      debugPrint('❌ Error during language introduction: $e');
      setState(() => _statusMessage = 'Introduction error. Touch mode available.');
    }
  }

  /// Start listening for language selection
  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) {
        if (val == "done" && !_isListening) {
          // Restart listening after completion
          _startListening();
        }
      },
      onError: (val) {
        debugPrint('Speech Error: $val');
        setState(() => _isListening = false);
      },
    );

    if (available) {
      setState(() {
        _isListening = true;
        _statusMessage = 'Listening... Say "English" or "Urdu"';
      });
      
      _speech.listen(
        localeId: 'en-US', // Use English for detection
        onResult: (result) {
          if (result.finalResult) {
            String recognized = result.recognizedWords.toLowerCase().trim();
            if (recognized.isNotEmpty) {
              _processCommand(recognized);
            }
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
      );
    } else {
      setState(() => _isListening = false);
    }
  }

  /// Process language selection command
  void _processCommand(String recognized) async {
    debugPrint("🎙 Language Page Recognized: $recognized");
    
    bool commandMatched = false;
    
    // Check for language selection commands
    if (recognized.contains('english') || 
        recognized.contains('انگریزی') ||
        recognized.contains('انگلش')) {
      commandMatched = true;
      _selectLanguageAndNavigate("English");
    } else if (recognized.contains('urdu') || 
               recognized.contains('اردو')) {
      commandMatched = true;
      _selectLanguageAndNavigate("Urdu");
    }
    
    // If command not recognized, ask to repeat
    if (!commandMatched && recognized.length > 2) {
      await _askToRepeat();
    }
  }

  /// Ask user to repeat language selection
  Future<void> _askToRepeat() async {
    setState(() => _statusMessage = 'Command not understood. Please repeat.');
    
    // Haptic feedback for error
    HapticFeedback.vibrate();

    // Speak in both languages
    await flutterTts.setLanguage('en-US');
    await flutterTts.speak("I didn't catch that. Please say: English, or Urdu.");
    await flutterTts.awaitSpeakCompletion(true);

    try {
      await flutterTts.setLanguage('ur-PK');
      await flutterTts.speak('میں نے نہیں سنا۔ براہ کرم کہیں: انگلش، یا اردو۔');
      await flutterTts.awaitSpeakCompletion(true);
    } catch (e) {
      debugPrint('⚠️ Urdu repeat message not available');
    }

    // Resume listening
    await _startListening();
  }

  /// Select language and navigate to next page
  void _selectLanguageAndNavigate(String language) async {
    _speech.stop();
    setState(() {
      _isListening = false;
      selectedLanguage = language;
      _statusMessage = '$language selected';
    });

    // Haptic feedback for selection
    HapticFeedback.mediumImpact();

    // Save language preference
    if (language == "Urdu") {
      await Lang.setLanguage('ur');
      await PreferencesManager.setLanguage('ur');
    } else {
      await Lang.setLanguage('en');
      await PreferencesManager.setLanguage('en');
    }

    debugPrint('✅ Language saved: $language');

    // Speak confirmation
    await _speakSelection(language);

    // Navigate to next page
    Future.delayed(const Duration(seconds: 2)).then((_) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const NameInputPage()),
        );
      }
    });
  }

  Future<void> _speakSelection(String language) async {
    await flutterTts.setLanguage("en-US");
    if (language == "Urdu") {
      await flutterTts.speak("You selected Urdu language interface. All future pages will use Urdu.");
      await flutterTts.awaitSpeakCompletion(true);
      
      try {
        await flutterTts.setLanguage('ur-PK');
        await flutterTts.speak('آپ نے اردو زبان کا انٹرفیس منتخب کیا۔ تمام مستقبل کے صفحات اردو میں ہوں گے۔');
        await flutterTts.awaitSpeakCompletion(true);
      } catch (e) {
        debugPrint('⚠️ Urdu confirmation not available');
      }
    } else {
      await flutterTts.speak("You selected English language interface. All future pages will use English.");
      await flutterTts.awaitSpeakCompletion(true);
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
                  Expanded(
                    child: Text(
                      Lang.t('language'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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
                    _buildLanguageOption("English"),
                    const SizedBox(height: 20),
                    
                    // Status indicators
                    if (_isSpeaking)
                      _buildStatusIndicator(
                        icon: Icons.volume_up,
                        text: 'Speaking... / بول رہا ہے...',
                        color: Colors.blue,
                      ),
                    
                    if (_isListening)
                      _buildStatusIndicator(
                        icon: Icons.mic,
                        text: 'Listening... Say "English" or "Urdu"',
                        color: Colors.green,
                      ),
                    
                    if (!_isSpeaking && !_isListening)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _statusMessage,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9DA4B9),
                          ),
                          textAlign: TextAlign.center,
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
                  child: Text(
                    Lang.t('save'),
                    style: const TextStyle(
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

  Widget _buildStatusIndicator({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color.withOpacity(0.8)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    flutterTts.stop();
    super.dispose();
  }
}