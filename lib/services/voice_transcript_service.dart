import 'package:flutter/foundation.dart';
import 'package:oasis_v2/core/network/supabase_client.dart';

/// Voice message transcript service for speech-to-text
/// Note: Full speech recognition requires speech_to_text package
class VoiceTranscriptService {
  bool _isInitialized = false;

  /// Initialize the speech recognition engine
  Future<bool> initialize() async {
    // Placeholder - in production, integrate speech_to_text package
    _isInitialized = true;
    return _isInitialized;
  }

  /// Check if speech recognition is available
  bool get isAvailable => _isInitialized;

  /// Transcribe audio from a recording (placeholder implementation)
  /// For full functionality, integrate with:
  /// - speech_to_text package for on-device recognition
  /// - Cloud APIs like Google Speech-to-Text, Whisper API, etc.
  Future<TranscriptionResult> transcribeVoiceMessage(String audioPath) async {
    final user = SupabaseService().client.auth.currentUser;
    final isPro = user?.userMetadata?['is_pro'] == true;
    if (!isPro) {
      throw Exception('Upgrade to Morrow Pro to transcribe voice messages.');
    }

    debugPrint('Transcribing audio: $audioPath');

    // Simulated response for demo purposes
    await Future.delayed(const Duration(seconds: 1));

    return TranscriptionResult(
      text:
          '[Voice message transcription - integrate speech_to_text package for full functionality]',
      confidence: 0.95,
      language: 'en-US',
      duration: const Duration(seconds: 5),
    );
  }

  /// Placeholder for live transcription
  void startListening({
    required Function(String) onResult,
    required Function() onComplete,
    String? localeId,
  }) {
    debugPrint('Live transcription requires speech_to_text package');
    // Simulate immediate completion
    Future.delayed(const Duration(milliseconds: 500), () {
      onResult('');
      onComplete();
    });
  }

  /// Stop listening
  void stopListening() {
    debugPrint('Stopping transcription');
  }

  /// Cancel listening
  void cancelListening() {
    debugPrint('Cancelling transcription');
  }

  bool get isListening => false;
}

/// Result of voice transcription
class TranscriptionResult {
  final String text;
  final double confidence;
  final String language;
  final Duration duration;
  final List<TranscriptionWord>? words;

  TranscriptionResult({
    required this.text,
    required this.confidence,
    required this.language,
    required this.duration,
    this.words,
  });

  factory TranscriptionResult.fromJson(Map<String, dynamic> json) {
    return TranscriptionResult(
      text: json['text'] ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
      language: json['language'] ?? 'en-US',
      duration: Duration(milliseconds: json['duration_ms'] ?? 0),
      words:
          (json['words'] as List?)
              ?.map((w) => TranscriptionWord.fromJson(w))
              .toList(),
    );
  }
}

/// Individual word in transcription with timing
class TranscriptionWord {
  final String word;
  final Duration startTime;
  final Duration endTime;
  final double confidence;

  TranscriptionWord({
    required this.word,
    required this.startTime,
    required this.endTime,
    required this.confidence,
  });

  factory TranscriptionWord.fromJson(Map<String, dynamic> json) {
    return TranscriptionWord(
      word: json['word'] ?? '',
      startTime: Duration(milliseconds: json['start_ms'] ?? 0),
      endTime: Duration(milliseconds: json['end_ms'] ?? 0),
      confidence: (json['confidence'] ?? 0).toDouble(),
    );
  }
}

/// Model for storing message transcripts
class MessageTranscript {
  final String id;
  final String messageId;
  final String text;
  final double confidence;
  final String language;
  final DateTime createdAt;

  MessageTranscript({
    required this.id,
    required this.messageId,
    required this.text,
    required this.confidence,
    required this.language,
    required this.createdAt,
  });

  factory MessageTranscript.fromJson(Map<String, dynamic> json) {
    return MessageTranscript(
      id: json['id'],
      messageId: json['message_id'],
      text: json['text'],
      confidence: (json['confidence'] ?? 0).toDouble(),
      language: json['language'] ?? 'en-US',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'text': text,
      'confidence': confidence,
      'language': language,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
