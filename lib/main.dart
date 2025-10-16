import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:nav_aif_fyp/pages/lang.dart';

void main() {
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
      routes: {'/lang': (context) => NavAILanguagePage()},
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
<<<<<<< Updated upstream
  bool _showChoices = false;
=======
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isSpeaking = false;
  bool _isListening = false;
  bool _urduMode = false;
>>>>>>> Stashed changes

  @override
  void initState() {
    super.initState();
<<<<<<< Updated upstream

    // Animation controllers
    _pathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );

    // Start path animation
    _pathController.forward(from: 0.0);

    // Sequence: start star after path
=======
    initTTS().then(() {
      speakEnglishThenUrdu().then(() {
        _startListening(); // start listening after speech
      });
    });
    _initAnimations();
  }

  Future<void> _initTTS() async {
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.awaitSpeakCompletion(true);

    _flutterTts.setStartHandler(() {
      setState(() => _isSpeaking = true);
    });

    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });

    _flutterTts.setErrorHandler((message) {
      setState(() => _isSpeaking = false);
    });
  }

  Future<void> _speakEnglishThenUrdu() async {
    // English - Always speak in English regardless of preference
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.speak(
      'Welcome to Nav AI. Smart navigation, designed for you. Say start with voice or continue by tapping.',
    );

    // Wait until speech finishes
    await Future.delayed(const Duration(seconds: 5));

    // Urdu - Only if TTS is enabled and language preference is Urdu
    if (TTSPreference.enabled && TTSPreference.language == 'ur') {
      try {
        List<dynamic> langs = await _flutterTts.getLanguages;
        if (langs.contains('ur-PK')) {
          await _flutterTts.setLanguage('ur-PK');
          await _flutterTts.speak(
            'نیو اے آئی میں خوش آمدید۔ سمارٹ نیویگیشن، آپ کے لیے تیار کی گئی۔ آواز سے شروع کریں یا ٹچ کے ذریعے جاری رکھیں۔',
          );
        } else {
          print('Urdu TTS not available.');
        }
      } catch (e) {
        print('Urdu TTS error: $e');
      }
    }
  }

  void _initAnimations() {
    _pathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    );

>>>>>>> Stashed changes
    _pathController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _starController.forward(from: 0.0);
      }
    });

    // TTS + buttons after star animation starts
    _starController.addStatusListener((status) async {
<<<<<<< Updated upstream
      if (status == AnimationStatus.forward) {
        await _flutterTts.setSpeechRate(0.5);
        await _flutterTts.setVolume(1.0);
        await _flutterTts.setPitch(1.0);
        await _flutterTts.awaitSpeakCompletion(true);

        // Detect device language
        String deviceLang = ui.window.locale.languageCode;
        bool isUrdu = deviceLang == 'ur';

        if (isUrdu) {
          await _flutterTts.setLanguage('ur-PK');
          await _flutterTts.speak('نیو اے آئی میں خوش آمدید');
          await Future.delayed(const Duration(seconds: 1));
          await _flutterTts.speak('کیا آپ ٹائپ کر کے جاری رکھنا چاہتے ہیں یا بول کر؟');
        } else {
          // English first
          await _flutterTts.setLanguage('en-US');
          await _flutterTts.speak('Welcome to Nav AI');
          await Future.delayed(const Duration(seconds: 1));
          // Then Urdu
          await _flutterTts.setLanguage('ur-PK');
          await _flutterTts.speak('نیو اے آئی میں خوش آمدید');
          await Future.delayed(const Duration(seconds: 1));
          // Follow-up question in both languages
          await _flutterTts.setLanguage('en-US');
          await _flutterTts.speak(
              'Do you want to continue by typing or continue with speech?');
          await Future.delayed(const Duration(seconds: 1));
          await _flutterTts.setLanguage('ur-PK');
          await _flutterTts.speak(
              'کیا آپ ٹائپ کر کے جاری رکھنا چاہتے ہیں یا بول کر؟');
        }

        setState(() {
          _showChoices = true;
        });
      }

      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 800), () {
=======
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 500), () {
>>>>>>> Stashed changes
          _pathController.reset();
          _starController.reset();
          _pathController.forward(from: 0.0);
        });
      }
    });

    _pathController.forward();
  }

