
import 'package:flutter/material.dart';
import 'package:nav_aif_fyp/pages/page_four.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:nav_aif_fyp/pages/lang.dart';

class GuidePageBody extends StatefulWidget {
  const GuidePageBody({super.key});

  @override
  State<GuidePageBody> createState() => _GuidePageBodyState();
}

class _GuidePageBodyState extends State<GuidePageBody> {
  final FlutterTts _tts = FlutterTts();

  String get _instructionText => 'Select your preferred navigation mode.';

  @override
  void initState() {
    super.initState();
    // Always speak in English
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.5);
    _tts.speak(_instructionText);
  }
  int _selectedIndex = 1; // Default to 'Voice + Haptic'

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
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with Back Button and Skip
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () {
  Navigator.pop(context);
},

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
            // Header
            Text(
              _instructionText,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            // Options
            Padding(
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
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                      ),
                      if (index != _options.length - 1) const SizedBox(height: 16),
                    ],
                  );
                }),
              ),
            ),
            const Spacer(),
            // Continue Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: const Color(0xFF0d1b2a),
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
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DashboardScreen(),
                      ),
                    );
                  },
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
  _GuideOptionData({required this.icon, required this.title, required this.subtitle});
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
    final borderColor = isSelected ? const Color(0xFF1349ec) : Colors.transparent;
    final iconColor = isSelected ? const Color(0xFF1349ec) : const Color(0xFF9DA4B9);
    final bgColor = isSelected ? const Color(0xFF1A202C) : const Color(0xFF1E232C);

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
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF9DA4B9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(const NavAIGuidePage());
}

class NavAIGuidePage extends StatelessWidget {
  const NavAIGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NavAI',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFF0d1b2a),
        colorScheme: const ColorScheme.dark().copyWith(
          primary: const Color(0xFF2563eb),
          surface: const Color(0xFF0d1b2a),
        ),
        textTheme: GoogleFonts.spaceGroteskTextTheme(
          Theme.of(context).textTheme.apply(
                bodyColor: Colors.white,
                displayColor: Colors.white,
              ),
        ),
      ),
      home: const GuidePageBody(),
    );
  }
}
