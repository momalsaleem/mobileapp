import 'package:flutter/material.dart';
import 'package:nav_aif_fyp/pages/privacy.dart';
import 'package:nav_aif_fyp/pages/page_four.dart'; 
import 'package:nav_aif_fyp/pages/profile.dart'; 
import 'package:nav_aif_fyp/pages/lang.dart';
import 'package:nav_aif_fyp/services/preferences_manager.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isInitialized = false; // Add initialization flag

  @override
  void initState() {
    super.initState();
    _initializeApp(); // Use separate initialization method
  }

  // Separate async initialization that doesn't block UI rendering
  Future<void> _initializeApp() async {
    // Set initialized to true first to show UI immediately
    setState(() {
      _isInitialized = true;
    });
    
    await _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    await Lang.init();
    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    
    await _initTTS();
    
    // Only speak if voice mode is enabled - don't await this
    if (isVoiceModeEnabled) {
      _speakWelcome(); // Don't await - let it run in background
    }
    
    // Start listening for voice input
    _startListening();
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
    await _tts.speak(Lang.t('settings_welcome'));
    await _tts.awaitSpeakCompletion(true);
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
        localeId: Lang.speechLocaleId,
        onResult: (result) {
          String recognized = result.recognizedWords.toLowerCase().trim();
          if (recognized.isNotEmpty) {
            _processCommand(recognized);
          }
        },
      );
    } else {
      setState(() => _isListening = false);
    }
  }

  void _processCommand(String recognized) async {
    debugPrint("🎙 Settings Recognized: $recognized");
    
    await _speech.stop();
    setState(() => _isListening = false);
    
    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    bool commandMatched = false;
    
    if (recognized.contains('account') || recognized.contains('اکاؤنٹ')) {
      if (isVoiceModeEnabled) {
        await _tts.speak('${Lang.t('opening')} ${Lang.t('account')}.');
        await _tts.awaitSpeakCompletion(true);
      }
      commandMatched = true;
      // TODO: Navigate to account settings
    } else if (recognized.contains('privacy') || recognized.contains('پرائیویسی')) {
      if (isVoiceModeEnabled) {
        await _tts.speak('${Lang.t('opening')} ${Lang.t('privacy')}.');
        await _tts.awaitSpeakCompletion(true);
      }
      commandMatched = true;
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const PrivacyPage()),
        );
      }
    } else if (recognized.contains('notification') || recognized.contains('نوٹیفیکیشن')) {
      if (isVoiceModeEnabled) {
        await _tts.speak('${Lang.t('opening')} ${Lang.t('notifications')}.');
        await _tts.awaitSpeakCompletion(true);
      }
      commandMatched = true;
      // TODO: Navigate to notification settings
    } else if (recognized.contains('about') || recognized.contains('مزید معلومات')) {
      if (isVoiceModeEnabled) {
        await _tts.speak('${Lang.t('opening')} ${Lang.t('about')}.');
        await _tts.awaitSpeakCompletion(true);
      }
      commandMatched = true;
      // TODO: Show about dialog
    }
    
    // If command not recognized, ask to repeat politely
    if (!commandMatched && recognized.length > 2) {
      await _askToRepeat();
    } else if (!commandMatched) {
      if (isVoiceModeEnabled) {
        _startListening();
      }
    }
  }

  Future<void> _askToRepeat() async {
    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    if (isVoiceModeEnabled) {
      await _tts.speak(Lang.t('please_repeat'));
      await _tts.awaitSpeakCompletion(true);
      _startListening();
    }
  }

  Widget _buildBottomNavItem(
      IconData icon, String label, bool active, BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (label == Lang.t('home_menu')) {
            // Navigate to DashboardScreen
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
              (route) => false,
            );
          } else if (label == Lang.t('settings')) {
            // Already on settings page, do nothing
          } else if (label == Lang.t('saved_routes')) {
            // TODO: Add navigation for saved routes if needed
            debugPrint('Saved Routes tapped');
          } else if (label == Lang.t('profile')) {
            // Navigate to ProfileScreen
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
                'Loading Settings...',
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
        title: Text(Lang.t('settings_title')),
        backgroundColor: const Color(0xFF0d1b2a),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _settingsCard(
                  icon: Icons.person,
                  titleKey: 'account',
                  subtitleKey: 'account_desc',
                  onTap: () async {
                    await _speech.stop();
                    setState(() => _isListening = false);
                    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
                    if (isVoiceModeEnabled) {
                      await _tts.speak('${Lang.t('opening')} ${Lang.t('account')}.');
                    }
                    // TODO: Navigate to account settings
                  },
                ),
                _settingsCard(
                  icon: Icons.lock,
                  titleKey: 'privacy',
                  subtitleKey: 'privacy_desc',
                  onTap: () async {
                    await _speech.stop();
                    setState(() => _isListening = false);
                    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
                    if (isVoiceModeEnabled) {
                      await _tts.speak('${Lang.t('opening')} ${Lang.t('privacy')}.');
                      await _tts.awaitSpeakCompletion(true);
                    }
                    if (mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const PrivacyPage()),
                      );
                    }
                  },
                ),
                _settingsCard(
                  icon: Icons.notifications,
                  titleKey: 'notifications',
                  subtitleKey: 'notifications_desc',
                  onTap: () async {
                    await _speech.stop();
                    setState(() => _isListening = false);
                    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
                    if (isVoiceModeEnabled) {
                      await _tts.speak('${Lang.t('opening')} ${Lang.t('notifications')}.');
                    }
                    // TODO: Navigate to notification settings
                  },
                ),
                _settingsCard(
                  icon: Icons.info,
                  titleKey: 'about',
                  subtitleKey: 'about_desc',
                  onTap: () async {
                    await _speech.stop();
                    setState(() => _isListening = false);
                    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
                    if (isVoiceModeEnabled) {
                      await _tts.speak('${Lang.t('opening')} ${Lang.t('about')}.');
                    }
                    // TODO: Show about dialog
                  },
                ),
              ],
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
                    '${Lang.t('listening')} Say "account", "privacy", "notifications", or "about"',
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
      // Same footer as DashboardScreen and ProfileScreen
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0d1b2a),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: Row(
          children: [
            _buildBottomNavItem(Icons.home, Lang.t('home_menu'), false, context),
            _buildBottomNavItem(Icons.settings, Lang.t('settings'), true, context),
            _buildBottomNavItem(Icons.bookmark, Lang.t('saved_routes'), false, context),
            _buildBottomNavItem(Icons.person, Lang.t('profile'), false, context),
          ],
        ),
      ),
    );
  }

  Widget _settingsCard({
    required IconData icon,
    required String titleKey,
    required String subtitleKey,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2563eb).withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF2563eb)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Lang.t(titleKey),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Lang.t(subtitleKey),
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
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }
}