import 'package:shared_preferences/shared_preferences.dart';

/// Centralized service for managing app preferences
/// Handles voice mode and language preferences persistence
class PreferencesManager {
  static const String _keyVoiceModeEnabled = 'voice_mode_enabled';
  static const String _keyLanguage = 'selected_language'; // 'en', 'ur', or 'bilingual'

  static SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Voice Mode Preferences
  static Future<bool> isVoiceModeEnabled() async {
    await init();
    return _prefs!.getBool(_keyVoiceModeEnabled) ?? false;
  }

  static Future<void> setVoiceModeEnabled(bool enabled) async {
    await init();
    await _prefs!.setBool(_keyVoiceModeEnabled, enabled);
  }

  /// Language Preferences
  static Future<String> getLanguage() async {
    await init();
    return _prefs!.getString(_keyLanguage) ?? 'en';
  }

  static Future<void> setLanguage(String language) async {
    await init();
    await _prefs!.setString(_keyLanguage, language);
  }

  /// Clear all preferences (useful for testing or logout)
  static Future<void> clearAll() async {
    await init();
    await _prefs!.clear();
  }
}

