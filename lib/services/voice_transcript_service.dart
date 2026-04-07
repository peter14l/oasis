import 'package:flutter/foundation.dart';
import 'package:oasis/core/network/supabase_client.dart';

/// Model for voice transcription result
class VoiceTranscript {
  final String text;
  final double confidence;
  final String language;
  final DateTime createdAt;

  VoiceTranscript({
    required this.text,
    required this.confidence,
    required this.language,
    required this.createdAt,
  });

  factory VoiceTranscript.fromJson(Map<String, dynamic> json) {
    return VoiceTranscript(
      text: json['text'] ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
      language: json['language'] ?? 'en-US',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}

/// Voice message transcript service for speech-to-text
class VoiceTranscriptService {
  final _supabase = SupabaseService().client;
  bool _isInitialized = false;

  /// Initialize the speech recognition engine
  Future<bool> initialize() async {
    _isInitialized = true;
    return _isInitialized;
  }

  /// Check if speech recognition is available
  bool get isAvailable => _isInitialized;

  /// Get existing transcript for a message
  Future<VoiceTranscript?> getTranscript(String messageId) async {
    try {
      final response = await _supabase
          .from('message_transcripts')
          .select()
          .eq('message_id', messageId)
          .maybeSingle();
      
      if (response != null) {
        return VoiceTranscript.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching transcript: $e');
      return null;
    }
  }

  /// Transcribe audio from a recording
  Future<VoiceTranscript> transcribeVoiceMessage(
    String messageId,
    String audioUrl,
  ) async {
    debugPrint('Transcribing audio: $audioUrl for message: $messageId');

    // Simulated transcription delay
    await Future.delayed(const Duration(seconds: 2));

    final transcript = VoiceTranscript(
      text: 'This is a simulated transcription of the voice message. To enable real speech-to-text, integrate the speech_to_text package or a cloud API like Whisper.',
      confidence: 0.98,
      language: 'en-US',
      createdAt: DateTime.now(),
    );

    try {
      // Persist the transcript
      await _supabase.from('message_transcripts').upsert({
        'message_id': messageId,
        'text': transcript.text,
        'confidence': transcript.confidence,
        'language': transcript.language,
        'created_at': transcript.createdAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving transcript: $e');
      // We still return the transcript even if saving fails
    }

    return transcript;
  }
}
