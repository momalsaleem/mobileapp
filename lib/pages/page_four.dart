import 'package:flutter/material.dart';
import 'package:nav_aif_fyp/pages/settings.dart';
import 'package:nav_aif_fyp/pages/profile.dart';
import 'package:nav_aif_fyp/pages/lang.dart';
import 'package:nav_aif_fyp/services/preferences_manager.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

// Import your camera page - replace with your actual camera page import
import 'package:nav_aif_fyp/pages/camera_page.dart'; // Adjust this import path
import 'package:nav_aif_fyp/pages/saved_routes_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  int? _hoveredIndex;
  int _backPressCount = 0;
  bool _isInitialized = false;

  String get _instructionText => Lang.t('dashboard_welcome');

  List<Map<String, dynamic>> _cards = [];
  
  void _buildCards() {
    _cards = [
      {
        'icon': Icons.camera_alt,
        'titleKey': "object_detection",
        'subtitleKey': "object_detection_desc",
        'onTap': _openObjectDetection, // Add onTap handler
      },
      {
        'icon': Icons.navigation,
        'titleKey': "navigation",
        'subtitleKey': "navigation_desc",
        'onTap': () => _handleCardTap('navigation'), // Add onTap handler
      },
      {
        'icon': Icons.route,
        'titleKey': "saved_routes",
        'subtitleKey': "saved_routes_desc",
        'onTap': () => _handleCardTap('saved_routes'), // Add onTap handler
      },
      {
        'icon': Icons.book, 
        'titleKey': "guide", 
        'subtitleKey': "guide_desc",
        'onTap': () => _handleCardTap('guide'), // Add onTap handler
      },
    ];
  }

  // Function to handle object detection card tap
  void _openObjectDetection() async {
    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    
    if (isVoiceModeEnabled) {
      await _tts.speak('${Lang.t('opening')} ${Lang.t('object_detection')}.');
    }
    
    // Navigate to camera page
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => CameraPage()), // Replace with your actual camera page
      );
    }
  }

  // Function to handle other card taps
  void _handleCardTap(String feature) async {
    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    
    if (isVoiceModeEnabled) {
      await _tts.speak('${Lang.t(feature)} ${Lang.t('selected')}.');
    }
    
    // TODO: Add navigation for other features
    if (feature == 'saved_routes') {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const SavedRoutesPage()),
        );
      }
      return;
    }
    debugPrint('$feature card tapped');
  }

  @override
  void initState() {
    super.initState();
    _buildCards();
    setState(() {
      _isInitialized = true;
    });
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _loadPreferences();
    await _initTTS();
    
    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    
    if (isVoiceModeEnabled) {
      _speakOptions();
    }
    
    _startListening();
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
  }

  Future<void> _speakOptions() async {
    await _tts.speak(_instructionText);
    await Future.delayed(const Duration(seconds: 6));

    for (var card in _cards) {
      await _tts.speak('${Lang.t(card['titleKey'])}. ${Lang.t(card['subtitleKey'])}');
      await Future.delayed(const Duration(seconds: 2));
    }

    await _tts.awaitSpeakCompletion(true);
  }

  void _startListening() {
    _speech.initialize(
      onStatus: (val) {
        if (val == "done" && !_isListening) {
          _startListening();
        }
      },
      onError: (val) {
        debugPrint('Speech Error: $val');
        setState(() => _isListening = false);
      },
    ).then((available) {
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
    });
  }

  void _processCommand(String recognized) async {
    debugPrint("🎙 Dashboard Recognized: $recognized");

    await _speech.stop();
    setState(() => _isListening = false);

    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    bool commandMatched = false;

    if (recognized.contains('settings') || recognized.contains('سیٹنگز')) {
      if (isVoiceModeEnabled) {
        await _tts.speak('${Lang.t('opening')} ${Lang.t('settings')}.');
        await _tts.awaitSpeakCompletion(true);
      }
      commandMatched = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SettingsPage()),
          );
        }
      });
    } else if (recognized.contains('profile') || recognized.contains('پروفائل')) {
      if (isVoiceModeEnabled) {
        await _tts.speak('${Lang.t('opening')} ${Lang.t('profile')}.');
        await _tts.awaitSpeakCompletion(true);
      }
      commandMatched = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        }
      });
    } else if (recognized.contains('object') || recognized.contains('آبجیکٹ')) {
      if (isVoiceModeEnabled) {
        await _tts.speak('${Lang.t('opening')} ${Lang.t('object_detection')}.');
        await _tts.awaitSpeakCompletion(true);
      }
      commandMatched = true;
      // Navigate to camera page when voice command is recognized
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => CameraPage()), // Replace with your actual camera page
          );
        }
      });
    } else if (recognized.contains('navigation') || recognized.contains('نیویگیشن')) {
      if (isVoiceModeEnabled) {
        await _tts.speak('${Lang.t('navigation')} ${Lang.t('selected')}.');
      }
      commandMatched = true;
    } else if (recognized.contains('route') || recognized.contains('راستہ')) {
      if (isVoiceModeEnabled) {
        await _tts.speak('${Lang.t('opening')} ${Lang.t('saved_routes')}.');
      }
      commandMatched = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SavedRoutesPage()),
          );
        }
      });
    } else if (recognized.contains('guide') || recognized.contains('گائیڈ')) {
      if (isVoiceModeEnabled) {
        await _tts.speak('${Lang.t('opening')} ${Lang.t('guide')}.');
      }
      commandMatched = true;
    }
    
    if (!commandMatched && recognized.length > 2) {
      await _askToRepeat();
    } else if (!commandMatched) {
      _startListening();
    }
  }

  Future<void> _askToRepeat() async {
    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    if (isVoiceModeEnabled) {
      await _tts.speak(Lang.t('not_understood'));
      await _tts.awaitSpeakCompletion(true);
      _startListening();
    }
  }

  Widget _buildCard(int index, IconData icon, String titleKey, String subtitleKey, VoidCallback onTap) {
    final isHovered = _hoveredIndex == index;
    final borderColor =
        isHovered ? const Color(0xFF1349ec) : Colors.transparent;
    final iconColor =
        isHovered ? const Color(0xFF1349ec) : const Color(0xFF2563eb);
    final bgColor =
        isHovered ? const Color(0xFF1A202C) : Colors.white.withOpacity(0.05);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        onTap: onTap,
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
      ),
    );
  }

  Widget _buildBottomNavItem(
      IconData icon, String label, bool active, BuildContext context) {
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
                'Loading Dashboard...',
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
        leading: _backPressCount == 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _backPressCount = 1;
                  });
                },
              )
            : null,
        centerTitle: true,
        backgroundColor: const Color(0xFF0d1b2a),
        elevation: 0.5,
        title: Text(
          Lang.t('navai'),
          style: const TextStyle(
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
                children: List.generate(_cards.length, (index) {
                  final card = _cards[index];
                  return _buildCard(
                    index, 
                    card['icon'], 
                    card['titleKey'], 
                    card['subtitleKey'],
                    card['onTap'], // Pass the onTap callback
                  );
                }),
              ),
            ),
          ),
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
                    '${Lang.t('listening')} Say "settings", "profile", or a feature name',
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
            _buildBottomNavItem(Icons.home, Lang.t('home_menu'), true, context),
            _buildBottomNavItem(Icons.settings, Lang.t('settings'), false, context),
            _buildBottomNavItem(Icons.bookmark, Lang.t('saved_routes'), false, context),
            _buildBottomNavItem(Icons.person, Lang.t('profile'), false, context),
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