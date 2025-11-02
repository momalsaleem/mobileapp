import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:nav_aif_fyp/pages/page_one.dart';
import 'package:nav_aif_fyp/services/preferences_manager.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Legacy class for backward compatibility
/// Use PreferencesManager for new code
class TTSPreference {
  static bool enabled = false;
  static String language = 'en';
}

/// Language translation service
/// Provides centralized translation using Lang.t(key)
class Lang {
  static String _currentLanguage = 'en';

  /// Initialize language from preferences
  static Future<void> init() async {
    _currentLanguage = await PreferencesManager.getLanguage();
  }

  /// Get current language code
  static String get currentLanguage => _currentLanguage;

  /// Set current language
  static Future<void> setLanguage(String language) async {
    _currentLanguage = language;
    await PreferencesManager.setLanguage(language);
  }

  /// Translation map for English and Urdu
  static const Map<String, Map<String, String>> _translations = {
    // Common UI
    'welcome': {
      'en': 'Welcome',
      'ur': 'خوش آمدید',
    },
    'language': {
      'en': 'Language',
      'ur': 'زبان',
    },
    'save': {
      'en': 'Save',
      'ur': 'محفوظ کریں',
    },
    'continue': {
      'en': 'Continue',
      'ur': 'جاری رکھیں',
    },
    'select_location': {
      'en': 'Select Location',
      'ur': 'مقام منتخب کریں',
    },
    'where_are_you': {
      'en': 'Where are you right now? Please select your current location.',
      'ur': 'آپ اب کہاں ہیں؟ براہ کرم اپنا موجودہ مقام منتخب کریں۔',
    },
    'home': {
      'en': 'At Home',
      'ur': 'گھر پر',
    },
    'work': {
      'en': 'Workplace',
      'ur': 'دفتر',
    },
    'college': {
      'en': 'College',
      'ur': 'کالج',
    },
    'university': {
      'en': 'University',
      'ur': 'یونیورسٹی',
    },
    'name_question': {
      'en': 'What should NavAI call you? You can say your name or type it in the text field.',
      'ur': 'NavAI آپ کو کیا پکارے؟ آپ اپنا نام بولیں یا متن فیلڈ میں ٹائپ کریں۔',
    },
    'your_name': {
      'en': 'Your name',
      'ur': 'آپ کا نام',
    },
    'save_continue': {
      'en': 'Save & Continue',
      'ur': 'محفوظ کریں اور جاری رکھیں',
    },
    'navai': {
      'en': 'NavAI',
      'ur': 'نیو اے آئی',
    },
    // Page 3 - Navigation Mode
    'select_nav_mode': {
      'en': 'Select your preferred navigation mode.',
      'ur': 'اپنا پسندیدہ نیویگیشن موڈ منتخب کریں۔',
    },
    'nav_mode_intro': {
      'en': 'Select your preferred navigation mode. Here are your available options.',
      'ur': 'اپنا پسندیدہ نیویگیشن موڈ منتخب کریں۔ یہاں آپ کے دستیاب اختیارات ہیں۔',
    },
    'voice_only': {
      'en': 'Voice Only',
      'ur': 'صرف آواز',
    },
    'voice_only_desc': {
      'en': 'Clear, spoken directions',
      'ur': 'واضح، بولی جانے والی ہدایات',
    },
    'voice_haptic': {
      'en': 'Voice + Haptic',
      'ur': 'آواز + ہیپٹک',
    },
    'voice_haptic_desc': {
      'en': 'Spoken directions with vibration cues',
      'ur': 'کمپن کی نشانوں کے ساتھ بولی جانے والی ہدایات',
    },
    'sound_voice': {
      'en': 'Sound Cues + Voice',
      'ur': 'آواز کے اشارے + آواز',
    },
    'sound_voice_desc': {
      'en': 'Ambient sounds and spoken directions',
      'ur': 'ماحولی آوازیں اور بولی جانے والی ہدایات',
    },
    'skip': {
      'en': 'Skip',
      'ur': 'چھوڑیں',
    },
    'selected_nav_mode': {
      'en': 'You selected',
      'ur': 'آپ نے منتخب کیا',
    },
    'navigating_next': {
      'en': 'Navigating to the next page.',
      'ur': 'اگلے صفحے پر جا رہے ہیں۔',
    },
    // Page 4 - Dashboard
    'dashboard_welcome': {
      'en': 'Welcome to your dashboard. You can choose: Object Detection, Navigation, Saved Routes, or Guide. You can also say Settings or Profile to navigate.',
      'ur': 'اپنے ڈیش بورڈ میں خوش آمدید۔ آپ منتخب کر سکتے ہیں: آبجیکٹ ڈیٹیکشن، نیویگیشن، محفوظ راستے، یا گائیڈ۔ آپ سیٹنگز یا پروفائل بھی کہہ سکتے ہیں۔',
    },
    'object_detection': {
      'en': 'Object Detection',
      'ur': 'آبجیکٹ ڈیٹیکشن',
    },
    'object_detection_desc': {
      'en': 'Identify objects in real-time',
      'ur': 'حقیقی وقت میں اشیاء کی شناخت کریں',
    },
    'navigation': {
      'en': 'Navigation',
      'ur': 'نیویگیشن',
    },
    'navigation_desc': {
      'en': 'Turn-by-turn directions',
      'ur': 'موڑ بہ موڑ ہدایات',
    },
    'saved_routes': {
      'en': 'Saved Routes',
      'ur': 'محفوظ راستے',
    },
    'saved_routes_desc': {
      'en': 'Access your frequent routes',
      'ur': 'اپنے اکثر استعمال ہونے والے راستوں تک رسائی حاصل کریں',
    },
    'guide': {
      'en': 'Guide',
      'ur': 'گائیڈ',
    },
    'guide_desc': {
      'en': 'Access complete guide',
      'ur': 'مکمل گائیڈ تک رسائی حاصل کریں',
    },
    'home_menu': {'en': 'Home', 'ur': 'ہوم'},
    'settings': {
      'en': 'Settings',
      'ur': 'سیٹنگز',
    },
    'profile': {
      'en': 'Profile',
      'ur': 'پروفائل',
    },
    // Privacy
    'privacy_title': {
      'en': 'Privacy & Security',
      'ur': 'پرائیویسی اور سیکیورٹی',
    },
    'location_services': {
      'en': 'Location Services',
      'ur': 'لوکیشن سروسز',
    },
    'location_services_desc': {
      'en': 'Manage location permissions and accuracy',
      'ur': 'لوکیشن کی اجازت اور درستگی کو منظم کریں',
    },
    'data_security': {
      'en': 'Data Security',
      'ur': 'ڈیٹا سیکیورٹی',
    },
    'data_security_desc': {
      'en': 'Control how your data is stored and protected',
      'ur': 'اپنے ڈیٹا کے محفوظ اور محفوظ رہنے کے طریقے کو کنٹرول کریں',
    },
    'data_sharing': {
      'en': 'Data Sharing',
      'ur': 'ڈیٹا شیئرنگ',
    },
    'data_sharing_desc': {
      'en': 'Control what data is shared with third parties',
      'ur': 'تیسرے فریق کے ساتھ کون سا ڈیٹا شیئر ہوتا ہے کنٹرول کریں',
    },
    'delete_data': {
      'en': 'Delete Data',
      'ur': 'ڈیٹا حذف کریں',
    },
    'delete_data_desc': {
      'en': 'Remove your stored data and routes',
      'ur': 'اپنا محفوظ شدہ ڈیٹا اور راستے حذف کریں',
    },
    'privacy_policy': {
      'en': 'Privacy Policy',
      'ur': 'پرائیویسی پالیسی',
    },
    'privacy_policy_desc': {
      'en': 'Read our privacy policy and terms',
      'ur': 'ہماری پرائیویسی پالیسی اور شرائط پڑھیں',
    },
    // Settings
    'settings_title': {
      'en': 'Settings',
      'ur': 'سیٹنگز',
    },
    'settings_welcome': {
      'en': 'Welcome to settings. You can manage your account, privacy, notifications, and view app information. Say the name of any setting to open it.',
      'ur': 'سیٹنگز میں خوش آمدید۔ آپ اپنے اکاؤنٹ، پرائیویسی، نوٹیفیکیشنز کو منظم کر سکتے ہیں، اور ایپ کی معلومات دیکھ سکتے ہیں۔ کسی بھی سیٹنگ کو کھولنے کے لیے اس کا نام کہیں۔',
    },
    'account': {
      'en': 'Account',
      'ur': 'اکاؤنٹ',
    },
    'account_desc': {
      'en': 'Manage your account settings',
      'ur': 'اپنی اکاؤنٹ کی سیٹنگز منظم کریں',
    },
    'privacy': {
      'en': 'Privacy',
      'ur': 'پرائیویسی',
    },
    'privacy_desc': {
      'en': 'Privacy and security options',
      'ur': 'پرائیویسی اور سیکیورٹی کے اختیارات',
    },
    'notifications': {
      'en': 'Notifications',
      'ur': 'نوٹیفیکیشنز',
    },
    'notifications_desc': {
      'en': 'Notification preferences',
      'ur': 'نوٹیفیکیشن کی ترجیحات',
    },
    'about': {
      'en': 'About',
      'ur': 'مزید معلومات',
    },
    'about_desc': {
      'en': 'App information',
      'ur': 'ایپ کی معلومات',
    },
    // Profile
    'profile_title': {
      'en': 'Profile',
      'ur': 'پروفائل',
    },
    'user_info': {
      'en': 'User Info',
      'ur': 'صارف کی معلومات',
    },
    'name': {
      'en': 'Name',
      'ur': 'نام',
    },
    'voice_id': {
      'en': 'Voice ID',
      'ur': 'آواز کی شناخت',
    },
    'preferences': {
      'en': 'Preferences',
      'ur': 'ترجیحات',
    },
    'preferred_language': {
      'en': 'Preferred Language',
      'ur': 'پسندیدہ زبان',
    },
    'preferred_nav_mode': {
      'en': 'Preferred Navigation Mode',
      'ur': 'پسندیدہ نیویگیشن موڈ',
    },
    'voice_only_mode': {
      'en': 'Voice-only',
      'ur': 'صرف آواز',
    },
    'haptic_only_mode': {
      'en': 'Haptic-only',
      'ur': 'صرف ہیپٹک',
    },
    'both_mode': {
      'en': 'Both',
      'ur': 'دونوں',
    },
    'saved_locations': {
      'en': 'Saved Locations',
      'ur': 'محفوظ مقامات',
    },
    'add_location': {
      'en': 'Add Location',
      'ur': 'مقام شامل کریں',
    },
    // Common voice commands feedback
    'opening': {
      'en': 'Opening',
      'ur': 'کھول رہے ہیں',
    },
    'selected': {
      'en': 'selected',
      'ur': 'منتخب کیا',
    },
    'listening': {
      'en': 'Listening...',
      'ur': 'سن رہے ہیں...',
    },
    'please_repeat': {
      'en': "I didn't catch that. Please repeat your command.",
      'ur': 'میں نے یہ نہیں سنا۔ براہ کرم اپنا حکم دوبارہ کہیں۔',
    },
    'try_again': {
      'en': "Could you please say that again?",
      'ur': 'کیا آپ براہ کرم دوبارہ کہہ سکتے ہیں؟',
    },
    'not_understood': {
      'en': "Sorry, I didn't understand. Please try again.",
      'ur': 'معذرت، میں سمجھ نہیں پایا۔ براہ کرم دوبارہ کوشش کریں۔',
    },
  };

