import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:nav_aif_fyp/services/preferences_manager.dart';

/// Simple localization helper used across the app.
/// Responsibilities:
/// - Load language JSON from assets/langs/<code>.json
/// - Provide a synchronous lookup via `Lang.t(key)` after init/load
class Lang {
  static String _currentLanguage = 'en';
  static Map<String, String> _localizedStrings = {};

  /// Returns true when the currently loaded language is Urdu
  static bool get isUrdu => _currentLanguage == 'ur';

  /// A small speech-locale identifier (not required by all callers).
  /// Note: PreferencesManager.getSpeechLocale() should be preferred where needed.
  static String get speechLocaleId => _currentLanguage == 'ur' ? 'ur_PK' : 'en_US';

  /// Initialize and load the saved language (uses PreferencesManager).
  static Future<void> init() async {
    final saved = await PreferencesManager.getLanguage();
    await loadLanguage(saved);
  }

  /// Load the JSON file for the given language code (e.g. 'en', 'ur').
  static Future<void> loadLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    final String jsonString =
        await rootBundle.loadString('assets/langs/$languageCode.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
  }

  /// Set language and persist via PreferencesManager.
  static Future<void> setLanguage(String languageCode) async {
    await PreferencesManager.setLanguage(languageCode);
    await loadLanguage(languageCode);
  }

  /// Translate key -> value. Returns the key when missing.
  static String t(String key) {
    return _localizedStrings[key] ?? key;
  }
}
