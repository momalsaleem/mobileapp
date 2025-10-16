import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:nav_aif_fyp/pages/lang.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SettingsPage extends StatefulWidget {
	const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

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
    await _tts.speak('Welcome to settings. You can manage your account, privacy, notifications, and view app information. Say the name of any setting to open it.');
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
    debugPrint("🎙 Settings Recognized: $recognized");
    
    if (recognized.contains('account')) {
      _speech.stop();
      setState(() => _isListening = false);
      _tts.speak('Opening account settings.');
      // TODO: Navigate to account settings
    } else if (recognized.contains('privacy')) {
      _speech.stop();
      setState(() => _isListening = false);
      _tts.speak('Opening privacy settings.');
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const PrivacyPage()),
      );
    } else if (recognized.contains('notification')) {
      _speech.stop();
      setState(() => _isListening = false);
      _tts.speak('Opening notification settings.');
      // TODO: Navigate to notification settings
    } else if (recognized.contains('about')) {
      _speech.stop();
      setState(() => _isListening = false);
      _tts.speak('Showing about information.');
      // TODO: Show about dialog
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
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF0d1b2a),
      ),
			body: Column(
				children: [
					Expanded(
						child: ListView(
							padding: const EdgeInsets.all(16),
							children: [
								// Guide: Make all cards clickable for navigation or actions
								_settingsCard(
									icon: Icons.person,
									title: 'Account',
									subtitle: 'Manage your account settings',
									onTap: () {
										_speech.stop();
										setState(() => _isListening = false);
										_tts.speak('Opening account settings.');
										// TODO: Navigate to account settings
									},
								),
								_settingsCard(
									icon: Icons.lock,
									title: 'Privacy',
									subtitle: 'Privacy and security options',
									onTap: () {
										_speech.stop();
										setState(() => _isListening = false);
										_tts.speak('Opening privacy settings.');
										Navigator.of(context).push(
											MaterialPageRoute(builder: (context) => const PrivacyPage()),
										);
									},
								),
								_settingsCard(
									icon: Icons.notifications,
									title: 'Notifications',
									subtitle: 'Notification preferences',
									onTap: () {
										_speech.stop();
										setState(() => _isListening = false);
										_tts.speak('Opening notification settings.');
										// TODO: Navigate to notification settings
									},
								),
								_settingsCard(
									icon: Icons.info,
									title: 'About',
									subtitle: 'App information',
									onTap: () {
										_speech.stop();
										setState(() => _isListening = false);
										_tts.speak('Showing about information.');
										// TODO: Show about dialog
									},
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
										'Listening... Say "account", "privacy", "notifications", or "about"',
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
		);
	}

	Widget _settingsCard({
		required IconData icon,
		required String title,
		required String subtitle,
		required VoidCallback onTap,
	}) {
		return InkWell(
			onTap: onTap,
			borderRadius: BorderRadius.circular(12),
			child: Container(
				margin: const EdgeInsets.only(bottom: 16),
				padding: const EdgeInsets.all(16),
				decoration: BoxDecoration(
					color: Colors.white.withOpacity(0.05),
					borderRadius: BorderRadius.circular(12),
				),
				child: Row(
					children: [
						Container(
							padding: const EdgeInsets.all(12),
							decoration: BoxDecoration(
								color: const Color(0xFF2563eb).withOpacity(0.25),
								shape: BoxShape.circle,
							),
							child: Icon(icon, color: const Color(0xFF2563eb)),
						),
						const SizedBox(width: 16),
						Expanded(
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text(
										title,
										style: const TextStyle(
											fontWeight: FontWeight.bold,
											fontSize: 18,
											color: Colors.white,
										),
									),
									const SizedBox(height: 4),
									Text(
										subtitle,
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
		);
	}

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}
