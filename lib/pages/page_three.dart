import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:nav_aif_fyp/pages/page_four.dart';

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

  final List<_GuideOptionData> _options = [
    _GuideOptionData(
      icon: Icons.mic,
      title: 'Voice Only',
      subtitle: 'Clear, spoken directions',
    ),
    _GuideOptionData(
      icon: Icons.vibration,
      title: 'Voice + Haptic',
      subtitle: 'Spoken directions with vibration cues',
    ),
    _GuideOptionData(
      icon: Icons.graphic_eq,
      title: 'Sound Cues + Voice',
      subtitle: 'Ambient sounds and spoken directions',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _speakOptions();
  }

  // ✅ Speak all options aloud in sequence with pauses
  Future<void> _speakOptions() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);

    // Step 1: Speak intro
    await _tts.speak(
        'Select your preferred navigation mode. Here are your available options.');
    await _tts.awaitSpeakCompletion(true);

    // Step 2: Speak each option (title + subtitle)
    for (var option in _options) {
      await _tts.speak('${option.title}. ${option.subtitle}.');
      await _tts.awaitSpeakCompletion(true);
    }

    // Step 3: Final instruction before listening
    await _tts.speak(
        'You can say Voice Only, Voice and Haptic, or Sound Cues with Voice to select your preferred mode.');
    await _tts.awaitSpeakCompletion(true);

    // Step 4: Start listening
    await _startListening();
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
        localeId: 'en-US',
        onResult: (result) {
          String recognized = result.recognizedWords.toLowerCase().trim();
          debugPrint('🎙 Recognized: $recognized');
          _processVoiceCommand(recognized);
        },
      );
    }
  }

  // ✅ Match recognized voice command
  void _processVoiceCommand(String recognized) {
    if (recognized.contains('voice only')) {
      _selectOption(0);
    } else if (recognized.contains('voice and haptic') ||
        recognized.contains('voice plus haptic')) {
      _selectOption(1);
    } else if (recognized.contains('sound cues') ||
        recognized.contains('sound and voice')) {
      _selectOption(2);
    }
  }

  // ✅ Select option and navigate
  Future<void> _selectOption(int index) async {
    _speech.stop();
    setState(() {
      _selectedIndex = index;
      _isListening = false;
    });

    await _tts.speak(
        'You selected ${_options[index].title}. Navigating to the next page.');
    await _tts.awaitSpeakCompletion(true);

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
                    onPressed: () {},
                    child: Text(
                      'Skip',
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
                'Select your preferred navigation mode.',
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
                          title: option.title,
                          subtitle: option.subtitle,
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
                    children: const [
                      Icon(Icons.mic, size: 18, color: Colors.greenAccent),
                      SizedBox(width: 8),
                      Text(
                        'Listening... Say "Voice Only" or "Voice and Haptic"',
                        style:
                            TextStyle(color: Colors.greenAccent, fontSize: 13),
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
                    'Continue',
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
  final String title;
  final String subtitle;
  const _GuideOptionData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class GuideOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const GuideOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
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
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle,
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
