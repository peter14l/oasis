import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:oasis_v2/features/circles/domain/models/circles_models.dart';
import 'package:oasis_v2/features/circles/domain/repositories/circle_repository.dart';
import 'package:oasis_v2/features/circles/presentation/providers/circle_state.dart';

export 'package:oasis_v2/features/circles/presentation/providers/circle_state.dart';

class CircleProvider with ChangeNotifier {
  final CircleRepository _repository;

  CircleState _state = const CircleState();
  CircleState get state => _state;

  List<CircleEntity> get circles => _state.circles;
  CircleEntity? get activeCircle => _state.activeCircle;
  List<CommitmentEntity> get todaysCommitments => _state.todaysCommitments;
  bool get isLoading => _state.isLoading;
  String? get error => _state.error;

  StreamSubscription<List<CommitmentEntity>>? _realtimeSubscription;

  CircleProvider({required CircleRepository repository})
    : _repository = repository;

  Future<void> loadCircles(String userId, {bool forceRefresh = false}) async {
    if (_state.circles.isNotEmpty && !forceRefresh) return;

    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final circles = await _repository.getCircles(userId);
      _state = _state.copyWith(circles: circles);
    } catch (e) {
      _state = _state.copyWith(error: e.toString());
      debugPrint('[CircleProvider] Error loading circles: $e');
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  Future<CircleEntity?> createCircle({
    required String createdBy,
    required String name,
    required String emoji,
    required List<String> memberIds,
  }) async {
    try {
      final circle = await _repository.createCircle(
        createdBy: createdBy,
        name: name,
        emoji: emoji,
        memberIds: memberIds,
      );
      _state = _state.copyWith(circles: [circle, ..._state.circles]);
      notifyListeners();
      return circle;
    } catch (e) {
      _state = _state.copyWith(error: e.toString());
      notifyListeners();
      return null;
    }
  }

  Future<CircleEntity> getCircle(String circleId) async {
    return _repository.getCircle(circleId);
  }

  Future<void> joinCircle(String circleId, String userId) async {
    await _repository.joinCircle(circleId, userId);
  }

  Future<void> openCircle(String circleId) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      CircleEntity? circle;
      try {
        circle = _state.circles.firstWhere((c) => c.id == circleId);
      } catch (_) {
        circle = await _repository.getCircle(circleId);
      }

      _state = _state.copyWith(activeCircle: circle);

      final commitments = await _repository.getCommitments(
        circleId: circleId,
        date: DateTime.now(),
      );
      _state = _state.copyWith(todaysCommitments: commitments);

      _realtimeSubscription?.cancel();
      _realtimeSubscription = _repository
          .subscribeToCommitments(circleId: circleId)
          .listen((commitments) {
            _state = _state.copyWith(todaysCommitments: commitments);
            notifyListeners();
          }, onError: (e) => debugPrint('[CircleProvider] Stream error: $e'));
    } catch (e) {
      _state = _state.copyWith(error: e.toString());
      debugPrint('[CircleProvider] Error opening circle: $e');
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  void closeCircle() {
    _realtimeSubscription?.cancel();
    _state = _state.copyWith(activeCircle: null, todaysCommitments: []);
    notifyListeners();
  }

  Future<void> deleteCircle(String circleId) async {
    try {
      await _repository.deleteCircle(circleId);
      _state = _state.copyWith(
        circles: _state.circles.where((c) => c.id != circleId).toList(),
      );
      if (_state.activeCircle?.id == circleId) {
        _state = _state.copyWith(activeCircle: null, todaysCommitments: []);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[CircleProvider] Error deleting circle: $e');
      rethrow;
    }
  }

  Future<void> addCommitment({
    required String createdBy,
    required String title,
    String? description,
    DateTime? dueDate,
  }) async {
    if (_state.activeCircle == null) return;
    try {
      final commitment = await _repository.createCommitment(
        circleId: _state.activeCircle!.id,
        createdBy: createdBy,
        title: title,
        description: description,
        dueDate: dueDate,
      );
      _state = _state.copyWith(
        todaysCommitments: [..._state.todaysCommitments, commitment],
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(error: e.toString());
      notifyListeners();
    }
  }

  Future<void> setIntent({
    required String commitmentId,
    required String userId,
    required MemberIntent intent,
  }) async {
    _state = _state.copyWith(
      todaysCommitments:
          _state.todaysCommitments.map((c) {
            if (c.id == commitmentId) {
              final updated = Map<String, CommitmentResponseEntity>.from(
                c.responses,
              );
              updated[userId] = CommitmentResponseEntity(
                userId: userId,
                intent: intent,
              );
              return c.copyWith(responses: updated);
            }
            return c;
          }).toList(),
    );
    notifyListeners();

    try {
      await _repository.setIntent(
        commitmentId: commitmentId,
        userId: userId,
        intent: intent,
      );
    } catch (e) {
      _state = _state.copyWith(error: e.toString());
      notifyListeners();
    }
  }

  Future<void> markComplete({
    required String commitmentId,
    required String userId,
    String? note,
  }) async {
    _state = _state.copyWith(
      todaysCommitments:
          _state.todaysCommitments.map((c) {
            if (c.id == commitmentId) {
              final updated = Map<String, CommitmentResponseEntity>.from(
                c.responses,
              );
              updated[userId] = CommitmentResponseEntity(
                userId: userId,
                intent: MemberIntent.inTrying,
                completed: true,
                completedAt: DateTime.now(),
                note: note,
              );
              return c.copyWith(responses: updated);
            }
            return c;
          }).toList(),
    );
    notifyListeners();

    try {
      await _repository.markComplete(
        commitmentId: commitmentId,
        userId: userId,
        note: note,
      );
    } catch (e) {
      _state = _state.copyWith(error: e.toString());
      notifyListeners();
    }
  }

  void clearError() {
    _state = _state.copyWith(error: null);
    notifyListeners();
  }

  void clear() {
    _realtimeSubscription?.cancel();
    _state = const CircleState();
    notifyListeners();
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}
