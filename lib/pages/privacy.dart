import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:nav_aif_fyp/pages/lang.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTTS();
  }

  Future<void> _initTTS() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    
    // Only speak if user selected "continue with voice" (English mode)
    if (TTSPreference.enabled && TTSPreference.language == 'en') {
      await _tts.speak('Privacy and Security Settings. Here you can manage your data privacy, location permissions, and security preferences.');
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
        title: const Text('Privacy & Security'),
        backgroundColor: const Color(0xFF0d1b2a),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _privacyCard(
            icon: Icons.location_on,
            title: 'Location Services',
            subtitle: 'Manage location permissions and accuracy',
            onTap: () {
              _speakIfEnabled('Location Services. You can control how the app uses your location data for navigation.');
            },
          ),
          _privacyCard(
            icon: Icons.security,
            title: 'Data Security',
            subtitle: 'Control how your data is stored and protected',
            onTap: () {
              _speakIfEnabled('Data Security. Manage how your personal data and routes are secured and stored.');
            },
          ),
          _privacyCard(
            icon: Icons.share,
            title: 'Data Sharing',
            subtitle: 'Control what data is shared with third parties',
            onTap: () {
              _speakIfEnabled('Data Sharing. Control whether your anonymous usage data is shared to improve the app.');
            },
          ),
          _privacyCard(
            icon: Icons.delete,
            title: 'Delete Data',
            subtitle: 'Remove your stored data and routes',
            onTap: () {
              _speakIfEnabled('Delete Data. You can permanently delete your stored routes and personal data.');
            },
          ),
          _privacyCard(
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy and terms',
            onTap: () {
              _speakIfEnabled('Privacy Policy. Review our complete privacy policy and terms of service.');
            },
          ),
        ],
      ),
    );
  }

  Widget _privacyCard({
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
          color: Colors.white.withValues(alpha: 13), // 0.05 * 255 ≈ 13
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2563eb).withValues(alpha: 64), // 0.25 * 255 ≈ 64
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
                      color: Colors.white.withValues(alpha: 153), // 0.6 * 255 ≈ 153
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

  void _speakIfEnabled(String text) {
    if (TTSPreference.enabled && TTSPreference.language == 'en') {
      _tts.speak(text);
    }
  }
}