import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:nav_aif_fyp/services/preferences_manager.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:nav_aif_fyp/utils/lang.dart';
import 'package:nav_aif_fyp/services/voice_manager.dart';
import 'package:nav_aif_fyp/services/route_tts_observer.dart';
import 'package:nav_aif_fyp/pages/page_four.dart';

export 'package:nav_aif_fyp/utils/lang.dart';

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

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> with RouteAwareTtsStopper {
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  String selectedLanguage = ""; // Start with no selection
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isNavigating = false;
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
      // Read the page content in both languages
      await _readPageContentBilingual();
      // Start listening after reading
      await _startListening();
    } else {
      // Touch mode - just show status
      setState(() => _statusMessage = 'Please select your preferred language.');
    }
  }

  Future<void> _loadPreferences() async {
    await Lang.init();
    // Don't pre-select a language - let user choose
    setState(() {
      selectedLanguage = "";
    });
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

  /// Read the page content in both English and Urdu
  Future<void> _readPageContentBilingual() async {
    try {
      setState(() {
        _isSpeaking = true;
        _statusMessage = 'Reading page content...';
      });
      
      // === ENGLISH PAGE CONTENT ===
      await flutterTts.setLanguage('en-US');
      await VoiceManager.safeSpeak(
        flutterTts,
        'Language Selection. Select Your Language. Please choose either English or Urdu to continue. '
        'Say English for English interface, or Urdu for Urdu interface. '
        'You can also tap the language buttons on screen. After selection, you will be automatically redirected to the dashboard.',
      );
      await VoiceManager.safeAwaitSpeakCompletion(flutterTts);
      
      // Pause between languages
      await Future.delayed(const Duration(milliseconds: 800));

      // === URDU PAGE CONTENT ===
      try {
        await flutterTts.setLanguage('ur-PK');
        await VoiceManager.safeSpeak(
          flutterTts,
          'زبان کی منتخب۔ اپنی زبان منتخب کریں۔ براہ کرم جاری رکھنے کے لیے انگلش یا اردو میں سے ایک منتخب کریں۔ '
          'انگریزی انٹرفیس کے لیے انگلش کہیں، یا اردو انٹرفیس کے لیے اردو کہیں۔ '
          'آپ سکرین پر زبان کے بٹنز پر ٹیپ بھی کر سکتے ہیں۔ منتخب کے بعد، آپ خود بخود ڈیش بورڈ پر منتقل ہو جائیں گے۔',
        );
        await VoiceManager.safeAwaitSpeakCompletion(flutterTts);
      } catch (e) {
        debugPrint('⚠ Urdu TTS not available, skipping: $e');
        // Fallback to English
        await flutterTts.setLanguage('en-US');
        await VoiceManager.safeSpeak(
          flutterTts,
          'Language selection page. Please select English or Urdu to continue.',
        );
        await VoiceManager.safeAwaitSpeakCompletion(flutterTts);
      }

      setState(() {
        _isSpeaking = false;
        _statusMessage = 'Listening... Say "English" or "Urdu" to select';
      });

      debugPrint('✅ Page content read in both languages');
    } catch (e) {
      debugPrint('❌ Error reading page content: $e');
      setState(() {
        _isSpeaking = false;
        _statusMessage = 'Please select your language to continue.';
      });
    }
  }

  /// Start listening for language selection
  Future<void> _startListening() async {
    // Only start listening if voice mode is enabled and no language is selected yet
    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    if (!isVoiceModeEnabled || selectedLanguage.isNotEmpty || _isNavigating) {
      return;
    }

    bool available = await _speech.initialize(
      onStatus: (val) {
        debugPrint('🎙️ Speech status: $val');
        if (val == "done" && !_isListening && mounted && !_isNavigating && selectedLanguage.isEmpty) {
          // Restart listening after completion if no selection made
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && !_isNavigating && selectedLanguage.isEmpty) _startListening();
          });
        }
      },
      onError: (val) {
        debugPrint('🎙️ Speech Error: $val');
        if (mounted) {
          setState(() {
            _isListening = false;
            _statusMessage = 'Listening error. Please use touch controls.';
          });
        }
      },
    );

    if (available && !_isNavigating && selectedLanguage.isEmpty) {
      if (mounted) {
        setState(() {
          _isListening = true;
          _statusMessage = 'Listening... Say "English" or "Urdu" to select';
        });
      }
      
      await _speech.listen(
        localeId: 'en-US',
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
        partialResults: false,
      );
    } else if (!available) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _statusMessage = 'Microphone not available. Please use touch controls.';
        });
      }
    }
  }

  /// Process language selection command in both English and Urdu
  void _processCommand(String recognized) async {
    debugPrint("🎙 Language Page Recognized: $recognized");
    
    // Stop listening while processing
    await _speech.stop();
    if (mounted) setState(() => _isListening = false);
    
    bool commandMatched = false;
    
    // ========== ENGLISH COMMANDS ==========
    if (recognized.contains('english') || 
        recognized.contains('inglish') ||
        recognized.contains('انگریزی') ||
        recognized == 'en' ||
        recognized == 'english' ||
        recognized == 'angrezi' ||
        recognized == 'انگلش') {
      commandMatched = true;
      await _selectLanguageAndNavigate("English");
    }
    // ========== URDU COMMANDS ==========
    else if (recognized.contains('urdu') || 
             recognized.contains('اردو') ||
             recognized.contains('urdu') ||
             recognized == 'urdu' ||
             recognized == 'اردو' ||
             recognized.contains('اردو زبان') ||
             recognized.contains('urdu language')) {
      commandMatched = true;
      await _selectLanguageAndNavigate("Urdu");
    }
    // ========== HELP/REPEAT COMMANDS ==========
    else if (recognized.contains('help') ||
             recognized.contains('مدد') ||
             recognized.contains('repeat') ||
             recognized.contains('دہرائیں') ||
             recognized.contains('again') ||
             recognized.contains('پھر کہیں') ||
             recognized.contains('what are my options') ||
             recognized.contains('کیا آپشنز ہیں')) {
      commandMatched = true;
      await _readPageContentBilingual(); // Read the page content again
      // Resume listening after reading
      if (mounted && !_isNavigating && selectedLanguage.isEmpty) await _startListening();
    }
    
    // If command not recognized, ask to repeat in both languages
    if (!commandMatched && recognized.length > 2 && !_isNavigating) {
      await _askToRepeatBilingual();
    } else if (!commandMatched && !_isNavigating) {
      // Restart listening for short/empty commands
      if (mounted && selectedLanguage.isEmpty) await _startListening();
    }
  }

  /// Ask user to repeat in both English and Urdu
  Future<void> _askToRepeatBilingual() async {
    if (mounted) {
      setState(() => _statusMessage = 'Command not understood. Please repeat.');
    }
    
    // Haptic feedback for error
    HapticFeedback.vibrate();

    // Only speak if voice mode is enabled
    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    if (!isVoiceModeEnabled) {
      if (mounted) {
        setState(() => _statusMessage = 'Please select language using buttons.');
      }
      return;
    }

    // Speak in English
    await flutterTts.setLanguage('en-US');
    await VoiceManager.safeSpeak(
      flutterTts,
      "I didn't understand that. Please say: English or Urdu to select your language."
    );
    await VoiceManager.safeAwaitSpeakCompletion(flutterTts);

    // Speak in Urdu
    try {
      await flutterTts.setLanguage('ur-PK');
      await VoiceManager.safeSpeak(
        flutterTts,
        'میں سمجھا نہیں۔ براہ کرم کہیں: انگلش یا اردو اپنی زبان منتخب کرنے کے لیے۔'
      );
      await VoiceManager.safeAwaitSpeakCompletion(flutterTts);
    } catch (e) {
      debugPrint('⚠️ Urdu repeat message not available');
    }

    // Resume listening
    if (mounted && !_isNavigating && selectedLanguage.isEmpty) await _startListening();
  }

  /// Select language and automatically navigate to dashboard
  Future<void> _selectLanguageAndNavigate(String language) async {
    if (_isNavigating) return; // Prevent multiple navigations
    
    _isNavigating = true;
    await _speech.stop();
    
    if (mounted) {
      setState(() {
        _isListening = false;
        selectedLanguage = language;
        _statusMessage = '$language selected. Redirecting to dashboard...';
      });
    }

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

    debugPrint('✅ Language selected: $language');

    // Speak confirmation in appropriate language
    await _speakSelectionConfirmation(language);

    // Navigate to DashboardScreen after a short delay
    Future.delayed(const Duration(seconds: 2)).then((_) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
          (Route<dynamic> route) => false,
        );
      }
    });
  }

  /// Speak language selection confirmation in both languages
  Future<void> _speakSelectionConfirmation(String language) async {
    // Only speak if voice mode is enabled
    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    if (!isVoiceModeEnabled) return;

    if (language == "Urdu") {
      // Confirm in Urdu
      try {
        await flutterTts.setLanguage('ur-PK');
        await VoiceManager.safeSpeak(
          flutterTts,
          'آپ نے اردو زبان کا انٹرفیس منتخب کیا۔ شکریہ۔ اب آپ کو ڈیش بورڈ پر منتقل کیا جا رہا ہے۔'
        );
        await VoiceManager.safeAwaitSpeakCompletion(flutterTts);
        
        // Also confirm in English for clarity
        await Future.delayed(const Duration(milliseconds: 500));
        await flutterTts.setLanguage('en-US');
        await VoiceManager.safeSpeak(
          flutterTts,
          "You selected Urdu interface. Thank you. Now redirecting you to the dashboard."
        );
        await VoiceManager.safeAwaitSpeakCompletion(flutterTts);
      } catch (e) {
        debugPrint('⚠️ Urdu confirmation not available, using English only');
        await flutterTts.setLanguage('en-US');
        await VoiceManager.safeSpeak(
          flutterTts,
          "You selected Urdu language interface. Now redirecting to dashboard."
        );
        await VoiceManager.safeAwaitSpeakCompletion(flutterTts);
      }
    } else {
      // Confirm in English
      await flutterTts.setLanguage('en-US');
      await VoiceManager.safeSpeak(
        flutterTts,
        "You selected English language interface. Thank you. Now redirecting you to the dashboard."
      );
      await VoiceManager.safeAwaitSpeakCompletion(flutterTts);
      
      // Also confirm in Urdu if possible
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        await flutterTts.setLanguage('ur-PK');
        await VoiceManager.safeSpeak(
          flutterTts,
          'آپ نے انگلش زبان کا انٹرفیس منتخب کیا۔ شکریہ۔ اب آپ کو ڈیش بورڈ پر منتقل کیا جا رہا ہے۔'
        );
        await VoiceManager.safeAwaitSpeakCompletion(flutterTts);
      } catch (e) {
        debugPrint('⚠️ Urdu confirmation not available for English selection');
      }
    }
  }

  /// Manual language selection (touch mode) with auto-navigation
  Future<void> _onLanguageSelected(String language) async {
    if (_isNavigating) return; // Prevent multiple navigations
    
    // Stop listening if active
    try {
      await _speech.stop();
    } catch (_) {}
    
    if (mounted) {
      setState(() {
        _isListening = false;
        selectedLanguage = language;
      });
    }
    
    await _selectLanguageAndNavigate(language);
  }

  Widget _buildLanguageOption(String language) {
    final bool isSelected = selectedLanguage == language;
    final bool isDisabled = _isNavigating || (selectedLanguage.isNotEmpty && !isSelected);
    
    return GestureDetector(
      onTap: isDisabled ? null : () => _onLanguageSelected(language),
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
              ? const Color(0xFF1349EC).withAlpha((0.2 * 255).round())
              : Colors.white.withAlpha((0.05 * 255).round()),
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: const Color(0xFF1349EC), width: 2)
                : Border.all(color: Colors.white.withAlpha((0.1 * 255).round()), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                language,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDisabled 
                    ? Colors.white.withAlpha((0.5 * 255).round())
                    : Colors.white,
                ),
              ),
              Radio<String>(
                value: language,
                groupValue: selectedLanguage,
                onChanged: isDisabled ? null : (value) {
                  if (value != null) _onLanguageSelected(value);
                },
                activeColor: const Color(0xFF1349EC),
              ),
            ],
          ),
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
                  // No back button - user must select language
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      'Language Selection',
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Welcome message (bilingual)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: Column(
                        children: [
                          Text(
                            'Select Your Language',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'اپنی زبان منتخب کریں',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withAlpha((0.7 * 255).round()),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Select a language to automatically continue',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withAlpha((0.6 * 255).round()),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          Text(
                            'خود بخود جاری رکھنے کے لیے ایک زبان منتخب کریں',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withAlpha((0.6 * 255).round()),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Language options with bilingual labels
                    Column(
                      children: [
                        _buildLanguageOption("Urdu"),
                        const SizedBox(height: 16),
                        _buildLanguageOption("English"),
                      ],
                    ),
                    const SizedBox(height: 30),
                    
                    // Selection status and loading indicator
                    if (selectedLanguage.isNotEmpty && !_isNavigating)
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha((0.2 * 255).round()),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, color: Colors.green.withAlpha((0.9 * 255).round())),
                                const SizedBox(width: 10),
                                Text(
                                  'Selected: $selectedLanguage',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.withAlpha((0.9 * 255).round()),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1349EC)),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Redirecting to dashboard...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withAlpha((0.7 * 255).round()),
                            ),
                          ),
                          Text(
                            'ڈیش بورڈ پر منتقل ہو رہا ہے...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withAlpha((0.7 * 255).round()),
                            ),
                          ),
                        ],
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Voice mode status indicators
                    if (_isSpeaking)
                      _buildStatusIndicator(
                        icon: Icons.volume_up,
                        text: 'Reading page... / صفحہ پڑھ رہا ہے...',
                        color: Colors.blue,
                      ),
                    
                    if (_isListening)
                      _buildStatusIndicator(
                        icon: Icons.mic,
                        text: 'Listening... / سن رہا ہے...',
                        color: Colors.green,
                      ),
                    
                    if (!_isSpeaking && !_isListening && selectedLanguage.isEmpty && !_isNavigating)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Column(
                          children: [
                            Text(
                              _statusMessage,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF9DA4B9),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            // Bilingual hint
                            Text(
                              'Select a language to continue automatically',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withAlpha((0.5 * 255).round()),
                              ),
                            ),
                            Text(
                              'خود بخود جاری رکھنے کے لیے ایک زبان منتخب کریں',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withAlpha((0.5 * 255).round()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Voice hint (bilingual)
                    if (_isListening && selectedLanguage.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Column(
                          children: [
                            Text(
                              'Say: "English" or "Urdu" to select',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withAlpha((0.6 * 255).round()),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'منتخب کرنے کے لیے کہیں: "انگلش" یا "اردو"',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withAlpha((0.6 * 255).round()),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color.withAlpha((0.2 * 255).round()),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color.withAlpha((0.9 * 255).round())),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color.withAlpha((0.9 * 255).round()),
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
    try {
      VoiceManager.safeStopListening(_speech);
    } catch (_) {}
    try {
      flutterTts.stop();
    } catch (_) {}
    super.dispose();
  }

  @override
  Future<void> stopTtsAndListening() async {
    try {
      await VoiceManager.safeStopListening(_speech);
    } catch (_) {}
    try {
      await flutterTts.stop();
    } catch (_) {}
  }
}