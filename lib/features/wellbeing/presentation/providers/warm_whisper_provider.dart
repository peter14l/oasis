import 'package:flutter/material.dart';
import 'package:oasis/features/wellbeing/domain/models/warm_whisper.dart';
import 'package:oasis/features/wellbeing/domain/repositories/warm_whisper_repository.dart';
import 'package:oasis/features/wellbeing/data/repositories/warm_whisper_repository_impl.dart';

class WarmWhisperProvider with ChangeNotifier {
  final WarmWhisperRepository _repository;

  List<WarmWhisper> _receivedWhispers = [];
  List<WarmWhisper> _sentWhispers = [];
  int _remainingCount = 3;
  bool _isLoading = false;

  WarmWhisperProvider({WarmWhisperRepository? repository})
      : _repository = repository ?? WarmWhisperRepositoryImpl();

  List<WarmWhisper> get receivedWhispers => _receivedWhispers;
  List<WarmWhisper> get sentWhispers => _sentWhispers;
  int get remainingCount => _remainingCount;
  bool get isLoading => _isLoading;

  Future<void> loadWhispers() async {
    _setLoading(true);
    try {
      _receivedWhispers = await _repository.getReceivedWhispers();
      _sentWhispers = await _repository.getSentWhispers();
      _remainingCount = await _repository.getRemainingWhisperCount();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendWhisper({
    required String recipientId,
    String? message,
    bool isAnonymous = false,
  }) async {
    try {
      await _repository.sendWhisper(
        recipientId: recipientId,
        message: message,
        isAnonymous: isAnonymous,
      );
      await loadWhispers();
      return true;
    } catch (e) {
      debugPrint('WarmWhisperProvider: Error sending whisper: $e');
      return false;
    }
  }

  Future<void> markAsRevealed(String whisperId) async {
    try {
      await _repository.markAsRevealed(whisperId);
      final index = _receivedWhispers.indexWhere((w) => w.id == whisperId);
      if (index != -1) {
        _receivedWhispers[index] = _receivedWhispers[index].copyWith(
          revealedAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('WarmWhisperProvider: Error marking as revealed: $e');
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
