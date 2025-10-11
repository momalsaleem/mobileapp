import 'package:flutter/material.dart';
import 'package:nav_aif_fyp/pages/page_two.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:nav_aif_fyp/pages/lang.dart';

class NameInputPage extends StatefulWidget {
  const NameInputPage({super.key});

  @override
  State<NameInputPage> createState() => _NameInputPageState();
}

class _NameInputPageState extends State<NameInputPage> {
  final FlutterTts _tts = FlutterTts();

  String get _instructionText =>
      TTSPreference.language == 'ur'
          ? 'NavAI آپ کو کیا پکارے؟'
          : 'What should NavAI call you?';

  @override
  void initState() {
    super.initState();
    if (TTSPreference.enabled) {
      final lang = TTSPreference.language == 'ur' ? 'ur-PK' : 'en-US';
      _tts.setLanguage(lang);
      _tts.setSpeechRate(0.5);
      _tts.speak(_instructionText);
    }
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
                        decoration: InputDecoration(
                          hintText: "Your name",
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
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
                          onPressed: () {},
                          icon: const Icon(
                            Icons.mic,
                            color: Color(0xFF9DA4B9),
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1349EC),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const UseLocationPage(),
                        ),
                      );
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
