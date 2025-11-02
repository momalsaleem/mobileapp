import 'package:flutter/material.dart';
import 'package:nav_aif_fyp/pages/settings.dart';
import 'package:nav_aif_fyp/pages/page_four.dart'; // Import DashboardScreen
import 'package:nav_aif_fyp/pages/lang.dart';
import 'package:nav_aif_fyp/services/preferences_manager.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController =
      TextEditingController(text: "Alex Doe");
  final FlutterTts _tts = FlutterTts();
  String _voiceId = "Female";
  String _language = "English";
  String _navMode = "Both";
  bool _isInitialized = false;

  final List<String> savedLocations = ["Home", "Work", "Grocery", "Doctor"];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() {
      _isInitialized = true;
    });
    
    await _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    await Lang.init();
    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    
    await _initTTS();
    
    // Load saved language preference
    final savedLang = await PreferencesManager.getLanguage();
    if (savedLang == 'ur') {
      setState(() {
        _language = "Urdu";
      });
    } else {
      setState(() {
        _language = "English";
      });
    }
    
    if (isVoiceModeEnabled) {
      _speakWelcome();
    }
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
  }

  Future<void> _speakWelcome() async {
    await _tts.speak('${Lang.t('welcome')} ${Lang.t('profile_title')}.');
    await _tts.awaitSpeakCompletion(true);
  }

  Widget _buildBottomNavItem(
      IconData icon, String label, bool active, BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (label == Lang.t('home_menu')) {
            // Navigate to DashboardScreen (PageFour)
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
              (route) => false,
            );
          } else if (label == Lang.t('settings')) {
            // Navigate to SettingsPage
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          } else if (label == Lang.t('profile')) {
            // Already on profile page, do nothing
          } else if (label == Lang.t('saved_routes')) {
            // TODO: Add navigation for saved routes if needed
            // For now, just show a message or do nothing
            debugPrint('Saved Routes tapped');
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
  void dispose() {
    _nameController.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                'Loading Profile...',
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
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: Text(Lang.t('profile_title')),
        backgroundColor: const Color(0xFF0d1b2a),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle(Lang.t('user_info')),
          _card(
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: Lang.t('name'),
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF2563eb)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _voiceId,
                  dropdownColor: const Color(0xFF1a2233),
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: Lang.t('voice_id'),
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF2563eb)),
                    ),
                  ),
                  items: ["Male", "Female", "System"]
                      .map((v) => DropdownMenuItem(
                            value: v,
                            child: Text(v, style: TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _voiceId = v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle(Lang.t('preferences')),
          _card(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _language,
                  dropdownColor: const Color(0xFF1a2233),
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: Lang.t('preferred_language'),
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF2563eb)),
                    ),
                  ),
                  items: ["English", "Urdu"]
                      .map((v) => DropdownMenuItem(
                            value: v,
                            child: Text(v, style: TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (v) async {
                    setState(() => _language = v!);
                    // Save language preference - simplified for English/Urdu only
                    if (v == "Urdu") {
                      await Lang.setLanguage('ur');
                      await PreferencesManager.setLanguage('ur');
                    } else {
                      await Lang.setLanguage('en');
                      await PreferencesManager.setLanguage('en');
                    }
                  },
                ),
                const SizedBox(height: 20),
                Text(Lang.t('preferred_nav_mode'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    )),
                const SizedBox(height: 8),
                ToggleButtons(
                  isSelected: ["Voice-only", "Haptic-only", "Both"]
                      .map((m) => _navMode == m)
                      .toList(),
                  onPressed: (index) {
                    setState(() {
                      _navMode = ["Voice-only", "Haptic-only", "Both"][index];
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  selectedColor: Colors.white,
                  fillColor: const Color(0xFF2563eb),
                  color: Colors.white60,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        Lang.t('voice_only_mode'),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        Lang.t('haptic_only_mode'),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        Lang.t('both_mode'),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle(Lang.t('saved_locations')),
          _card(
            child: Column(
              children: [
                for (var loc in savedLocations)
                  ListTile(
                    title: Text(loc, style: TextStyle(color: Colors.white)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white60),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white60),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563eb).withOpacity(0.2),
              foregroundColor: const Color(0xFF2563eb),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: const Color(0xFF2563eb).withOpacity(0.5)),
              ),
            ),
            onPressed: () {
              // TODO: Implement add location functionality
            },
            child: Text(Lang.t('add_location')),
          ),
        ],
      ),
      // Same footer as DashboardScreen
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0d1b2a),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: Row(
          children: [
            _buildBottomNavItem(Icons.home, Lang.t('home_menu'), false, context),
            _buildBottomNavItem(Icons.settings, Lang.t('settings'), false, context),
            _buildBottomNavItem(Icons.bookmark, Lang.t('saved_routes'), false, context),
            _buildBottomNavItem(Icons.person, Lang.t('profile'), true, context),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Card(
      color: const Color(0xFF1a2233),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
}