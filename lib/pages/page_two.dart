import 'package:flutter/material.dart';
import 'package:nav_aif_fyp/pages/page_three.dart';
import 'package:nav_aif_fyp/pages/lang.dart';
import 'package:nav_aif_fyp/services/preferences_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(const NavAIApp());
}

class NavAIApp extends StatelessWidget {
  const NavAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const UseLocationPage();
  }
}

class UseLocationPage extends StatefulWidget {
  const UseLocationPage({super.key});

  @override
  State<UseLocationPage> createState() => _UseLocationPageState();
}

class _UseLocationPageState extends State<UseLocationPage> {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  int? _hoveredIndex;
  int? _selectedIndex;

  final List<Map<String, dynamic>> options = [
    {'icon': Icons.home, 'label': 'home'},
    {'icon': Icons.work, 'label': 'work'},
    {'icon': Icons.school, 'label': 'college'},
    {'icon': Icons.account_balance, 'label': 'university'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    await Lang.init();
    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    
    await _initTTS();
    
    // Only speak if voice mode is enabled
    if (isVoiceModeEnabled) {
      await _speakOptions();
    }
    
    // Start listening for voice input
    await _startListening();
  }

  Future<void> _initTTS() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
  }

  // ✅ Speak instructions and all options clearly
  Future<void> _speakOptions() async {
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

    // Step 1: Introduction
    await _tts.speak(Lang.t('where_are_you'));
    await _tts.awaitSpeakCompletion(true);

    // Step 2: Speak each option in order
    for (var option in options) {
      await _tts.speak('${Lang.t(option['label'])}.');
      await _tts.awaitSpeakCompletion(true);
    }

    // Step 3: Final guidance
    await _tts.speak(
        'You can say Home, Work, College, or University to select your location.');
    await _tts.awaitSpeakCompletion(true);

    // Step 4: Start voice recognition after speaking all options
    await _startListening();
  }

  // ✅ Start listening continuously for user command
  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) {
        if (val == "done" && _isListening) {
          setState(() => _isListening = false);
          _startListening(); // Keep listening if user pauses
        }
      },
      onError: (val) {
        debugPrint('Speech Error: $val');
        setState(() => _isListening = false);
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
            _processCommand(recognized);
          }
        },
      );
    }
  }

  // ✅ Interpret recognized voice command
  void _processCommand(String recognized) async {
    int? selectedIndex;
    
    // Support both English and Urdu commands
    if (recognized.contains('home') || recognized.contains('گھر')) {
      selectedIndex = 0;
    } else if (recognized.contains('work') || recognized.contains('دفتر')) {
      selectedIndex = 1;
    } else if (recognized.contains('college') || recognized.contains('کالج')) {
      selectedIndex = 2;
    } else if (recognized.contains('university') || recognized.contains('یونیورسٹی')) {
      selectedIndex = 3;
    }

    if (selectedIndex != null) {
      _selectLocationAndNavigate(selectedIndex);
    } else if (recognized.length > 2) {
      // Command not recognized, ask to repeat
      await _askToRepeat();
    }
  }

  Future<void> _askToRepeat() async {
    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    if (isVoiceModeEnabled) {
      await _initTTS();
      final isUrdu = Lang.isUrdu;
      if (isUrdu) {
        try {
          await _tts.setLanguage('ur-PK');
        } catch (_) {
          await _tts.setLanguage('en-US');
        }
      }
      await _tts.speak(Lang.t('please_repeat'));
      await _tts.awaitSpeakCompletion(true);
    }
  }

  // ✅ Speak confirmation and navigate to next page
  Future<void> _selectLocationAndNavigate(int index) async {
    _speech.stop();
    setState(() {
      _isListening = false;
      _selectedIndex = index;
    });

    String location = Lang.t(options[index]['label']);

    await _tts
        .speak('You selected $location. Moving to navigation mode selection.');
    await _tts.awaitSpeakCompletion(true);

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const GuidePageBody()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1b2a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0d1b2a),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          Lang.t('select_location'),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              Lang.t('where_are_you'),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Listening indicator
            if (_isListening)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.mic, size: 16, color: Colors.greenAccent),
                    SizedBox(width: 8),
                    Text(
                      'Listening... Say "home", "work", "college", or "university"',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ],
                ),
              ),

            // List of options
            Expanded(
              child: ListView.separated(
                itemCount: options.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = _selectedIndex == index;
                  return MouseRegion(
                    onEnter: (_) => setState(() => _hoveredIndex = index),
                    onExit: (_) => setState(() => _hoveredIndex = null),
                    child: GestureDetector(
                      onTap: () {
                        _selectLocationAndNavigate(index);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected || _hoveredIndex == index
                              ? const Color(0xFF1A202C)
                              : const Color(0xFF1E232C),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF2563eb)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 16),
                        child: Row(
                          children: [
                            Icon(
                              option['icon'],
                              color: isSelected
                                  ? const Color(0xFF2563eb)
                                  : Colors.white,
                              size: 32,
                            ),
                            const SizedBox(width: 20),
                            Text(
                              Lang.t(option['label']),
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Continue Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563eb),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _selectedIndex != null
                  ? () {
                      _selectLocationAndNavigate(_selectedIndex!);
                    }
                  : null,
              child: Text(
                Lang.t('continue'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }
}
