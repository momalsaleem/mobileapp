import 'package:flutter/material.dart';
import 'package:nav_aif_fyp/pages/settings.dart';
import 'package:nav_aif_fyp/pages/profile.dart';
import 'package:nav_aif_fyp/pages/lang.dart';
import 'package:nav_aif_fyp/services/preferences_manager.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:nav_aif_fyp/services/voice_manager.dart';
import 'package:nav_aif_fyp/services/route_tts_observer.dart';
import 'package:nav_aif_fyp/pages/camera_page.dart';
import 'package:nav_aif_fyp/pages/saved_routes_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with RouteAwareTtsStopper {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isSpeaking = false;
  int? _hoveredIndex;
  int _backPressCount = 0;

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
      await _speakMessage('${Lang.t('opening')} ${Lang.t('object_detection')}.');
    }
    
    try {
      await VoiceManager.safeStopListening(_speech);
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}

    if (mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const CameraPage()),
      );
    }
  }

  void _handleCardTap(String feature) async {
    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    
    if (isVoiceModeEnabled) {
      await _initTTS();
      await _speakMessage('${Lang.t(feature)} ${Lang.t('selected')}.');
    }
    
    if (feature == 'saved_routes') {
      try {
        await VoiceManager.safeStopListening(_speech);
      } catch (_) {}
      try {
        await _tts.stop();
      } catch (_) {}
      if (mounted) {
        await Navigator.of(context).push(
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeVoiceSystem();
    });
  }

  @override
  void dispose() {
    try {
      VoiceManager.safeStopListening(_speech);
    } catch (_) {}
    try {
      _tts.stop();
    } catch (_) {}
    super.dispose();
  }

  @override
  Future<void> stopTtsAndListening() async {
    try {
      await VoiceManager.safeStopListening(_speech);
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
  }

  /// Initialize voice system with selected language
  Future<void> _initializeVoiceSystem() async {
    try {
      await Lang.init();
      final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
      await _initTTS();

      if (isVoiceModeEnabled) {
        await _speakWelcomeMessage();
        await _startListening();
      }
    } catch (e) {
      debugPrint('Voice system initialization error: $e');
    }
  }

  /// Initialize TTS with the selected language from lang.dart
  Future<void> _initTTS() async {
    final isUrdu = Lang.isUrdu;
    if (isUrdu) {
      try {
        await _tts.setLanguage('ur-PK');
        debugPrint('✅ TTS language set to Urdu');
      } catch (_) {
        await _tts.setLanguage('en-US');
        debugPrint('⚠️ Urdu TTS not available, using English');
      }
    } else {
      await _tts.setLanguage('en-US');
      debugPrint('✅ TTS language set to English');
    }
    
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true);

    _tts.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
    });

    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });

    _tts.setErrorHandler((message) {
      debugPrint('TTS Error: $message');
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  /// Speak a message in the selected language
  Future<void> _speakMessage(String text) async {
    try {
      await VoiceManager.safeSpeak(_tts, text);
      await _tts.awaitSpeakCompletion(true);
    } catch (e) {
      debugPrint('Error speaking message: $e');
    }
  }

  /// Speak welcome message in the selected language
  Future<void> _speakWelcomeMessage() async {
    try {
      setState(() => _isSpeaking = true);
      
      final isUrdu = Lang.isUrdu;
      
      if (isUrdu) {
        // Urdu welcome message
        await _speakMessage(
          'نوے اے آئی ڈیش بورڈ پر خوش آمدید۔ '
          'آپ کے پاس درج ذیل آپشنز دستیاب ہیں: '
          'آبجیکٹ ڈیٹیکشن کیمرہ استعمال کر کے اشیا کی شناخت کے لیے۔ '
          'نیویگیشن - مختلف مقامات پر راستہ تلاش کرنے کے لیے۔ '
          'محفوظ شدہ راستے - پہلے سے محفوظ شدہ راستوں کو دیکھنے کے لیے۔ '
          'گائیڈ - ایپلیکیشن استعمال کرنے کے طریقے جاننے کے لیے۔ '
          'آپ کسی بھی آپشن کو منتخب کرنے کے لیے بول سکتے ہیں یا ٹیپ کر سکتے ہیں۔'
        );
      } else {
        // English welcome message
        await _speakMessage(
          'Welcome to Nav AI Dashboard. '
          'The following options are available: '
          'Object detection for identifying objects using camera. '
          'Navigation for finding routes to different locations. '
          'Saved routes to view previously saved paths. '
          'Guide to learn how to use the application. '
          'You can speak or tap to select any option.'
        );
      }
      
      setState(() => _isSpeaking = false);
      
    } catch (e) {
      debugPrint('Error during welcome message: $e');
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  Future<void> _startListening() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      debugPrint('Microphone permission not granted');
      if (mounted) setState(() => _isListening = false);
      return;
    }

    bool available = await _speech.initialize(
      onStatus: (val) {
        debugPrint('🎙️ Speech status: $val');
        if (val == "done" && !_isListening && mounted) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) _startListening();
          });
        }
      },
      onError: (val) {
        debugPrint('🎙️ Speech Error: $val');
        if (mounted) setState(() => _isListening = false);
      },
    );

    if (available) {
      if (mounted) {
        setState(() => _isListening = true);
      }
      
      await _speech.listen(
        localeId: Lang.speechLocaleId,
        onResult: (result) {
          if (result.finalResult) {
            String recognized = result.recognizedWords.toLowerCase().trim();
            if (recognized.isNotEmpty) {
              _processCommand(recognized);
            }
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: false,
      );
    } else {
      if (mounted) setState(() => _isListening = false);
    }
  }

  Future<void> _processCommand(String recognized) async {
    debugPrint("🎙 Dashboard Recognized: $recognized");
    
    await _speech.stop();
    if (mounted) setState(() => _isListening = false);
    
    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    bool commandMatched = false;

    // ========== COMMAND PROCESSING ==========
    
    // OBJECT DETECTION
    if (recognized.contains('object') || 
        recognized.contains('آبجیکٹ') ||
        recognized.contains('camera') ||
        recognized.contains('کیمرہ')) {
      commandMatched = true;
      if (isVoiceModeEnabled) {
        await _initTTS();
        await _speakMessage('${Lang.t('opening')} ${Lang.t('object_detection')}.');
      }
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CameraPage()),
          );
        }
      });
    }
    // SETTINGS
    else if (recognized.contains('settings') || 
             recognized.contains('سیٹنگز')) {
      commandMatched = true;
      if (isVoiceModeEnabled) {
        await _initTTS();
        await _speakMessage('${Lang.t('opening')} ${Lang.t('settings')}.');
      }
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SettingsPage()),
          );
        }
      });
    }
    // PROFILE
    else if (recognized.contains('profile') || 
             recognized.contains('پروفائل')) {
      commandMatched = true;
      if (isVoiceModeEnabled) {
        await _initTTS();
        await _speakMessage('${Lang.t('opening')} ${Lang.t('profile')}.');
      }
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        }
      });
    }
    // NAVIGATION
    else if (recognized.contains('navigation') || 
             recognized.contains('نیویگیشن')) {
      commandMatched = true;
      if (isVoiceModeEnabled) {
        await _initTTS();
        await _speakMessage('${Lang.t('navigation')} ${Lang.t('selected')}.');
      }
      if (mounted) await _startListening();
    }
    // SAVED ROUTES
    else if (recognized.contains('saved') || 
             recognized.contains('محفوظ') ||
             recognized.contains('route') ||
             recognized.contains('راستہ')) {
      commandMatched = true;
      if (isVoiceModeEnabled) {
        await _initTTS();
        await _speakMessage('${Lang.t('opening')} ${Lang.t('saved_routes')}.');
      }
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SavedRoutesPage()),
          );
        }
      });
    }
    // GUIDE
    else if (recognized.contains('guide') || 
             recognized.contains('گائیڈ')) {
      commandMatched = true;
      if (isVoiceModeEnabled) {
        await _initTTS();
        await _speakMessage('${Lang.t('guide')} ${Lang.t('selected')}.');
      }
      if (mounted) await _startListening();
    }
    // HELP/REPEAT
    else if (recognized.contains('help') ||
             recognized.contains('مدد') ||
             recognized.contains('repeat') ||
             recognized.contains('دہرائیں')) {
      commandMatched = true;
      await _askToRepeat();
    }
    
    if (!commandMatched && recognized.length > 2) {
      await _askToRepeat();
    } else if (!commandMatched) {
      if (mounted) await _startListening();
    }
  }

  Future<void> _askToRepeat() async {
    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    if (!isVoiceModeEnabled) return;

    await _initTTS();
    await _speakMessage(Lang.t('not_understood'));
    
    if (mounted) await _startListening();
  }

  Widget _buildCard(int index, IconData icon, String titleKey, String subtitleKey, VoidCallback onTap) {
    final isHovered = _hoveredIndex == index;
    final borderColor = isHovered ? const Color(0xFF1349ec) : Colors.transparent;
    final iconColor = isHovered ? const Color(0xFF1349ec) : const Color(0xFF2563eb);
    final bgColor = isHovered ? const Color(0xFF1A202C) : Colors.white.withAlpha((0.05 * 255).round());

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
                  color: iconColor.withAlpha((0.25 * 255).round()),
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
                        color: Colors.white.withAlpha((0.6 * 255).round()),
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
          if (label == Lang.t('settings')) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          } else if (label == Lang.t('profile')) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          } else if (label == Lang.t('saved_routes')) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SavedRoutesPage()),
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
          
          // Status indicators
          if (_isSpeaking)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha((0.2 * 255).round()),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.volume_up, size: 16, color: Colors.blue[300]),
                  const SizedBox(width: 8),
                  Text(
                    Lang.isUrdu ? 'بول رہا ہے...' : 'Speaking...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[300],
                    ),
                  ),
                ],
              ),
            ),
            
          if (_isListening)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha((0.2 * 255).round()),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mic, size: 16, color: Colors.green[300]),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      Lang.isUrdu 
                        ? 'سن رہا ہے... آپ "آبجیکٹ"، "نیویگیشن"، "محفوظ راستے"، یا "گائیڈ" کہہ سکتے ہیں۔' 
                        : 'Listening... You can say "object", "navigation", "saved routes", or "guide".',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[300],
                      ),
                      textAlign: TextAlign.center,
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
          border: Border(top: BorderSide(color: Colors.white.withAlpha((0.1 * 255).round()))),
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
}