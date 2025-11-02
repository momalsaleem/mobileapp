import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:nav_aif_fyp/pages/page_four.dart';
import 'package:nav_aif_fyp/pages/lang.dart';
import 'package:nav_aif_fyp/services/preferences_manager.dart';

class GuidePageBody extends StatefulWidget {
  const GuidePageBody({super.key});

  @override
  State<GuidePageBody> createState() => _GuidePageBodyState();
}

class _GuidePageBodyState extends State<GuidePageBody> {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  int _selectedIndex = 1;
  bool _isListening = false;
  bool _isInitialized = false; // Add this flag

  List<_GuideOptionData> _options = [];
  
  void _buildOptions() {
    _options = [
      _GuideOptionData(
        icon: Icons.mic,
        titleKey: 'voice_only',
        subtitleKey: 'voice_only_desc',
      ),
      _GuideOptionData(
        icon: Icons.vibration,
        titleKey: 'voice_haptic',
        subtitleKey: 'voice_haptic_desc',
      ),
      _GuideOptionData(
        icon: Icons.graphic_eq,
        titleKey: 'sound_voice',
        subtitleKey: 'sound_voice_desc',
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _buildOptions(); // Build options immediately
    setState(() {
      _isInitialized = true; // Mark as initialized for UI
    });
    _initializeApp(); // Separate initialization that doesn't block UI
  }

  // Separate async initialization that doesn't block UI rendering
  Future<void> _initializeApp() async {
    await _loadPreferences();
    await _initTTS();
    
    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    
    // Only speak if voice mode is enabled - don't await this to prevent blocking
    if (isVoiceModeEnabled) {
      _speakOptions(); // Don't await - let it run in background
    }
    
    // Start listening for voice input
    await _startListening();
  }

  Future<void> _loadPreferences() async {
    await Lang.init();
  }

  Future<void> _initTTS() async {
    final isUrdu = Lang.isUrdu;
    if (isUrdu) {
      try {
        await _tts.setLanguage('ur-PK');
      } catch (_) {
        await _tts.setLanguage('en-US');
      }
    } else {
      await _tts.setLanguage('en-US');
    }
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
  }

  // ✅ Speak all options aloud in sequence with pauses - NO AWAIT in call chain
  Future<void> _speakOptions() async {
    // Step 1: Speak intro
    await _tts.speak(Lang.t('nav_mode_intro'));
    await _tts.awaitSpeakCompletion(true);

    // Step 2: Speak each option (title + subtitle)
    for (var option in _options) {
      await _tts.speak('${Lang.t(option.titleKey)}. ${Lang.t(option.subtitleKey)}.');
      await _tts.awaitSpeakCompletion(true);
    }

    // Step 3: Final instruction before listening
    await _tts.speak(
        'You can say Voice Only, Voice and Haptic, or Sound Cues with Voice to select your preferred mode.');
    await _tts.awaitSpeakCompletion(true);
  }

  // ✅ Start listening for voice commands
  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) {
        if (val == "done" && _isListening) {
          setState(() => _isListening = false);
          _startListening(); // keep listening if user pauses
        }
      },
      onError: (val) {
        debugPrint('Speech Error: $val');
      },
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        localeId: Lang.speechLocaleId,
        onResult: (result) {
          String recognized = result.recognizedWords.toLowerCase().trim();
          if (recognized.isNotEmpty) {
            debugPrint('🎙 Recognized: $recognized');
            _processVoiceCommand(recognized);
          }
        },
      );
    }
  }

  // ✅ Match recognized voice command
  void _processVoiceCommand(String recognized) async {
    bool commandMatched = false;
    
    if (recognized.contains('voice only') || recognized.contains('صرف آواز')) {
      _selectOption(0);
      commandMatched = true;
    } else if (recognized.contains('voice and haptic') ||
        recognized.contains('voice plus haptic') ||
        recognized.contains('آواز اور ہیپٹک')) {
      _selectOption(1);
      commandMatched = true;
    } else if (recognized.contains('sound cues') ||
        recognized.contains('sound and voice') ||
        recognized.contains('آواز کے اشارے')) {
      _selectOption(2);
      commandMatched = true;
    }
    
    // If command not recognized, ask to repeat
    if (!commandMatched && recognized.length > 2) {
      await _askToRepeat();
    }
  }

  Future<void> _askToRepeat() async {
    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    if (isVoiceModeEnabled) {
      await _tts.speak(Lang.t('please_repeat'));
      await _tts.awaitSpeakCompletion(true);
    }
  }

  // ✅ Select option and navigate
  Future<void> _selectOption(int index) async {
    _speech.stop();
    setState(() {
      _selectedIndex = index;
      _isListening = false;
    });

    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    if (isVoiceModeEnabled) {
      await _tts.speak(
          '${Lang.t('selected_nav_mode')} ${Lang.t(_options[index].titleKey)}. ${Lang.t('navigating_next')}');
      await _tts.awaitSpeakCompletion(true);
    }

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator if not initialized yet
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFF0d1b2a),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1349EC)),
              ),
              SizedBox(height: 20),
              Text(
                'Loading...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0d1b2a),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const DashboardScreen()),
                      );
                    },
                    child: Text(
                      Lang.t('skip'),
                      style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFF9DA4B9),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                Lang.t('select_nav_mode'),
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 32),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: List.generate(_options.length, (index) {
                    final option = _options[index];
                    return Column(
                      children: [
                        GuideOption(
                          icon: option.icon,
                          titleKey: option.titleKey,
                          subtitleKey: option.subtitleKey,
                          isSelected: _selectedIndex == index,
                          onTap: () => _selectOption(index),
                        ),
                        if (index != _options.length - 1)
                          const SizedBox(height: 16),
                      ],
                    );
                  }),
                ),
              ),
            ),

            // Listening indicator
            if (_isListening)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.greenAccent, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.mic, size: 18, color: Colors.greenAccent),
                      const SizedBox(width: 8),
                      Text(
                        '${Lang.t('listening')} Say "Voice Only" or "Voice and Haptic"',
                        style:
                            const TextStyle(color: Colors.greenAccent, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),

            // Continue button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1349EC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => _selectOption(_selectedIndex),
                  child: Text(
                    Lang.t('continue'),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

class _GuideOptionData {
  final IconData icon;
  final String titleKey;
  final String subtitleKey;
  const _GuideOptionData({
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
  });
}

class GuideOption extends StatelessWidget {
  final IconData icon;
  final String titleKey;
  final String subtitleKey;
  final bool isSelected;
  final VoidCallback onTap;

  const GuideOption({
    super.key,
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isSelected ? const Color(0xFF1349ec) : Colors.transparent;
    final iconColor =
        isSelected ? const Color(0xFF1349ec) : const Color(0xFF9DA4B9);
    final bgColor =
        isSelected ? const Color(0xFF1A202C) : const Color(0xFF1E232C);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: iconColor),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Lang.t(titleKey),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(Lang.t(subtitleKey),
                      style: const TextStyle(
                          color: Color(0xFF9DA4B9), fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}