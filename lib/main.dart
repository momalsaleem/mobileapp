import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

class NavAIIntro extends StatefulWidget {
  const NavAIIntro({super.key});

  @override
  State<NavAIIntro> createState() => _NavAIIntroState();
}

class _NavAIIntroState extends State<NavAIIntro> with TickerProviderStateMixin {
  late AnimationController _pathController;
  late AnimationController _starController;
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _showChoices = false;
  bool _isTalkBackEnabled = false;
  bool _micPermissionGranted = false;
  bool _listening = false;

  static const platform = MethodChannel('navai/accessibility');

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkTalkBackStatus();
  }

  Future<void> _checkTalkBackStatus() async {
    try {
      final bool result = await platform.invokeMethod('isTalkBackEnabled');
      setState(() => _isTalkBackEnabled = result);
    } on PlatformException catch (e) {
      debugPrint("Error checking TalkBack: ${e.message}");
    }
  }

  Future<void> _checkMicPermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      setState(() => _micPermissionGranted = true);
    } else {
      setState(() => _micPermissionGranted = false);
    }
  }

  Future<void> _requestMicPermission() async {
    var status = await Permission.microphone.request();
    setState(() => _micPermissionGranted = status.isGranted);
  }

  void _initializeAnimations() {
    _pathController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _starController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 7000));

    _pathController.forward(from: 0.0);
    _pathController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _starController.forward(from: 0.0);
      }
    });

    _starController.addStatusListener((status) async {
      if (status == AnimationStatus.forward) {
        await _startIntroVoice();
      }
    });
  }

  Future<void> _startIntroVoice() async {
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.awaitSpeakCompletion(true);

    String? deviceLang = ui.window.locale.languageCode;
    bool isUrdu = (deviceLang == 'ur');

    await _checkMicPermission();

    if (!_isTalkBackEnabled) {
      await _speakBothLang(
        en: 'Please enable TalkBack from accessibility settings for voice guidance.',
        ur: 'براہ کرم ٹاک بیک کو سیٹنگز سے آن کریں تاکہ آپ کو آواز سے رہنمائی مل سکے۔',
      );
    } else if (!_micPermissionGranted) {
      await _speakBothLang(
        en: 'Microphone access is needed. Say "Allow" or tap Allow when asked.',
        ur: 'مائیکروفون کی اجازت درکار ہے۔ اجازت دینے کے لیے "اجازت دیں" کہیں۔',
      );
      await _listenForAllowCommand();
    } else {
      await _speakBothLang(
        en: 'Welcome to Nav AI. Do you want to continue by typing or speaking?',
        ur: 'نیو اے آئی میں خوش آمدید۔ کیا آپ ٹائپ کرنا چاہتے ہیں یا بول کر؟',
      );
      setState(() => _showChoices = true);
    }
  }

  Future<void> _speakBothLang({required String en, required String ur}) async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.speak(en);
    await Future.delayed(const Duration(seconds: 1));
    await _flutterTts.setLanguage('ur-PK');
    await _flutterTts.speak(ur);
  }

  Future<void> _listenForAllowCommand() async {
    bool available = await _speech.initialize(
      onStatus: (status) => debugPrint('Speech status: $status'),
      onError: (error) => debugPrint('Speech error: $error'),
    );

    if (available) {
      setState(() => _listening = true);
      await _flutterTts.speak(
        'Please say Allow to grant microphone permission.',
      );
      _speech.listen(onResult: (result) async {
        final text = result.recognizedWords.toLowerCase();
        if (text.contains('allow') || text.contains('اجازت')) {
          await _speech.stop();
          setState(() => _listening = false);
          await _requestMicPermission();
          if (_micPermissionGranted) {
            await _flutterTts.speak('Microphone permission granted. Thank you.');
            await _startIntroVoice(); // Continue normally
          } else {
            await _flutterTts.speak('Microphone permission denied.');
          }
        }
      });
    } else {
      await _flutterTts.speak('Speech recognition not available on this device.');
    }
  }

  Future<void> _openAccessibilitySettings() async {
    try {
      await platform.invokeMethod('openAccessibilitySettings');
    } on PlatformException catch (e) {
      debugPrint("Error opening accessibility settings: ${e.message}");
    }
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([_pathController, _starController]),
              builder: (context, child) {
                return CustomPaint(
                  painter: _PathPainter(
                    pathProgress: _pathController.value,
                    starProgress: _starController.value,
                  ),
                  size: const Size(300, 300),
                );
              },
            ),
            const SizedBox(height: 30),
            if (_showChoices)
              Column(
                children: [
                  if (!_isTalkBackEnabled)
                    ElevatedButton(
                      onPressed: _openAccessibilitySettings,
                      child: const Text('Enable TalkBack'),
                    ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Typing flow selected')),
                      );
                    },
                    child: const Text('Continue by Typing'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Speech flow selected')),
                      );
                    },
                    child: const Text('Continue with Speech'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  final double pathProgress;
  final double starProgress;

  _PathPainter({required this.pathProgress, required this.starProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.8)
      ..quadraticBezierTo(
          size.width * 0.5, size.height * 0.1, size.width * 0.9, size.height * 0.8);

    final metric = path.computeMetrics().first;
    final extractPath = metric.extractPath(0, metric.length * pathProgress);
    canvas.drawPath(extractPath, paint);

    if (starProgress > 0) {
      final pos = metric.getTangentForOffset(metric.length * starProgress);
      if (pos != null) {
        final starPaint = Paint()..color = Colors.yellowAccent;
        canvas.drawCircle(pos.position, 6, starPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_PathPainter oldDelegate) {
    return oldDelegate.pathProgress != pathProgress ||
        oldDelegate.starProgress != starProgress;
  }
}
