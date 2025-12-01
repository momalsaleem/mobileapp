import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

/// Safe wrappers for TTS and STT with proper initialization sequencing
class VoiceManager {
  static bool _isMicrophoneInitialized = false;
  static bool _isInitializing = false;

  /// Safely speak text. On web this will be skipped to avoid engine errors.
  static Future<void> safeSpeak(FlutterTts tts, String text) async {
    if (kIsWeb) {
      debugPrint('TTS skipped on Web: $text');
      return;
    }
    try {
      await tts.speak(text);
    } catch (e, st) {
      debugPrint('TTS error: $e');
      debugPrint('$st');
    }
  }

  /// Safely await speak completion if available. No-op on web.
  static Future<void> safeAwaitSpeakCompletion(FlutterTts tts) async {
    if (kIsWeb) return;
    try {
      await tts.awaitSpeakCompletion(true);
    } catch (e) {
      debugPrint('awaitSpeakCompletion error: $e');
    }
  }

  /// Initialize microphone AFTER all TTS is complete
  /// This prevents audio conflicts and ensures smooth page reading
  static Future<bool> initializeMicrophoneAfterSpeaking({
    required stt.SpeechToText speech,
    required FlutterTts tts,
    void Function(String)? onStatus,
    void Function(dynamic)? onError,
  }) async {
    if (kIsWeb) {
      debugPrint('Microphone initialization skipped on Web');
      return false;
    }

    // Prevent multiple simultaneous initialization attempts
    if (_isInitializing) {
      debugPrint('⚠️ Microphone initialization already in progress');
      return _isMicrophoneInitialized;
    }

    _isInitializing = true;

    try {
      // Step 1: Ensure TTS is completely stopped
      debugPrint('🔇 Stopping TTS before microphone init...');
      try {
        await tts.stop();
        // Small delay to ensure audio resources are released
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        debugPrint('Error stopping TTS: $e');
      }

      // Step 2: Request microphone permission
      debugPrint('🎤 Requesting microphone permission...');
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        debugPrint('❌ Microphone permission denied');
        _isInitializing = false;
        return false;
      }

      // Step 3: Stop any existing speech session
      try {
        await speech.stop();
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        debugPrint('Error stopping previous speech session: $e');
      }

      // Step 4: Initialize speech recognizer
      debugPrint('🎙️ Initializing speech recognizer...');
      final available = await speech.initialize(
        onStatus: (status) {
          debugPrint('🎙️ Speech status: $status');
          if (onStatus != null) onStatus(status);
        },
        onError: (error) {
          debugPrint('❌ Speech error: $error');
          _isMicrophoneInitialized = false;
          if (onError != null) onError(error);
        },
      );

      if (!available) {
        debugPrint('❌ Speech recognizer not available');
        _isMicrophoneInitialized = false;
        _isInitializing = false;
        return false;
      }

      _isMicrophoneInitialized = true;
      _isInitializing = false;
      debugPrint('✅ Microphone initialized successfully');
      return true;

    } catch (e, st) {
      debugPrint('❌ Microphone initialization error: $e');
      debugPrint('$st');
      _isMicrophoneInitialized = false;
      _isInitializing = false;
      return false;
    }
  }

  /// Safely initialize speech recognizer (legacy method for compatibility)
  static Future<bool> safeInitializeSpeech(
    stt.SpeechToText speech, {
    void Function(String)? onStatus,
    void Function(dynamic)? onError,
  }) async {
    if (kIsWeb) {
      debugPrint('STT initialize skipped on Web');
      return false;
    }
    try {
      return await speech.initialize(
        onStatus: onStatus,
        onError: onError,
      );
    } catch (e) {
      debugPrint('STT initialize error: $e');
      return false;
    }
  }

  /// Safely start listening with automatic restart on "done"
  static Future<void> safeListen(
    stt.SpeechToText speech, {
    String? localeId,
    required void Function(dynamic) onResult,
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    if (kIsWeb) {
      debugPrint('STT listen skipped on Web');
      return;
    }

    if (!_isMicrophoneInitialized) {
      debugPrint('⚠️ Cannot start listening: microphone not initialized');
      return;
    }

    try {
      await speech.listen(
        localeId: localeId,
        onResult: onResult,
        listenFor: listenFor ?? const Duration(seconds: 30),
        pauseFor: pauseFor ?? const Duration(seconds: 5),
        partialResults: false,
      );
    } catch (e) {
      debugPrint('STT listen error: $e');
    }
  }

  /// Safely stop listening
  static Future<void> safeStopListening(stt.SpeechToText speech) async {
    if (kIsWeb) return;
    try {
      await speech.stop();
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      debugPrint('STT stop error: $e');
    }
  }

  /// Reset microphone state (call when navigating away from page)
  static void resetMicrophoneState() {
    _isMicrophoneInitialized = false;
    _isInitializing = false;
  }

  /// Check if microphone is initialized
  static bool isMicrophoneReady() {
    return _isMicrophoneInitialized;
  }

  /// Complete voice initialization sequence: TTS → Speak → Initialize Mic → Listen
  /// This is the recommended method for pages with voice interaction
  static Future<bool> initializePageWithVoice({
    required FlutterTts tts,
    required stt.SpeechToText speech,
    required String textToSpeak,
    required String localeId,
    required void Function(dynamic) onResult,
    void Function(String)? onStatus,
    void Function(dynamic)? onError,
  }) async {
    if (kIsWeb) {
      debugPrint('Voice initialization skipped on Web');
      return false;
    }

    try {
      // Step 1: Configure TTS
      debugPrint('🔧 Configuring TTS...');
      try {
        await tts.setLanguage(localeId);
        await tts.setSpeechRate(0.5);
        await tts.setPitch(1.0);
        await tts.setVolume(1.0);
      } catch (e) {
        debugPrint('TTS configuration error: $e');
      }

      // Step 2: Speak the text
      debugPrint('🔊 Speaking: $textToSpeak');
      await safeSpeak(tts, textToSpeak);
      await safeAwaitSpeakCompletion(tts);
      
      // Additional delay to ensure audio is fully released
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 3: Initialize microphone AFTER speaking is complete
      debugPrint('🎤 Initializing microphone after speaking...');
      final micReady = await initializeMicrophoneAfterSpeaking(
        speech: speech,
        tts: tts,
        onStatus: onStatus,
        onError: onError,
      );

      if (!micReady) {
        debugPrint('❌ Failed to initialize microphone');
        return false;
      }

      // Step 4: Start listening
      debugPrint('👂 Starting to listen...');
      await safeListen(
        speech,
        localeId: localeId,
        onResult: onResult,
      );

      debugPrint('✅ Voice initialization complete');
      return true;

    } catch (e, st) {
      debugPrint('❌ Voice initialization error: $e');
      debugPrint('$st');
      return false;
    }
  }
}