import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Safe wrappers for TTS and STT to avoid Flutter Web engine/window assertions.
class VoiceManager {
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

  /// Safely initialize speech recognizer. Returns whether available.
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

  /// Safely start listening. Skipped on web.
  static Future<void> safeListen(
    stt.SpeechToText speech, {
    String? localeId,
    required void Function(dynamic) onResult,
  }) async {
    if (kIsWeb) {
      debugPrint('STT listen skipped on Web');
      return;
    }
    try {
      speech.listen(
        localeId: localeId,
        onResult: onResult,
      );
    } catch (e) {
      debugPrint('STT listen error: $e');
    }
  }

  static Future<void> safeStopListening(stt.SpeechToText speech) async {
    if (kIsWeb) return;
    try {
      await speech.stop();
    } catch (e) {
      debugPrint('STT stop error: $e');
    }
  }

  /// Safely start a new speech recognition session.
  ///
  /// Behavior:
  /// 1. Stops any existing session.
  /// 2. Waits [preDelay] (default 500ms) to allow audio streams to settle.
  /// 3. Ensures [tts] is not speaking by calling stop() on it.
  /// 4. Initializes the speech recognizer (with handlers) and begins listening.
  /// 5. Returns true if listening started, false otherwise.
  static Future<bool> safeStartListening({
    required FlutterTts tts,
    required stt.SpeechToText speech,
    String? localeId,
    required void Function(dynamic) onResult,
    void Function(String)? onStatus,
    void Function(dynamic)? onError,
    Duration preDelay = const Duration(milliseconds: 500),
  }) async {
    if (kIsWeb) {
      debugPrint('STT start skipped on Web');
      return false;
    }

    try {
      // 1) Stop any previous listening session
      try {
        await safeStopListening(speech);
      } catch (e) {
        debugPrint('Error stopping previous STT session: $e');
      }

      // 2) Small delay to let audio streams settle
      await Future.delayed(preDelay);

      // 3) Ensure TTS is not speaking
      try {
        await tts.stop();
      } catch (e) {
        debugPrint('Error stopping TTS before STT: $e');
      }

      // 4) Initialize speech recognizer
      final available = await safeInitializeSpeech(
        speech,
        onStatus: (s) {
          if (onStatus != null) onStatus(s);
        },
        onError: (e) {
          if (onError != null) onError(e);
        },
      );

      if (!available) {
        debugPrint('STT initialize reported not available');
        return false;
      }

      // 5) Start listening
      await safeListen(
        speech,
        localeId: localeId,
        onResult: onResult,
      );

      return true;
    } catch (e, st) {
      debugPrint('safeStartListening error: $e');
      debugPrint('$st');
      // Consider this a permanent failure for this attempt
      try {
        if (onError != null) onError(e);
      } catch (_) {}
      return false;
    }
  }
}
