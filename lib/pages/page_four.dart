import 'package:flutter/material.dart';
import 'package:nav_aif_fyp/pages/settings.dart';
import 'package:nav_aif_fyp/pages/profile.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:nav_aif_fyp/pages/lang.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FlutterTts _tts = FlutterTts();

  String get _instructionText =>
      TTSPreference.language == 'ur'
          ? 'ڈیش بورڈ میں خوش آمدید۔ جاری رکھنے کے لیے ایک فیچر منتخب کریں۔'
          : 'Welcome to your dashboard. Select a feature to continue.';

  @override
  void initState() {
    super.initState();
    _backPressCount = 0; // show the back button when screen opens
    if (TTSPreference.enabled) {
      final lang = TTSPreference.language == 'ur' ? 'ur-PK' : 'en-US';
      _tts.setLanguage(lang);
      _tts.setSpeechRate(0.5);
      _tts.speak(_instructionText);
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
      body: Padding(
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
}
