import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:nav_aif_fyp/pages/page_four.dart';
import 'package:nav_aif_fyp/utils/lang.dart';
import 'package:nav_aif_fyp/services/preferences_manager.dart';
import 'package:nav_aif_fyp/services/voice_manager.dart';
import 'package:nav_aif_fyp/services/route_tts_observer.dart';

class GuidePageBody extends StatefulWidget {
  const GuidePageBody({super.key});

  @override
  State<GuidePageBody> createState() => _GuidePageBodyState();
}

class _GuidePageBodyState extends State<GuidePageBody> with RouteAwareTtsStopper {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  int? _hoveredIndex;
  int? _selectedIndex;
  bool _isInitialized = false;
  bool _isSpeaking = false;

  final List<Map<String, dynamic>> options = [
    {
      'icon': Icons.mic,
      'label': 'voice_only',
      'desc': 'voice_only_desc',
      'voiceCommands': ['voice only', 'voice', '1', 'صرف آواز', 'آواز']
    },
    {
      'icon': Icons.vibration,
      'label': 'voice_haptic',
      'desc': 'voice_haptic_desc', 
      'voiceCommands': ['voice and haptic', 'haptic', '2', 'ہلکی سی وائبریشن', 'وائبریشن']
    },
    {
      'icon': Icons.graphic_eq,
      'label': 'sound_voice',
      'desc': 'sound_voice_desc',
      'voiceCommands': ['sound cues', 'sound', '3', 'آواز کے اشارے', 'اشارے']
    },
  ];

