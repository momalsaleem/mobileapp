import 'package:flutter/material.dart';
import 'package:nav_aif_fyp/pages/settings.dart';
import 'package:nav_aif_fyp/pages/profile.dart';
import 'package:nav_aif_fyp/pages/lang.dart';
import 'package:nav_aif_fyp/services/preferences_manager.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:nav_aif_fyp/services/voice_manager.dart';

import 'package:nav_aif_fyp/pages/camera_page.dart'; 
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

  String get _instructionText => Lang.t('dashboard_welcome');

  List<Map<String, dynamic>> _cards = [];
  
  void _buildCards() {
    _cards = [
      {
        'icon': Icons.camera_alt,
        'titleKey': "object_detection",
        'subtitleKey': "object_detection_desc",
        'onTap': _openObjectDetection,
      },
      {
        'icon': Icons.navigation,
        'titleKey': "navigation",
        'subtitleKey': "navigation_desc",
        'onTap': () => _handleCardTap('navigation'),
      },
      {
        'icon': Icons.route,
        'titleKey': "saved_routes",
        'subtitleKey': "saved_routes_desc",
        'onTap': () => _handleCardTap('saved_routes'), 
      },
      {
        'icon': Icons.book, 
        'titleKey': "guide", 
        'subtitleKey': "guide_desc",
        'onTap': () => _handleCardTap('guide'), 
      },
    ];
  }

  void _openObjectDetection() async {
    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    
    if (isVoiceModeEnabled) {
      await _initTTS();
      await VoiceManager.safeSpeak(_tts, '${Lang.t('opening')} ${Lang.t('object_detection')}.');
    }
    
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => CameraPage()),
      );
    }
  }

  void _handleCardTap(String feature) async {
    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    
    if (isVoiceModeEnabled) {
      await _initTTS();
      await VoiceManager.safeSpeak(_tts, '${Lang.t(feature)} ${Lang.t('selected')}.');
    }
    
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
    // Build UI immediately, initialize voice in background without blocking UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeVoiceInBackground();
    });
  }

  Future<void> _initializeVoiceInBackground() async {
    try {
      await Lang.init();
      final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
      await _initTTS();

      if (isVoiceModeEnabled) {
        await _speakOptions();
        await _startListening();
      }
    } catch (e) {
      debugPrint('Background voice init error: $e');
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
    // Tweak for clearer speech
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    try {
      await _tts.setVolume(1.0);
    } catch (_) {}
  }

  Future<void> _speakOptions() async {
    await VoiceManager.safeSpeak(_tts, _instructionText);

    // Speak each card's title and subtitle
    for (var card in _cards) {
      await VoiceManager.safeSpeak(
          _tts, '${Lang.t(card['titleKey'])}. ${Lang.t(card['subtitleKey'])}');
    }
  }

  Future<void> _startListening() async {
    // Ensure microphone permission is available
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      debugPrint('Microphone permission not granted (dashboard)');
      setState(() => _isListening = false);
      return;
    }

    final available = await VoiceManager.safeInitializeSpeech(
      _speech,
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
      await VoiceManager.safeListen(
        _speech,
        localeId: Lang.speechLocaleId,
        onResult: (result) {
          String recognized = (result.recognizedWords ?? '').toString().toLowerCase().trim();
          if (recognized.isNotEmpty) {
            _processCommand(recognized);
          }
        },
      );
    } else {
      setState(() => _isListening = false);
    }
  }

  Future<void> _processCommand(String recognized) async {
    debugPrint("🎙 Dashboard Recognized: $recognized");
    await VoiceManager.safeStopListening(_speech);
    setState(() => _isListening = false);

    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    bool commandMatched = false;

    // Process commands without awaiting long operations
    if (recognized.contains('settings') || recognized.contains('سیٹنگز')) {
      commandMatched = true;
      if (isVoiceModeEnabled) {
        await _initTTS();
        await VoiceManager.safeSpeak(_tts, '${Lang.t('opening')} ${Lang.t('settings')}.');
      }
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SettingsPage()),
          );
        }
      });
    } else if (recognized.contains('profile') || recognized.contains('پروفائل')) {
      commandMatched = true;
      if (isVoiceModeEnabled) {
        await _initTTS();
        await VoiceManager.safeSpeak(_tts, '${Lang.t('opening')} ${Lang.t('profile')}.');
      }
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        }
      });
    } else if (recognized.contains('object') || recognized.contains('آبجیکٹ')) {
      commandMatched = true;
      if (isVoiceModeEnabled) {
        await _initTTS();
        await VoiceManager.safeSpeak(_tts, '${Lang.t('opening')} ${Lang.t('object_detection')}.');
      }
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => CameraPage()),
          );
        }
      });
    } else if (recognized.contains('navigation') || recognized.contains('نیویگیشن')) {
      commandMatched = true;
      if (isVoiceModeEnabled) {
        await _initTTS();
        VoiceManager.safeSpeak(_tts, '${Lang.t('navigation')} ${Lang.t('selected')}.');
      }
      _startListening();
    } else if (recognized.contains('route') || recognized.contains('راستہ')) {
      commandMatched = true;
      if (isVoiceModeEnabled) {
        await _initTTS();
        VoiceManager.safeSpeak(_tts, '${Lang.t('opening')} ${Lang.t('saved_routes')}.');
      }
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SavedRoutesPage()),
          );
        }
      });
    } else if (recognized.contains('guide') || recognized.contains('گائیڈ')) {
      commandMatched = true;
      if (isVoiceModeEnabled) {
        await _initTTS();
        VoiceManager.safeSpeak(_tts, '${Lang.t('opening')} ${Lang.t('guide')}.');
      }
      _startListening();
    }
    
    if (!commandMatched && recognized.length > 2) {
      _askToRepeat();
    } else if (!commandMatched) {
      _startListening();
    }
  }

  void _askToRepeat() async {
    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    if (isVoiceModeEnabled) {
      await _initTTS();
      VoiceManager.safeSpeak(_tts, Lang.t('not_understood'));
      _startListening();
    }
  }

  Widget _buildCard(int index, IconData icon, String titleKey, String subtitleKey, VoidCallback onTap) {
    final isHovered = _hoveredIndex == index;
    final borderColor = isHovered ? const Color(0xFF1349ec) : Colors.transparent;
    final iconColor = isHovered ? const Color(0xFF1349ec) : const Color(0xFF2563eb);
    final bgColor = isHovered ? const Color(0xFF1A202C) : Colors.white.withOpacity(0.05);

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
    // Show loading only for a very brief moment if needed
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
                    card['onTap'],
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
                    '${Lang.t('listening')} ${Lang.t('dashboard_voice_hint')}',
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
    VoiceManager.safeStopListening(_speech);
    _tts.stop();
    super.dispose();
  }
}