  /// Get the appropriate locale ID for speech recognition based on current language
  static String get speechLocaleId {
    if (_currentLanguage == 'ur') {
      return 'ur-PK'; // Urdu (Pakistan)
    } else {
      return 'en-US'; // English (US)
    }
  }

  /// Get translated text for a key
  /// Returns English if translation not found
  static String t(String key) {
    if (_currentLanguage == 'ur') {
      final translation = _translations[key];
      if (translation != null && translation.containsKey('ur')) {
        return translation['ur'] ?? translation['en'] ?? key;
      }
    }
    // Default to English
    return _translations[key]?['en'] ?? key;
  }

  /// Check if current language is Urdu
  static bool get isUrdu => _currentLanguage == 'ur';
}

class NavAILanguagePage extends StatelessWidget {
  const NavAILanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LanguageSelectionScreen();
  }
}

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  String selectedLanguage = "English";
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _initTTS();
    _startListening();
  }

  Future<void> _loadPreferences() async {
    await Lang.init();
    final savedLanguage = await PreferencesManager.getLanguage();
    if (savedLanguage == 'ur') {
      selectedLanguage = "Urdu";
    } else {
      selectedLanguage = "English";
    }
  }

  Future<void> _initTTS() async {
    final isUrdu = Lang.isUrdu;
    if (isUrdu) {
      try {
        await flutterTts.setLanguage('ur-PK');
      } catch (_) {
        await flutterTts.setLanguage('en-US');
      }
    } else {
      await flutterTts.setLanguage("en-US");
    }
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
    
    // Language selection page always speaks in English for initial setup
    await flutterTts.setLanguage("en-US");
    await flutterTts.speak(
      "Select your language. Say Urdu for Urdu interface, or English for English interface.",
    );
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
          localeId: Lang.speechLocaleId,
          onResult: (result) {
            String recognized = result.recognizedWords.toLowerCase().trim();
            if (recognized.isNotEmpty) {
              _processCommand(recognized);
            }
          },
        );
      } else {
        setState(() => _isListening = false);
      }
    });
  }

  void _processCommand(String recognized) async {
    debugPrint("🎙 Recognized: $recognized");
    bool commandMatched = false;
    
    // Support both English and Urdu commands
    if (recognized.contains('urdu') || recognized.contains('اردو')) {
      _selectLanguageAndNavigate("Urdu");
      commandMatched = true;
    } else if (recognized.contains('english') || recognized.contains('انگریزی')) {
      _selectLanguageAndNavigate("English");
      commandMatched = true;
    }
    
    // If command not recognized, ask to repeat
    if (!commandMatched && recognized.length > 2) {
      await _askToRepeat();
    }
  }

  Future<void> _askToRepeat() async {
    await _initTTS();
    await flutterTts.speak("I didn't catch that. Please say Urdu or English.");
    await flutterTts.awaitSpeakCompletion(true);
  }

  void _selectLanguageAndNavigate(String language) async {
    _speech.stop();
    setState(() {
      _isListening = false;
      selectedLanguage = language;

      // Save language preference using PreferencesManager
      if (language == "Urdu") {
        TTSPreference.enabled = true;
        TTSPreference.language = 'ur';
        Lang.setLanguage('ur');
        PreferencesManager.setLanguage('ur');
      } else {
        TTSPreference.enabled = false;
        TTSPreference.language = 'en';
        Lang.setLanguage('en');
        PreferencesManager.setLanguage('en');
      }
    });

    _speakSelection(language).then((_) {
      Future.delayed(const Duration(seconds: 2)).then((_) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const NameInputPage()),
          );
        }
      });
    });
  }

  Future<void> _speakSelection(String language) async {
    await flutterTts.setLanguage("en-US");
    if (language == "Urdu") {
      await flutterTts.speak("You selected Urdu language interface.");
    } else {
      await flutterTts.speak("You selected English language interface.");
    }
  }

  Widget _buildLanguageOption(String language) {
    final bool isSelected = selectedLanguage == language;
    return GestureDetector(
      onTap: () => _selectLanguageAndNavigate(language),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1349EC).withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: const Color(0xFF1349EC), width: 2)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              language,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Radio<String>(
              value: language,
              groupValue: selectedLanguage,
              onChanged: (value) {
                if (value != null) _selectLanguageAndNavigate(value);
              },
              activeColor: const Color(0xFF1349EC),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1b2a),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/', (route) => false);
                    },
                  ),
                  Expanded(
                    child: Text(
                      Lang.t('language'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildLanguageOption("Urdu"),
                    const SizedBox(height: 12),
                    _buildLanguageOption("English"),
                    const SizedBox(height: 20),
                    if (_isListening)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.mic,
                                size: 16, color: Colors.greenAccent),
                            SizedBox(width: 8),
                            Text(
                              'Listening... Say "Urdu" or "English"',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1349EC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    _selectLanguageAndNavigate(selectedLanguage);
                  },
                  child: Text(
                    Lang.t('save'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
}