<<<<<<< Updated upstream
=======
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
        localeId: 'en-US', // for English
        onResult: (result) {
          String recognized = result.recognizedWords.toLowerCase().trim();
          _processCommand(recognized);
        },
      );

      // Also listen for Urdu (ur-PK)
      _speech.listen(
        localeId: 'ur-PK',
        onResult: (result) {
          String recognized = result.recognizedWords.toLowerCase().trim();
          _processCommand(recognized);
        },
      );
    } else {
      setState(() => _isListening = false);
    }
  }

  void _processCommand(String recognized) {
    debugPrint("🎙 Recognized: $recognized");
    // Accept English voice commands regardless of language preference
    if (recognized.contains('start') ||
        recognized.contains('voice') ||
        recognized.contains('continue with voice') ||
        recognized.contains('start with voice') ||
        recognized.contains('آواز') ||
        recognized.contains('شروع')) {
      _navigateToLang();
    } else if (recognized.contains('touch') ||
        recognized.contains('continue') ||
        recognized.contains('tap') ||
        recognized.contains('ٹچ') ||
        recognized.contains('جاری')) {
      _navigateToLang();
    }
  }

  void _navigateToLang() {
    _speech.stop();
    setState(() => _isListening = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NavAILanguagePage()),
    );
  }

>>>>>>> Stashed changes
  @override
  void dispose() {
    _flutterTts.stop();
    _speech.stop();
    _pathController.dispose();
    _starController.dispose();
    super.dispose();
  }

  // Helper to build the main background gradient
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< Updated upstream
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Color(0xFF0f2027),
              Color(0xFF203a43),
              Color(0xFF2c5364),
            ],
          ),
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Enhanced Animation Container
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
                      animation: Listenable.merge([_pathController, _starController]),
                      builder: (context, child) {
                        return CustomPaint(
                          painter: EnhancedPathPainter(
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
                const SizedBox(height: 30),
                Text(
                  'Welcome to NavAI',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Smart navigation, designed for you.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFcbd5e0),
                    fontFamily: 'Inter',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (_showChoices)
                  Column(
                    children: [
                      _buildButton('Continue by Typing', Icons.keyboard,
                          const Color(0xFF2563eb), Colors.white),
                      const SizedBox(height: 10),
                      _buildButton('Continue with Speech', Icons.mic,
                          const Color(0xFF1f2937), const Color(0xFFd1d5db),
                          borderColor: const Color(0xFF374151)),
                    ],
                  ),
              ],
            ),
          ),
=======
      body: Container(
        decoration: _buildBackground(),
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
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                        child: IntrinsicHeight(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Animation Container
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
                                    animation: Listenable.merge([_pathController, _starController]),
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
                              Text(
                                'Welcome to Nav AI / نیو اے آئی میں خوش آمدید',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Smart navigation, designed for you.\nسمارٹ نیویگیشن، آپ کے لیے تیار کی گئی۔',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFcbd5e0),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              _buildButton(
                                'Start with Voice / آواز سے شروع کریں', 
                                Icons.mic, 
                                const Color(0xFF2563eb), 
                                Colors.white
                              ),
                              _buildButton(
                                'Continue with Touch / ٹچ کے ذریعے جاری رکھیں', 
                                Icons.smartphone, 
                                const Color(0xFF1f2937), 
                                const Color(0xFFd1d5db),
                                borderColor: const Color(0xFF374151)
                              ),
                              
                              // Status indicators
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Column(
                                  children: [
                                    if (_isSpeaking)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.volume_up, size: 16, color: Colors.blue[300]),
                                          const SizedBox(width: 5),
                                          const Text(
                                            'Speaking... / بول رہا ہے...',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (_isListening)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.mic, size: 16, color: Colors.green[300]),
                                          const SizedBox(width: 5),
                                          const Text(
                                            'Listening... / آواز سن رہا ہے...',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
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
              ),
            );
          },
>>>>>>> Stashed changes
        ),
      ),
    );
  }

