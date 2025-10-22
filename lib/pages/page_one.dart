import 'package:flutter/material.dart';
import 'package:nav_aif_fyp/pages/page_two.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class NameInputPage extends StatefulWidget {
  const NameInputPage({super.key});

  @override
  State<NameInputPage> createState() => _NameInputPageState();
}

class _NameInputPageState extends State<NameInputPage> {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _nameController = TextEditingController();
  bool _isListening = false;

  String get _instructionText => 'What should NavAI call you? You can say your name or type it in the text field.';

  @override
  void initState() {
    super.initState();
    _initTTS();
    _startListening();
  }

  void _initTTS() {
    // Always speak in English
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.5);
    _tts.speak(_instructionText);
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
          localeId: 'en-US',
          onResult: (result) {
            String recognized = result.recognizedWords.toLowerCase().trim();
            _processCommand(recognized);
          },
        );
      } else {
        setState(() => _isListening = false);
      }
    });
  }

  void _processCommand(String recognized) {
    debugPrint("🎙 Name Input Recognized: $recognized");
    
    // If user says their name, set it in the text field and navigate
    if (recognized.isNotEmpty && !recognized.contains('continue') && !recognized.contains('next')) {
      _speech.stop();
      setState(() {
        _isListening = false;
        _nameController.text = recognized; // Set the recognized name
      });
      
      // Speak confirmation and navigate after a short delay
      _tts.speak('Hello $recognized. Moving to location selection.');
      Future.delayed(const Duration(seconds: 2), () {
        _navigateToNext();
      });
    }
  }

  void _navigateToNext() {
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const UseLocationPage(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1b2a),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'NavAI',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _instructionText,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Stack(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: "Your name",
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0xFF9DA4B9),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0xFF1349EC),
                              width: 2,
                            ),
                          ),
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: IconButton(
                          onPressed: () {
                            if (_isListening) {
                              _speech.stop();
                              setState(() => _isListening = false);
                            } else {
                              _startListening();
                            }
                          },
                          icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening ? Colors.red : const Color(0xFF9DA4B9),
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Voice input indicator
                  if (_isListening)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mic, size: 16, color: Colors.red[300]),
                          const SizedBox(width: 8),
                          Text(
                            'Listening for your name...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[300],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1349EC),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      _navigateToNext();
                    },
                    child: const Text(
                      "Save & Continue",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}