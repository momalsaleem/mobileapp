package com.example.fyp.service

import android.content.Context
import android.speech.tts.TextToSpeech
import android.util.Log
import java.util.Locale

class VoiceFeedbackService private constructor(context: Context) {
    private var tts: TextToSpeech? = null
    private var isReady = false

    init {
        tts = TextToSpeech(context.applicationContext) { status ->
            if (status == TextToSpeech.SUCCESS) {
                val result = tts?.setLanguage(Locale.US)
                isReady = result != TextToSpeech.LANG_MISSING_DATA && result != TextToSpeech.LANG_NOT_SUPPORTED
                tts?.setSpeechRate(1.0f)
            } else {
                isReady = false
                Log.e("VoiceFeedbackService", "TTS initialization failed")
            }
        }
    }

    fun speak(text: String) {
        if (isReady && tts != null) {
            tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, null)
        } else {
            Log.w("VoiceFeedbackService", "TTS not ready, cannot speak: $text")
        }
    }

    fun shutdown() {
        tts?.stop()
        tts?.shutdown()
        tts = null
        isReady = false
    }

    companion object {
        @Volatile private var INSTANCE: VoiceFeedbackService? = null
        fun getInstance(context: Context): VoiceFeedbackService {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: VoiceFeedbackService(context).also { INSTANCE = it }
            }
        }
    }
} 