import 'package:flutter/material.dart';
import 'package:nav_aif_fyp/pages/page_three.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:nav_aif_fyp/pages/lang.dart';

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

// Removed old StatelessWidget version of UseLocationPage

class UseLocationPage extends StatefulWidget {
  const UseLocationPage({super.key});

  @override
  State<UseLocationPage> createState() => _UseLocationPageState();
}

class _UseLocationPageState extends State<UseLocationPage> {
  final FlutterTts _tts = FlutterTts();

  String get _instructionText =>
      TTSPreference.language == 'ur'
          ? 'آپ اس وقت کہاں ہیں؟ براہ کرم اپنی لوکیشن منتخب کریں۔'
          : 'Where are you right now? Please select your location.';

  @override
  void initState() {
    super.initState();
    if (TTSPreference.enabled) {
      final lang = TTSPreference.language == 'ur' ? 'ur-PK' : 'en-US';
      _tts.setLanguage(lang);
      _tts.setSpeechRate(0.5);
      _tts.speak(_instructionText);
    }
  }
  int? _hoveredIndex;
  int? _selectedIndex;

  final List<Map<String, dynamic>> options = [
    {'icon': Icons.home, 'label': 'At Home'},
    {'icon': Icons.work, 'label': 'Workplace'},
    {'icon': Icons.school, 'label': 'College'},
    {'icon': Icons.account_balance, 'label': 'University'},
  ];

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
        title: const Text('Select Location'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _instructionText,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView.separated(
                itemCount: options.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = _selectedIndex == index;
                  return MouseRegion(
                    onEnter: (_) => setState(() => _hoveredIndex = index),
                    onExit: (_) => setState(() => _hoveredIndex = null),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected || _hoveredIndex == index
                              ? const Color(0xFF1A202C)
                              : const Color(0xFF1E232C),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF2563eb) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        child: Row(
                          children: [
                            Icon(option['icon'], color: isSelected ? const Color(0xFF2563eb) : Colors.white, size: 32),
                            const SizedBox(width: 20),
                            Text(
                              option['label'],
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
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const GuidePageBody()),
                      );
                    }
                  : null,
              child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
