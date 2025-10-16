import 'package:flutter/material.dart';
import 'package:nav_aif_fyp/pages/settings.dart';
import 'package:nav_aif_fyp/pages/profile.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:nav_aif_fyp/pages/lang.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  String get _instructionText => 'Welcome to your dashboard. Select a feature to continue. Say settings or profile to navigate.';

  @override
  void initState() {
    super.initState();
    _backPressCount = 0; // show the back button when screen opens
    _initTTS();
    _startListening();
  }

  Future<void> _initTTS() async {
    // Always speak in English
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.5);
    _tts.speak(_instructionText);
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) {
        if (val == "done" && !_isListening) {
          _startListening();
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
        localeId: 'en-US',
        onResult: (result) {
          String recognized = result.recognizedWords.toLowerCase().trim();
          _processCommand(recognized);
        },
      );
    } else {
      setState(() => _isListening = false);
    }
  }

  void _processCommand(String recognized) {
    debugPrint("🎙 Dashboard Recognized: $recognized");
    
    if (recognized.contains('settings')) {
      _speech.stop();
      setState(() => _isListening = false);
      _tts.speak('Opening settings.');
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        );
      });
    } else if (recognized.contains('profile')) {
      _speech.stop();
      setState(() => _isListening = false);
      _tts.speak('Opening profile.');
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
      });
    }
  }

  int? _hoveredIndex;
  int _backPressCount = 0;

  final List<Map<String, dynamic>> cards = [
    {
      'icon': Icons.camera_alt,
      'title': "Object Detection",
      'subtitle': "Identify objects in real-time"
    },
    {
      'icon': Icons.navigation,
      'title': "Navigation",
      'subtitle': "Turn-by-turn directions"
    },
    {
      'icon': Icons.route,
      'title': "Saved Routes",
      'subtitle': "Access your frequent routes"
    },
    {
      'icon': Icons.book,
      'title': "Guide",
      'subtitle': "Access complete guide"
    },
  ];


  Widget _buildCard(int index, IconData icon, String title, String subtitle) {
    final isHovered = _hoveredIndex == index;
    final borderColor = isHovered ? const Color(0xFF1349ec) : Colors.transparent;
    final iconColor = isHovered ? const Color(0xFF1349ec) : const Color(0xFF2563eb);
    final bgColor = isHovered ? const Color(0xFF1A202C) : Colors.white.withOpacity(0.05);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, bool active, BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (label == "Settings") {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          } else if (label == "Profile") {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: active ? const Color(0xFF2563eb) : Colors.white60,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: active ? const Color(0xFF2563eb) : Colors.white60,
                ),
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
      appBar: AppBar(
        leading: _backPressCount == 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context); // Go back once
                  setState(() {
                    _backPressCount = 1; // Hide button next rebuild
                  });
                },
              )
            : null,
        centerTitle: true,
        backgroundColor: const Color(0xFF0d1b2a),
        elevation: 0.5,
        title: const Text(
          "NavAI",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: List.generate(cards.length, (index) {
                  final card = cards[index];
                  return _buildCard(index, card['icon'], card['title'], card['subtitle']);
                }),
              ),
            ),
          ),
          // Voice command indicator
          if (_isListening)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mic, size: 16, color: Colors.green[300]),
                  const SizedBox(width: 8),
                  Text(
                    'Listening... Say "settings" or "profile"',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[300],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0d1b2a),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: Row(
          children: [
            _buildBottomNavItem(Icons.home, "Home", true, context),
            _buildBottomNavItem(Icons.settings, "Settings", false, context),
            _buildBottomNavItem(Icons.bookmark, "Saved Routes", false, context),
            _buildBottomNavItem(Icons.person, "Profile", false, context),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}
