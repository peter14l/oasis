import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:oasis_v2/models/circle.dart';
import 'package:oasis_v2/models/commitment.dart';
import 'package:oasis_v2/services/circle_service.dart';

class CircleProvider extends ChangeNotifier {
  final CircleService _service = CircleService();

  List<Circle> _circles = [];
  Circle? _activeCircle;
  List<Commitment> _todaysCommitments = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<Commitment>>? _realtimeSubscription;

  // ─── Getters ──────────────────────────────────────────────────────────────────
  List<Circle> get circles => _circles;
  Circle? get activeCircle => _activeCircle;
  List<Commitment> get todaysCommitments => _todaysCommitments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ─── Circles ──────────────────────────────────────────────────────────────────

  Future<void> loadCircles(String userId, {bool forceRefresh = false}) async {
    if (_circles.isNotEmpty && !forceRefresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _circles = await _service.fetchUserCircles(userId);
    } catch (e) {
      _error = e.toString();
      debugPrint('CircleProvider.loadCircles error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Circle?> createCircle({
    required String createdBy,
    required String name,
    required String emoji,
    required List<String> memberIds,
  }) async {
    try {
      final circle = await _service.createCircle(
        createdBy: createdBy,
        name: name,
        emoji: emoji,
        memberIds: memberIds,
      );
      _circles = [circle, ..._circles];
      notifyListeners();
      return circle;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ─── Active circle ────────────────────────────────────────────────────────────

  Future<void> openCircle(String circleId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _activeCircle = _circles.firstWhere((c) => c.id == circleId);
    } catch (_) {
      try {
        _activeCircle = await _service.getCircle(circleId);
      } catch (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
        return;
      }
    }

    try {
      _todaysCommitments =
          await _service.fetchCommitments(circleId, date: DateTime.now());
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();

    // Subscribe to realtime updates
    _realtimeSubscription?.cancel();
    _realtimeSubscription =
        _service.subscribeToCommitments(circleId).listen((commitments) {
      _todaysCommitments = commitments;
      notifyListeners();
    });
  }

  void closeCircle() {
    _realtimeSubscription?.cancel();
    _activeCircle = null;
    _todaysCommitments = [];
    notifyListeners();
  }

  // ─── Commitments ─────────────────────────────────────────────────────────────

  Future<void> addCommitment({
    required String createdBy,
    required String title,
    String? description,
    DateTime? dueDate,
  }) async {
    if (_activeCircle == null) return;
    try {
      final commitment = await _service.createCommitment(
        circleId: _activeCircle!.id,
        createdBy: createdBy,
        title: title,
        description: description,
        dueDate: dueDate,
      );
      _todaysCommitments = [..._todaysCommitments, commitment];
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> setIntent({
    required String commitmentId,
    required String userId,
    required MemberIntent intent,
  }) async {
    // Optimistic update
    _todaysCommitments = _todaysCommitments.map((c) {
      if (c.id == commitmentId) {
        final updated = Map<String, CommitmentResponse>.from(c.responses);
        updated[userId] = CommitmentResponse(userId: userId, intent: intent);
        return c.copyWith(responses: updated);
      }
      return c;
    }).toList();
    notifyListeners();

    try {
      await _service.setIntent(
        commitmentId: commitmentId,
        userId: userId,
        intent: intent,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markComplete({
    required String commitmentId,
    required String userId,
    String? note,
  }) async {
    // Optimistic update
    _todaysCommitments = _todaysCommitments.map((c) {
      if (c.id == commitmentId) {
        final updated = Map<String, CommitmentResponse>.from(c.responses);
        updated[userId] = CommitmentResponse(
          userId: userId,
          intent: MemberIntent.inTrying,
          completed: true,
          completedAt: DateTime.now(),
          note: note,
        );
        return c.copyWith(responses: updated);
      }
      return c;
    }).toList();
    notifyListeners();

    try {
      await _service.markComplete(
        commitmentId: commitmentId,
        userId: userId,
        note: note,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clear() {
    _circles = [];
    _activeCircle = null;
    _todaysCommitments = [];
    _isLoading = false;
    _error = null;
    _realtimeSubscription?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}
