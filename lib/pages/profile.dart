import 'package:flutter/material.dart';
import 'package:nav_aif_fyp/pages/settings.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:nav_aif_fyp/pages/lang.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController =
      TextEditingController(text: "Alex Doe");
  String _voiceId = "Female";
  String _language = "English";
  String _navMode = "Both";
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  final List<String> savedLocations = ["Home", "Work", "Grocery", "Doctor"];

  @override
  void initState() {
    super.initState();
    _initTTS();
    _startListening();
  }

  Future<void> _initTTS() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    
    // Always speak in English
    await _tts.speak('Welcome to your profile. Here you can manage your personal information, preferences, and saved locations. Say the name of any setting to change it.');
  }

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
        localeId: 'en-US',
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
    debugPrint("🎙 Profile Recognized: $recognized");
    
    if (recognized.contains('name')) {
      _speech.stop();
      setState(() => _isListening = false);
      _tts.speak('Please say your new name.');
      _startListening();
    } else if (recognized.contains('voice') && recognized.contains('male')) {
      _speech.stop();
      setState(() => _isListening = false);
      setState(() => _voiceId = "Male");
      _tts.speak('Voice changed to male.');
    } else if (recognized.contains('voice') && recognized.contains('female')) {
      _speech.stop();
      setState(() => _isListening = false);
      setState(() => _voiceId = "Female");
      _tts.speak('Voice changed to female.');
    } else if (recognized.contains('language') && recognized.contains('english')) {
      _speech.stop();
      setState(() => _isListening = false);
      setState(() => _language = "English");
      _tts.speak('Language changed to English.');
    } else if (recognized.contains('language') && recognized.contains('urdu')) {
      _speech.stop();
      setState(() => _isListening = false);
      setState(() => _language = "Urdu");
      _tts.speak('Language changed to Urdu.');
    } else if (recognized.contains('language') && recognized.contains('bilingual')) {
      _speech.stop();
      setState(() => _isListening = false);
      setState(() => _language = "Bilingual");
      _tts.speak('Language changed to Bilingual.');
    } else if (recognized.contains('navigation') && recognized.contains('voice')) {
      _speech.stop();
      setState(() => _isListening = false);
      setState(() => _navMode = "Voice-only");
      _tts.speak('Navigation mode changed to voice only.');
    } else if (recognized.contains('navigation') && recognized.contains('haptic')) {
      _speech.stop();
      setState(() => _isListening = false);
      setState(() => _navMode = "Haptic-only");
      _tts.speak('Navigation mode changed to haptic only.');
    } else if (recognized.contains('navigation') && recognized.contains('both')) {
      _speech.stop();
      setState(() => _isListening = false);
      setState(() => _navMode = "Both");
      _tts.speak('Navigation mode changed to both voice and haptic.');
    } else if (recognized.isNotEmpty && !recognized.contains('voice') && !recognized.contains('language') && !recognized.contains('navigation') && !recognized.contains('male') && !recognized.contains('female') && !recognized.contains('english') && !recognized.contains('urdu') && !recognized.contains('bilingual') && !recognized.contains('haptic') && !recognized.contains('both')) {
      // This might be a new name
      _speech.stop();
      setState(() => _isListening = false);
      _nameController.text = recognized;
      _tts.speak('Name updated to $recognized.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1b2a),
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF0d1b2a),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
            _sectionTitle("User Info"),
            _card(
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "Name"),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _voiceId,
                    decoration: const InputDecoration(labelText: "Voice ID"),
                    items: ["Male", "Female", "System"]
                        .map((v) =>
                            DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => _voiceId = v!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle("Preferences"),
            _card(
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _language,
                    decoration: const InputDecoration(
                        labelText: "Preferred Language"),
                    items: ["English", "Urdu", "Bilingual"]
                        .map((v) =>
                            DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => _language = v!),
                  ),
                  const SizedBox(height: 20),
                  const Text("Preferred Navigation Mode",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ToggleButtons(
                    isSelected: ["Voice-only", "Haptic-only", "Both"]
                        .map((m) => _navMode == m)
                        .toList(),
                    onPressed: (index) {
                      setState(() {
                        _navMode = ["Voice-only", "Haptic-only", "Both"][index];
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    selectedColor: Colors.white,
                    fillColor: Theme.of(context).colorScheme.primary,
                    children: const [
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text("Voice-only")),
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text("Haptic-only")),
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text("Both")),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle("Saved Locations"),
            _card(
              child: Column(
                children: [
                  for (var loc in savedLocations)
                    ListTile(
                      title: Text(loc),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              icon: const Icon(Icons.edit), onPressed: () {}),
                          IconButton(
                              icon: const Icon(Icons.delete), onPressed: () {}),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.2),
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {},
              child: const Text("Add Location"),
            ),
              ],
            ),
          ),
          // Voice command indicator
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
                    'Listening... Say "name", "voice male/female", "language english/urdu/bilingual", "navigation voice/haptic/both"',
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
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color(0xFF0d1b2a),
          selectedItemColor: const Color(0xFF2563eb),
          unselectedItemColor: Colors.white60,
          currentIndex: 2,
          onTap: (index) {
            if (index == 0) {
              Navigator.of(context).pushReplacementNamed('/');
            } else if (index == 1) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
            BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: "Saved Routes"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      );
  }

  /// ✅ Helper methods placed inside the class
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Card(
      color: const Color(0xFF1a2233),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _nameController.dispose();
    super.dispose();
  }
}
