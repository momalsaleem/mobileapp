import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nav AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const NavAIIntro(),
    );
  }
}

class NavAIIntro extends StatefulWidget {
  const NavAIIntro({super.key});

  @override
  State<NavAIIntro> createState() => _NavAIIntroState();
}

class _NavAIIntroState extends State<NavAIIntro> with TickerProviderStateMixin {
  late AnimationController _pathController;
  late AnimationController _starController;
  final FlutterTts _flutterTts = FlutterTts();
  bool _showChoices = false;

  @override
  void initState() {
    super.initState();

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
    _pathController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _starController.forward(from: 0.0);
      }
    });

    // TTS + buttons after star animation starts
    _starController.addStatusListener((status) async {
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
          _pathController.reset();
          _starController.reset();
          _pathController.forward(from: 0.0);
        });
      }
    });
  }

  @override
  void dispose() {
    _pathController.dispose();
    _starController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        ),
      ),
    );
  }

  Widget _buildButton(String text, IconData icon, Color background,
      Color foreground, {Color? borderColor}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$text selected')),
          );
        },
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
            fontFamily: 'Inter',
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(text),
          ],
        ),
      ),
    );
  }
}

class EnhancedPathPainter extends CustomPainter {
  final Animation<double> pathAnimation;
  final Animation<double> starAnimation;
  final Size viewBox = const Size(400, 200);

  EnhancedPathPainter({required this.pathAnimation, required this.starAnimation})
      : super(repaint: Listenable.merge([pathAnimation, starAnimation]));

  // Path 1 definition (M 0 120 Q 150 40 250 90 T 400 50)
  Path _getPath1() {
    final path = Path()..moveTo(0, 120);
    path.quadraticBezierTo(150, 40, 250, 90);
    path.quadraticBezierTo(350, 140, 400, 50);
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

    canvas.drawPath(m1.extractPath(0, drawLen1), paint1);
    canvas.drawPath(m2.extractPath(0, drawLen2), paint2);

    // --- Moving star ---
    if (starAnimation.value > 0.0) {
      // Compute midpoint path between top & bottom lines
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
          opacity = (1.0 - invisibleFracEnd - starAnimation.value) / 0.1;
        } else {
          opacity = 0.0;
        }

        // Paint the star
        canvas.save();
        canvas.translate(tangent.position.dx, tangent.position.dy);
        canvas.scale(1 / scaleX, 1 / scaleY);

        final star = _createStarShape(starSize);

        // Custom Paint for Glow
        final starPaint = Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.outer, 5.0);

        canvas.drawPath(star, starPaint); // Draw glow layer

        final starPaintSolid = Paint()
          ..color = Colors.white.withOpacity(opacity);

        canvas.drawPath(star, starPaintSolid); // Draw solid star layer

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant EnhancedPathPainter oldDelegate) => true;
}