<<<<<<< Updated upstream
  Widget _buildButton(String text, IconData icon, Color background,
      Color foreground, {Color? borderColor}) {
=======
  Widget _buildButton(String text, IconData icon, Color background, Color foreground, {Color? borderColor}) {
>>>>>>> Stashed changes
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      width: double.infinity,
      child: ElevatedButton(
<<<<<<< Updated upstream
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$text selected')),
          );
        },
=======
        onPressed: _navigateToLang,
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
            fontFamily: 'Inter',
=======
>>>>>>> Stashed changes
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
<<<<<<< Updated upstream
            Text(text),
=======
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
>>>>>>> Stashed changes
          ],
        ),
      ),
    );
  }
}

<<<<<<< Updated upstream
class EnhancedPathPainter extends CustomPainter {
  final Animation<double> pathAnimation;
  final Animation<double> starAnimation;
  final Size viewBox = const Size(400, 200);

  EnhancedPathPainter({required this.pathAnimation, required this.starAnimation})
=======
class PathAnimationPainter extends CustomPainter {
  final Animation<double> pathAnimation;
  final Animation<double> starAnimation;
  final Size viewBox = const Size(400, 200); 

  PathAnimationPainter({required this.pathAnimation, required this.starAnimation})
>>>>>>> Stashed changes
      : super(repaint: Listenable.merge([pathAnimation, starAnimation]));

  // Path 1 definition (M 0 120 Q 150 40 250 90 T 400 50)
  Path _getPath1() {
    final path = Path()..moveTo(0, 120);
    path.quadraticBezierTo(150, 40, 250, 90);
<<<<<<< Updated upstream
    path.quadraticBezierTo(350, 140, 400, 50);
=======
    path.quadraticBezierTo(350, 140, 400, 50); 
>>>>>>> Stashed changes
    return path;
  }

  // Path 2 definition (M 0 200 Q 150 120 250 170 T 400 130)
  Path _getPath2() {
    final path = Path()..moveTo(0, 200);
    path.quadraticBezierTo(150, 120, 250, 170);
    path.quadraticBezierTo(350, 220, 400, 130);
    return path;
  }

  // Star shape drawing
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

<<<<<<< Updated upstream
    const Offset centerOffset = Offset(0.5, 0.5);

=======
    const Offset centerOffset = Offset(0.5, 0.5); 
    
>>>>>>> Stashed changes
    path.moveTo(
      (points[0].dx - centerOffset.dx) * size,
      (points[0].dy - centerOffset.dy) * size,
    );
<<<<<<< Updated upstream

=======
    
>>>>>>> Stashed changes
    for (int i = 1; i < points.length; i++) {
      path.lineTo(
        (points[i].dx - centerOffset.dx) * size,
        (points[i].dy - centerOffset.dy) * size,
      );
    }

<<<<<<< Updated upstream
    path.close();
=======
    path.close(); 
>>>>>>> Stashed changes
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / viewBox.width;
    final double scaleY = size.height / viewBox.height;
<<<<<<< Updated upstream

    canvas.scale(scaleX, scaleY);

    final path1 = _getPath1();
    final path2 = _getPath2();

    final ui.PathMetric m1 = path1.computeMetrics().first;
    final ui.PathMetric m2 = path2.computeMetrics().first;

=======
    
    canvas.scale(scaleX, scaleY); 

    final path1 = _getPath1();
    final path2 = _getPath2();

    final ui.PathMetric m1 = path1.computeMetrics().first;
    final ui.PathMetric m2 = path2.computeMetrics().first;

>>>>>>> Stashed changes
    final double drawLen1 = m1.length * pathAnimation.value;
    final double drawLen2 = m2.length * math.max(0.0, pathAnimation.value - 0.075);