  @override
  void initState() {
    super.initState();
    // Defer voice initialization until after first frame (prevents web window assertion)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Build UI immediately and perform heavy voice init in background
      setState(() {
        _isInitialized = true;
      });
      _initializeAppInBackground();
    });
  }

  Future<void> _initializeAppInBackground() async {
    try {
      await Lang.init();
      await _initTTS();

      final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();

      if (isVoiceModeEnabled) {
        // Speak and initialize mic in background so UI stays responsive
        await _speakFullPageContent();
        await _initializeMicrophone();
      }
    } catch (e) {
      debugPrint('Background voice init error: $e');
    }
  }

  // _initializeApp removed: initialization is handled in background by
  // _initializeAppInBackground to avoid blocking the UI build.

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
    // Use conservative rate and full volume for clearer speech
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    try {
      await _tts.setVolume(1.0);
    } catch (_) {}
  }

  // ✅ Speak the entire page content including all options
  Future<void> _speakFullPageContent() async {
    if (!mounted) return;
    
    setState(() {
      _isSpeaking = true;
    });

    try {
      // 1. Speak the main title
      await VoiceManager.safeSpeak(_tts, Lang.t('select_nav_mode'));
      await VoiceManager.safeAwaitSpeakCompletion(_tts);

      // 2. Speak each option with description
      for (int i = 0; i < options.length; i++) {
        final option = options[i];
        final optionText = 'Option ${i + 1}. ${Lang.t(option['label'])}. ${Lang.t(option['desc'])}';
        await VoiceManager.safeSpeak(_tts, optionText);
        await VoiceManager.safeAwaitSpeakCompletion(_tts);
        
        // Small pause between options
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // 3. Speak voice instructions
      final instructionText = Lang.isUrdu 
          ? "اپنی پسند کا انتخاب کرنے کے لئے بولئیے: صرف آواز، آواز اور وائبریشن، یا آواز کے اشارے۔ آپ نمبر بھی استعمال کر سکتے ہیں: ایک، دو، یا تین۔"
          : "Speak to select your preference: voice only, voice and haptic, or sound cues. You can also use numbers: one, two, or three.";
      
      await VoiceManager.safeSpeak(_tts, instructionText);
      await VoiceManager.safeAwaitSpeakCompletion(_tts);

    } catch (e) {
      debugPrint('Error speaking page content: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    }
  }

  // ✅ Initialize microphone exactly like template
  Future<void> _initializeMicrophone() async {
    // Ensure microphone permission is granted before initializing STT
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      debugPrint('Microphone permission not granted');
      setState(() => _isListening = false);
      return;
    }

    final available = await VoiceManager.safeInitializeSpeech(
      _speech,
      onStatus: (val) {
        debugPrint('Speech Status: $val');
        if (val == "done" && _isListening) {
          setState(() => _isListening = false);
          // Restart listening exactly like template
          Future.delayed(const Duration(milliseconds: 100), _startListening);
        }
      },
      onError: (val) {
        debugPrint('Speech Error: $val');
        setState(() => _isListening = false);
        // Retry exactly like template
        Future.delayed(const Duration(seconds: 1), _initializeMicrophone);
      },
    );

    if (available) {
      await _startListening();
    } else {
      debugPrint('Microphone not available');
      // Retry exactly like template
      Future.delayed(const Duration(seconds: 2), _initializeMicrophone);
    }
  }

  // ✅ Start listening exactly like template
  Future<void> _startListening() async {
    if (!mounted) return;

    // Ask for microphone permission before initializing STT
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      debugPrint('Microphone permission not granted (startListening)');
      setState(() => _isListening = false);
      return;
    }

    final available = await VoiceManager.safeInitializeSpeech(
      _speech,
      onStatus: (val) {
        debugPrint('Speech Status: $val');
        if (val == "done" && _isListening) {
          setState(() => _isListening = false);
          _startListening(); // Restart listening exactly like template
        }
      },
      onError: (val) {
        debugPrint('Speech Error: $val');
        setState(() => _isListening = false);
        Future.delayed(const Duration(seconds: 1), _startListening);
      },
    );

    if (available) {
      setState(() => _isListening = true);
      await VoiceManager.safeListen(
        _speech,
        localeId: Lang.speechLocaleId,
        onResult: (result) {
          String recognized = (result.recognizedWords ?? '').toString().trim();
          if (recognized.isNotEmpty && (result.finalResult ?? false)) {
            debugPrint('🎙 Recognized: $recognized');
            _processVoiceCommand(recognized);
          }
        },
      );
    } else {
      debugPrint('Speech not available');
      Future.delayed(const Duration(seconds: 2), _startListening);
    }
  }

  // ✅ Process voice commands exactly like template
  void _processVoiceCommand(String recognized) {
    String cleaned = recognized.toLowerCase().trim();
    int? selectedIndex;

    // Quick command matching exactly like template
    for (int i = 0; i < options.length; i++) {
      for (String command in options[i]['voiceCommands']) {
        if (cleaned.contains(command.toLowerCase())) {
          selectedIndex = i;
          debugPrint('✅ Command matched: $command → Option $i');
          break;
        }
      }
      if (selectedIndex != null) break;
    }

    // Also check for number commands
    if (selectedIndex == null) {
      if (cleaned.contains('1') || cleaned.contains('one') || cleaned.contains('ایک')) {
        selectedIndex = 0;
      } else if (cleaned.contains('2') || cleaned.contains('two') || cleaned.contains('دو')) {
        selectedIndex = 1;
      } else if (cleaned.contains('3') || cleaned.contains('three') || cleaned.contains('تین')) {
        selectedIndex = 2;
      }
    }

    if (selectedIndex != null) {
      _selectAndNavigate(selectedIndex);
    } else if (cleaned.length > 3) {
      // If substantial speech but not recognized, provide quick feedback exactly like template
      _provideQuickFeedback();
    }
  }

  // ✅ Quick feedback exactly like template
  Future<void> _provideQuickFeedback() async {
    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    if (isVoiceModeEnabled && mounted) {
      await VoiceManager.safeSpeak(_tts, Lang.t('please_repeat'));
    }
  }

  // ✅ Immediate selection and navigation exactly like template
  Future<void> _selectAndNavigate(int index) async {
    if (!mounted) return;

    // Stop everything immediately exactly like template
    await VoiceManager.safeStopListening(_speech);
    try {
      _tts.stop();
    } catch (_) {}

    setState(() {
      _selectedIndex = index;
      _isListening = false;
    });

    // Quick confirmation exactly like template
    final selectedOption = options[index];
    final confirmationText = Lang.isUrdu
        ? "آپ نے ${Lang.t(selectedOption['label'])} منتخب کیا ہے۔"
        : "You selected ${Lang.t(selectedOption['label'])}.";
    
    await VoiceManager.safeSpeak(_tts, confirmationText);

    // Navigate immediately after confirmation exactly like template
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    });
  }

  // ✅ Manual selection via tap exactly like template
  Future<void> _handleManualSelection(int index) async {
    // Stop exactly like template
    await VoiceManager.safeStopListening(_speech);
    try {
      _tts.stop();
    } catch (_) {}
    
    setState(() {
      _selectedIndex = index;
      _isListening = false;
    });

    // Quick navigation for manual selection exactly like template
    Future.delayed(Duration.zero, () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    });
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
                Lang.isUrdu ? 'لوڈ ہو رہا ہے...' : 'Loading...',
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
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and skip - exactly like template
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () {
                      VoiceManager.safeStopListening(_speech);
                      _tts.stop();
                      Navigator.pop(context);
                    },
                  ),
                  const Spacer(),
                  // Speaking indicator when speaking
                  if (_isSpeaking)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha((0.2 * 255).round()),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.volume_up, size: 16, color: Colors.blueAccent),
                          SizedBox(width: 6),
                          Text(
                            Lang.isUrdu ? 'بول رہا ہے' : 'Speaking',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    TextButton(
                      onPressed: () {
                        VoiceManager.safeStopListening(_speech);
                        _tts.stop();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const DashboardScreen()),
                        );
                      },
                      child: Text(
                        Lang.t('skip'),
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
            
            // Title - exactly like template
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                Lang.t('select_nav_mode'),
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 32),

            // Voice listening indicator - exactly like template
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isListening
                  ? Container(
                      key: const ValueKey('listening'),
                      margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha((0.15 * 255).round()),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mic, size: 18, color: Colors.greenAccent),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              Lang.isUrdu 
                                  ? 'سنیں جا رہی ہیں... بولئیے'
                                  : 'Listening... Speak now',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      key: const ValueKey('not_listening'),
                      margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                        color: Colors.orange.withAlpha((0.15 * 255).round()),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mic_off, size: 18, color: Colors.orangeAccent),
                          SizedBox(width: 10),
                          Text(
                            Lang.isUrdu ? 'سنیں بند ہیں' : 'Listening paused',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            // Options list - exactly like template
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: List.generate(options.length, (index) {
                    final option = options[index];
                    final isSelected = _selectedIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _NavigationOptionCard(
                        icon: option['icon'],
                        title: Lang.t(option['label']),
                        subtitle: Lang.t(option['desc']),
                        isSelected: isSelected,
                        isHovered: _hoveredIndex == index,
                        onTap: () => _handleManualSelection(index),
                        onHover: (isHovered) {
                          setState(() {
                            _hoveredIndex = isHovered ? index : null;
                          });
                        },
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Continue button - exactly like template
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
          backgroundColor: _selectedIndex != null 
            ? const Color(0xFF1349EC)
            : Colors.grey.withAlpha((0.3 * 255).round()),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    shadowColor: _selectedIndex != null 
                        ? Color(0xFF1349EC).withAlpha((0.5 * 255).round())
                        : Colors.transparent,
                  ),
                  onPressed: _selectedIndex != null
                      ? () => _handleManualSelection(_selectedIndex!)
                      : null,
                  child: Text(
                    Lang.t('continue'),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 17,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
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

  @override
  void dispose() {
    // Let mixin unsubscribe when super.dispose is called
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
}

// Custom option card widget - exactly like template
class _NavigationOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isHovered;
  final VoidCallback onTap;
  final Function(bool) onHover;

  const _NavigationOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.isHovered,
    required this.onTap,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected 
        ? const Color(0xFF1A2A3A)
        : (isHovered ? const Color(0xFF1A202C) : const Color(0xFF1E232C));
    
    final borderColor = isSelected ? const Color(0xFF1349ec) : Colors.transparent;
    final iconColor = isSelected ? const Color(0xFF1349ec) : const Color(0xFF9DA4B9);

    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: 2.5,
            ),
            boxShadow: [
              if (isSelected || isHovered)
                BoxShadow(
                  color: Colors.black.withAlpha((0.3 * 255).round()),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                    border: Border.all(
                    color: iconColor.withAlpha((0.3 * 255).round()),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, size: 28, color: iconColor),
              ),
              
              const SizedBox(width: 20),
              
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF9DA4B9),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Selection indicator
              if (isSelected)
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1349ec),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
