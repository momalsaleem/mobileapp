import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:nav_aif_fyp/pages/lang.dart';
import 'package:nav_aif_fyp/services/preferences_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PreferencesManager.init();
  await Lang.init();
  runApp(const NavAIApp());
}

class NavAIApp extends StatelessWidget {
  const NavAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NavAI',
      theme: ThemeData.dark(),
      home: const NavAIHomePage(),
      routes: {'/lang': (context) => const NavAILanguagePage()},
    );
  }
}

class NavAIHomePage extends StatefulWidget {
  const NavAIHomePage({super.key});

  @override
  State<NavAIHomePage> createState() => _NavAIHomePageState();
}

class _NavAIHomePageState extends State<NavAIHomePage>
    with TickerProviderStateMixin {
  late AnimationController _pathController;
  late AnimationController _starController;
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  // Voice interaction state
  bool _isSpeaking = false;
  bool _isListening = false;
  bool _bilingualIntroComplete = false;
  bool _microphoneReady = false;
  
  // Status messages for accessibility
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeVoiceSystem();
  }

  /// Initialize animations
  void _initAnimations() {
    _pathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    );

    _pathController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _starController.forward(from: 0.0);
      }
    });

    _starController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _pathController.reset();
            _starController.reset();
            _pathController.forward(from: 0.0);
          }
        });
      }
    });

    _pathController.forward();
  }

  /// Initialize complete voice system with bilingual support
  Future<void> _initializeVoiceSystem() async {
    try {
      setState(() => _statusMessage = 'Initializing voice system...');

      // Step 1: Initialize TTS
      await _initTTS();
      
      // Step 2: Initialize microphone in background (non-blocking)
      _initMicrophoneInBackground();
      
      // Step 3: Start bilingual introduction
      await _speakBilingualIntroduction();
      
      // Step 4: Wait for microphone to be ready
      await _waitForMicrophone();
      
      // Step 5: Start listening for commands
      await _startListening();
      
    } catch (e) {
      debugPrint('❌ Voice system initialization error: $e');
      setState(() => _statusMessage = 'Voice system unavailable. Touch mode enabled.');
      // Fall back to touch-only mode
    }
  }

  /// Initialize TTS with proper configuration
  Future<void> _initTTS() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5); // Slower for clarity
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.awaitSpeakCompletion(true);

    // Setup TTS event handlers
    _flutterTts.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
    });

    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });

    _flutterTts.setErrorHandler((message) {
      debugPrint('TTS Error: $message');
      if (mounted) setState(() => _isSpeaking = false);
    });

    debugPrint('✅ TTS initialized');
  }

  /// Initialize microphone in background (non-blocking)
  void _initMicrophoneInBackground() {
    Future.microtask(() async {
      try {
        setState(() => _statusMessage = 'Preparing microphone...');
        
        bool available = await _speech.initialize(
          onStatus: (status) {
            debugPrint('🎙️ Speech status: $status');
            if (status == 'done' && _isListening) {
              // Restart listening if it stops
              _startListening();
            }
          },
          onError: (error) {
            debugPrint('🎙️ Speech error: $error');
            if (mounted) {
              setState(() => _statusMessage = 'Microphone error. Using touch mode.');
            }
          },
        );

        if (available) {
          debugPrint('✅ Microphone initialized and ready');
          if (mounted) {
            setState(() {
              _microphoneReady = true;
              _statusMessage = 'Microphone ready';
            });
          }
        } else {
          debugPrint('❌ Microphone not available');
          if (mounted) {
            setState(() => _statusMessage = 'Microphone unavailable. Touch mode only.');
          }
        }
      } catch (e) {
        debugPrint('❌ Microphone initialization error: $e');
      }
    });
  }

  /// Initialize microphone immediately and await readiness.
  Future<void> _initMicrophoneNow() async {
    try {
      setState(() => _statusMessage = 'Requesting microphone permission...');

      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        debugPrint('Microphone permission denied');
        setState(() => _statusMessage = 'Microphone permission denied.');
        _microphoneReady = false;
        return;
      }

      setState(() => _statusMessage = 'Initializing microphone...');
      final available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('🎙️ Speech status (now): $status');
          if (status == 'done' && _isListening) {
            _startListening();
          }
        },
        onError: (error) {
          debugPrint('🎙️ Speech error (now): $error');
          if (mounted) setState(() => _statusMessage = 'Microphone error');
        },
      );

      if (available) {
        debugPrint('✅ Microphone initialized (now)');
        if (mounted) {
          setState(() {
            _microphoneReady = true;
            _statusMessage = 'Microphone ready';
          });
        }
      } else {
        debugPrint('❌ Microphone not available (now)');
        if (mounted) setState(() => _statusMessage = 'Microphone unavailable');
        _microphoneReady = false;
      }
    } catch (e) {
      debugPrint('❌ Microphone initialization error (now): $e');
      if (mounted) setState(() => _statusMessage = 'Microphone init error');
      _microphoneReady = false;
    }
  }

  /// Wait for microphone to be ready (with timeout)
  Future<void> _waitForMicrophone() async {
    int waitCount = 0;
    const maxWait = 10; // 5 seconds max

    while (!_microphoneReady && waitCount < maxWait) {
      await Future.delayed(const Duration(milliseconds: 500));
      waitCount++;
    }

    if (!_microphoneReady) {
      debugPrint('⚠️ Microphone initialization timeout. Proceeding anyway.');
    }
  }

  /// Speak bilingual introduction (English first, then Urdu)
  Future<void> _speakBilingualIntroduction() async {
    setState(() => _statusMessage = 'Speaking introduction...');

    try {
      // === ENGLISH INTRODUCTION ===
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.speak(
        'Welcome to Nav AI. Smart navigation, designed for you. '
        'You can say: Continue with voice, or Continue with touch. '
        'You can also just say: voice, or touch.',
      );
      await _flutterTts.awaitSpeakCompletion(true);
      
      // Pause between languages
      await Future.delayed(const Duration(milliseconds: 1000));

      // === URDU INTRODUCTION ===
      try {
        await _flutterTts.setLanguage('ur-PK');
        await _flutterTts.speak(
          'نیو اے آئی میں خوش آمدید۔ سمارٹ نیویگیشن، آپ کے لیے تیار کی گئی۔ '
          'آپ کہہ سکتے ہیں: آواز کے ساتھ جاری رکھیں، یا ٹچ کے ساتھ جاری رکھیں۔ '
          'آپ صرف یہ بھی کہہ سکتے ہیں: آواز، یا ٹچ۔',
        );
        await _flutterTts.awaitSpeakCompletion(true);
      } catch (e) {
        debugPrint('⚠️ Urdu TTS not available, skipping: $e');
        // Continue even if Urdu TTS fails
      }

      // Pause before listening
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _bilingualIntroComplete = true;
        _statusMessage = 'Listening for your command...';
      });

      debugPrint('✅ Bilingual introduction complete');
    } catch (e) {
      debugPrint('❌ Error during introduction: $e');
      setState(() => _statusMessage = 'Introduction error. Touch mode available.');
    }
  }

  /// Start listening for voice commands
  Future<void> _startListening() async {
    if (!_microphoneReady) {
      debugPrint('⚠️ Cannot start listening: microphone not ready');
      return;
    }

    if (!_bilingualIntroComplete) {
      debugPrint('⚠️ Cannot start listening: introduction not complete');
      return;
    }

    try {
      setState(() {
        _isListening = true;
        _statusMessage = 'Listening... Say "voice" or "touch"';
      });

      await _speech.listen(
        localeId: 'en-US', // Use English for initial detection
        onResult: (result) {
          if (result.finalResult) {
            String recognized = result.recognizedWords.toLowerCase().trim();
            if (recognized.isNotEmpty) {
              _processCommand(recognized);
            }
          }
        },
        listenFor: const Duration(seconds: 30), // Listen for 30 seconds
        pauseFor: const Duration(seconds: 5), // 5 second pause threshold
        partialResults: false,
      );
    } catch (e) {
      debugPrint('❌ Error starting listening: $e');
      setState(() {
        _isListening = false;
        _statusMessage = 'Listening error. Use touch controls.';
      });
    }
  }

  /// Process recognized voice command
  void _processCommand(String recognized) async {
    debugPrint('🎙️ Recognized command: "$recognized"');

    // Stop listening while processing
    await _speech.stop();
    setState(() => _isListening = false);

    bool commandMatched = false;

    // === VOICE MODE COMMANDS ===
    if (_matchesVoiceCommand(recognized)) {
      commandMatched = true;
      await _handleVoiceMode();
    }
    // === TOUCH MODE COMMANDS ===
    else if (_matchesTouchCommand(recognized)) {
      commandMatched = true;
      await _handleTouchMode();
    }

    // If command not recognized, ask to repeat
    if (!commandMatched && recognized.length > 2) {
      await _askToRepeat();
    } else if (!commandMatched) {
      // Resume listening for very short/empty input
      await _startListening();
    }
  }

  /// Check if input matches voice mode command
  bool _matchesVoiceCommand(String input) {
    const voiceKeywords = [
      'voice',
      'continue with voice',
      'start with voice',
      'voice mode',
      'awaz', // Urdu transliteration
      'آواز', // Urdu script
      'آواز کے ساتھ', // Urdu: with voice
    ];

    return voiceKeywords.any((keyword) => input.contains(keyword));
  }

  /// Check if input matches touch mode command
  bool _matchesTouchCommand(String input) {
    const touchKeywords = [
      'touch',
      'continue with touch',
      'start with touch',
      'touch mode',
      'tap',
      'ٹچ', // Urdu script
    ];

    return touchKeywords.any((keyword) => input.contains(keyword));
  }

  /// Handle voice mode selection
  Future<void> _handleVoiceMode() async {
    setState(() => _statusMessage = 'Voice mode selected');

    // Save preference
    await PreferencesManager.setVoiceModeEnabled(true);
    // Initialize microphone right away so next page can listen immediately
    await _initMicrophoneNow();
    debugPrint('✅ Voice mode enabled and saved');

    // Provide haptic feedback
    HapticFeedback.mediumImpact();

    // Speak confirmation in English
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.speak('Voice mode selected. Navigating to language selection.');
    await _flutterTts.awaitSpeakCompletion(true);

    // Navigate to language page
    _navigateToLang();
  }

  /// Handle touch mode selection
  Future<void> _handleTouchMode() async {
    setState(() => _statusMessage = 'Touch mode selected');

    // Save preference
    await PreferencesManager.setVoiceModeEnabled(false);
    debugPrint('✅ Touch mode enabled and saved');

    // Provide haptic feedback
    HapticFeedback.lightImpact();

    // Speak confirmation in English
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.speak('Touch mode selected. You can now use touch controls with voice guidance. Navigating to language selection.');
    await _flutterTts.awaitSpeakCompletion(true);

    // Navigate to language page
    _navigateToLang();
  }

  /// Ask user to repeat command
  Future<void> _askToRepeat() async {
    setState(() => _statusMessage = 'Command not understood. Please repeat.');

    // Provide haptic feedback for error
    HapticFeedback.vibrate();

    // Speak in both languages
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.speak(
      "I didn't catch that. Please say: voice, or touch.",
    );
    await _flutterTts.awaitSpeakCompletion(true);

    try {
      await _flutterTts.setLanguage('ur-PK');
      await _flutterTts.speak('میں نے نہیں سنا۔ براہ کرم کہیں: آواز، یا ٹچ۔');
      await _flutterTts.awaitSpeakCompletion(true);
    } catch (e) {
      debugPrint('⚠️ Urdu repeat message not available');
    }

    // Resume listening
    await _startListening();
  }

  /// Navigate to language selection page
  void _navigateToLang() {
    try {
      _speech.stop();
    } catch (_) {}
    
    setState(() => _isListening = false);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NavAILanguagePage()),
      );
    }
  }

  @override
  void dispose() {
    try {
      _flutterTts.stop();
      _speech.stop();
    } catch (_) {}
    _pathController.dispose();
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _buildBackground(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Container(
                    color: const Color(0xFF0d1b2a),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 450),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Animation container
                              SizedBox(
                                height: 250,
                                width: double.infinity,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFF0a192f),
                                        Color(0xFF0d253f),
                                      ],
                                    ),
                                  ),
                                  child: AnimatedBuilder(
                                    animation: Listenable.merge(
                                        [_pathController, _starController]),
                                    builder: (context, child) {
                                      return CustomPaint(
                                        painter: PathAnimationPainter(
                                          pathAnimation: _pathController,
                                          starAnimation: Tween<double>(
                                            begin: 0.0,
                                            end: 1.0,
                                          ).animate(
                                            CurvedAnimation(
                                              parent: _starController,
                                              curve: Curves.easeInOut,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Title (bilingual)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'Welcome to Nav AI / نیو اے آئی میں خوش آمدید',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 10),
                              
                              // Subtitle (bilingual)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'Smart navigation, designed for you.\nسمارٹ نیویگیشن، آپ کے لیے تیار کی گئی۔',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFcbd5e0),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Voice mode button
                              _buildButton(
                                'Start with Voice / آواز سے شروع کریں',
                                Icons.mic,
                                const Color(0xFF2563eb),
                                Colors.white,
                                onTap: () async {
                                  await PreferencesManager.setVoiceModeEnabled(true);
                                  _navigateToLang();
                                },
                              ),
                              
                              // Touch mode button
                              _buildButton(
                                'Continue with Touch / ٹچ کے ذریعے جاری رکھیں',
                                Icons.smartphone,
                                const Color(0xFF1f2937),
                                const Color(0xFFd1d5db),
                                borderColor: const Color(0xFF374151),
                                onTap: () async {
                                  await PreferencesManager.setVoiceModeEnabled(false);
                                  _navigateToLang();
                                },
                              ),
                              
                              // Status indicators
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Column(
                                  children: [
                                    // Speaking indicator
                                    if (_isSpeaking)
                                      _buildStatusIndicator(
                                        icon: Icons.volume_up,
                                        text: 'Speaking... / بول رہا ہے...',
                                        color: Colors.blue,
                                      ),
                                    
                                    // Listening indicator
                                    if (_isListening)
                                      _buildStatusIndicator(
                                        icon: Icons.mic,
                                        text: 'Listening... / سن رہا ہے...',
                                        color: Colors.green,
                                      ),
                                    
                                    // Status message
                                    if (!_isSpeaking && !_isListening)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          _statusMessage,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF9DA4B9),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Build button widget
  Widget _buildButton(
      String text, IconData icon, Color background, Color foreground,
      {Color? borderColor, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap ?? _navigateToLang,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: borderColor != null
                ? BorderSide(color: borderColor, width: 1)
                : BorderSide.none,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build status indicator widget
  Widget _buildStatusIndicator({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color.withOpacity(0.8)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _buildBackground() {
    return const BoxDecoration(
      gradient: RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Color(0xFF0f2027),
          Color(0xFF203a43),
          Color(0xFF2c5364),
        ],
      ),
    );
  }
}

// PathAnimationPainter class remains unchanged
class PathAnimationPainter extends CustomPainter {
  final Animation<double> pathAnimation;
  final Animation<double> starAnimation;
  static const Size viewBox = Size(400, 200);

  PathAnimationPainter(
      {required this.pathAnimation, required this.starAnimation})
      : super(repaint: Listenable.merge([pathAnimation, starAnimation]));

  Path _getPath1() {
    final path = Path()..moveTo(0, 120);
    path.quadraticBezierTo(150, 40, 250, 90);
    path.quadraticBezierTo(350, 140, 400, 50);
    return path;
  }

  Path _getPath2() {
    final path = Path()..moveTo(0, 200);
    path.quadraticBezierTo(150, 120, 250, 170);
    path.quadraticBezierTo(350, 220, 400, 130);
    return path;
  }

  Path _createStarShape(double size) {
    final path = Path();
    const double normalizer = 22.0;

    final List<Offset> points = [
      const Offset(12.00, 2.00),
      const Offset(9.42, 8.66),
      const Offset(2.00, 10.47),
      const Offset(7.60, 15.34),
      const Offset(6.18, 22.00),
      const Offset(12.00, 18.50),
      const Offset(17.82, 22.00),
      const Offset(16.40, 15.34),
      const Offset(22.00, 10.47),
      const Offset(14.58, 8.66),
    ].map((p) => Offset(p.dx / normalizer, p.dy / normalizer)).toList();

    const Offset centerOffset = Offset(0.5, 0.5);

    path.moveTo(
      (points[0].dx - centerOffset.dx) * size,
      (points[0].dy - centerOffset.dy) * size,
    );

    for (int i = 1; i < points.length; i++) {
      path.lineTo(
        (points[i].dx - centerOffset.dx) * size,
        (points[i].dy - centerOffset.dy) * size,
      );
    }

    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / viewBox.width;
    final double scaleY = size.height / viewBox.height;

    canvas.scale(scaleX, scaleY);

    final path1 = _getPath1();
    final path2 = _getPath2();

    final ui.PathMetric m1 = path1.computeMetrics().first;
    final ui.PathMetric m2 = path2.computeMetrics().first;

    final double drawLen1 = m1.length * pathAnimation.value;
    final double drawLen2 =
        m2.length * math.max(0.0, pathAnimation.value - 0.075);

    final double strokeWidth = 3 / scaleX;

    final paint1 = Paint()
      ..color = const Color(0xFF3a9df8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final paint2 = Paint()
      ..color = const Color(0xFF00f7ff)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawPath(m1.extractPath(0, drawLen1), paint1);
    canvas.drawPath(m2.extractPath(0, drawLen2), paint2);

    if (starAnimation.value > 0.0) {
      int steps = 100;
      Path midpointPath = Path();
      for (int i = 0; i <= steps; i++) {
        double t = i / steps;
        final ui.Tangent? p1 = m1.getTangentForOffset(m1.length * t);
        final ui.Tangent? p2 = m2.getTangentForOffset(m2.length * t);
        if (p1 != null && p2 != null) {
          Offset mid = Offset(
            (p1.position.dx + p2.position.dx) / 2,
            (p1.position.dy + p2.position.dy) / 2,
          );
          if (i == 0) {
            midpointPath.moveTo(mid.dx, mid.dy);
          } else {
            midpointPath.lineTo(mid.dx, mid.dy);
          }
        }
      }

      final ui.PathMetric midMetric = midpointPath.computeMetrics().first;
      final double distance = midMetric.length * starAnimation.value;
      final ui.Tangent? tangent = midMetric.getTangentForOffset(distance);

      if (tangent != null) {
        double starSize = 40 + 10 * math.sin(math.pi * starAnimation.value);
        double opacity = 1.0;

        const double invisibleFracStart = 0.2 / 7.0;
        const double invisibleFracEnd = 0.5 / 7.0;
        if (starAnimation.value < invisibleFracStart) {
          opacity = 0.0;
        } else if (starAnimation.value < invisibleFracStart + 0.1) {
          opacity = (starAnimation.value - invisibleFracStart) / 0.1;
        } else if (starAnimation.value < 1.0 - invisibleFracEnd - 0.1) {
          opacity = 1.0;
        } else if (starAnimation.value < 1.0 - invisibleFracEnd) {
          opacity = (1.0 - invisibleFracEnd - starAnimation.value) / 0.1;
        } else {
          opacity = 0.0;
        }

        canvas.save();
        canvas.translate(tangent.position.dx, tangent.position.dy);
        canvas.scale(1 / scaleX, 1 / scaleY);

        final star = _createStarShape(starSize);

        final starPaint = Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 5.0);

        canvas.drawPath(star, starPaint);

        final starPaintSolid = Paint()
          ..color = Colors.white.withOpacity(opacity);

        canvas.drawPath(star, starPaintSolid);

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant PathAnimationPainter oldDelegate) => true;
}