    final double strokeWidth = 3 / scaleX;

    final paint1 = Paint()
      ..color = const Color(0xFF3a9df8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final paint2 = Paint()
      ..color = const Color(0xFF00f7ff)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
<<<<<<< Updated upstream

    canvas.drawPath(m1.extractPath(0, drawLen1), paint1);
    canvas.drawPath(m2.extractPath(0, drawLen2), paint2);

    // --- Moving star ---
    if (starAnimation.value > 0.0) {
      // Compute midpoint path between top & bottom lines
=======
    
    canvas.drawPath(m1.extractPath(0, drawLen1), paint1);
    canvas.drawPath(m2.extractPath(0, drawLen2), paint2);

    // Moving star
    if (starAnimation.value > 0.0) {
>>>>>>> Stashed changes
      int steps = 100;
      Path midpointPath = Path();
      for (int i = 0; i <= steps; i++) {
        double t = i / steps;
        final ui.Tangent? p1 = m1.getTangentForOffset(m1.length * t);
        final ui.Tangent? p2 = m2.getTangentForOffset(m2.length * t);
        if (p1 != null && p2 != null) {
          Offset mid = Offset(
<<<<<<< Updated upstream
            (p1.position.dx + p2.position.dx) / 2,
            (p1.position.dy + p2.position.dy) / 2,
          );

=======
              (p1.position.dx + p2.position.dx) / 2,
              (p1.position.dy + p2.position.dy) / 2);
          
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
        // Star size with path-based subtle pulsing (40 to 50)
        double starSize = 40 + 10 * math.sin(math.pi * starAnimation.value);

        // --- Opacity Fade In (0.0 to 0.1) and Fade Out (0.8 to 1.0) ---
        double opacity = 1.0;

        // Invisible for first 0.2s and last 0.5s (of 7s), fade in/out in next 10%
        const double invisibleFracStart = 0.2 / 7.0; // ~0.02857
        const double invisibleFracEnd = 0.5 / 7.0;   // ~0.07143
        if (starAnimation.value < invisibleFracStart) {
          opacity = 0.0;
        } else if (starAnimation.value < invisibleFracStart + 0.1) {
          // Fade in: 0 → 1
          opacity = (starAnimation.value - invisibleFracStart) / 0.1;
        } else if (starAnimation.value < 1.0 - invisibleFracEnd - 0.1) {
          // Fully visible
          opacity = 1.0;
        } else if (starAnimation.value < 1.0 - invisibleFracEnd) {
          // Fade out: 1 → 0
=======
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
>>>>>>> Stashed changes
          opacity = (1.0 - invisibleFracEnd - starAnimation.value) / 0.1;
        } else {
          opacity = 0.0;
        }

<<<<<<< Updated upstream
        // Paint the star
=======
>>>>>>> Stashed changes
        canvas.save();
        canvas.translate(tangent.position.dx, tangent.position.dy);
        canvas.scale(1 / scaleX, 1 / scaleY);

        final star = _createStarShape(starSize);
<<<<<<< Updated upstream

        // Custom Paint for Glow
=======
        
>>>>>>> Stashed changes
        final starPaint = Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.outer, 5.0);

<<<<<<< Updated upstream
        canvas.drawPath(star, starPaint); // Draw glow layer

        final starPaintSolid = Paint()
          ..color = Colors.white.withOpacity(opacity);

        canvas.drawPath(star, starPaintSolid); // Draw solid star layer

=======
        canvas.drawPath(star, starPaint);
        
        final starPaintSolid = Paint()
          ..color = Colors.white.withOpacity(opacity);

        canvas.drawPath(star, starPaintSolid);
        
>>>>>>> Stashed changes
        canvas.restore();
      }
    }
  }

  @override
<<<<<<< Updated upstream
  bool shouldRepaint(covariant EnhancedPathPainter oldDelegate) => true;
}
=======
  bool shouldRepaint(covariant PathAnimationPainter oldDelegate) => true;
}
>>>>>>> Stashed changes
