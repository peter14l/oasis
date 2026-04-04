import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:oasis_v2/features/canvas/domain/models/canvas_models.dart';
import 'package:oasis_v2/models/oasis_canvas.dart';
import 'package:oasis_v2/services/canvas_service.dart';

class CanvasProvider extends ChangeNotifier {
  final CanvasService _service = CanvasService();

  List<OasisCanvas> _canvases = [];
  OasisCanvas? _activeCanvas;
  List<CanvasItemEntity> _activeItems = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<CanvasItemEntity>>? _realtimeSubscription;
  Map<String, dynamic> _presenceState = {};
  StreamSubscription<Map<String, dynamic>>? _presenceSubscription;

  // ─── Getters ──────────────────────────────────────────────────────────────────
  List<OasisCanvas> get canvases => _canvases;
  OasisCanvas? get activeCanvas => _activeCanvas;
  List<CanvasItemEntity> get activeItems => _activeItems;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get presenceState => _presenceState;

  // ─── Canvas list ─────────────────────────────────────────────────────────────

  Future<void> loadCanvases(String userId, {bool forceRefresh = false}) async {
    if (_canvases.isNotEmpty && !forceRefresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _canvases = await _service.fetchUserCanvases(userId);
    } catch (e) {
      _error = e.toString();
      debugPrint('CanvasProvider.loadCanvases error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<OasisCanvas?> createCanvas({
    required String createdBy,
    required String title,
    required String coverColor,
    List<String> memberIds = const [],
    bool isPro = false,
  }) async {
    if (!isPro && _canvases.length >= 2) {
      _error = 'FREE_LIMIT_REACHED';
      notifyListeners();
      return null;
    }
    
    try {
      final canvas = await _service.createCanvas(
        createdBy: createdBy,
        title: title,
        coverColor: coverColor,
        memberIds: memberIds,
      );
      _canvases = [canvas, ..._canvases];
      notifyListeners();
      return canvas;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteCanvas(String canvasId) async {
    try {
      await _service.deleteCanvas(canvasId);
      _canvases = _canvases.where((c) => c.id != canvasId).toList();
      if (_activeCanvas?.id == canvasId) {
        _activeCanvas = null;
        _activeItems = [];
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> leaveCanvas(String canvasId) async {
    try {
      await _service.leaveCanvas(canvasId);
      _canvases = _canvases.where((c) => c.id != canvasId).toList();
      if (_activeCanvas?.id == canvasId) {
        _activeCanvas = null;
        _activeItems = [];
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> joinCanvas(String canvasId, String userId) async {
    try {
      await _service.joinCanvas(canvasId, userId);
      await loadCanvases(userId, forceRefresh: true); // Refresh list
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ─── Active canvas ────────────────────────────────────────────
  // ──────────────────────────────────────────────────────────────

  Future<void> openCanvas(String canvasId) async {
    _isLoading = true;
    notifyListeners();

    // Find the canvas in the list
    try {
      _activeCanvas = _canvases.firstWhere((c) => c.id == canvasId);
    } catch (_) {
      try {
        _activeCanvas = await _service.getCanvas(canvasId);
      } catch (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
        return;
      }
    }

    try {
      _activeItems = await _service.fetchCanvasItems(canvasId);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();

    // Start realtime subscription
    _realtimeSubscription?.cancel();
    _realtimeSubscription =
        _service.subscribeToCanvas(canvasId).listen((items) {
      _activeItems = items;
      notifyListeners();
    });

    // Start presence subscription
    _presenceSubscription?.cancel();
    _presenceSubscription = _service.subscribeToPresence(canvasId).listen((state) {
      _presenceState = state;
      notifyListeners();
    });
  }

  void updatePresence(String userId, double x, double y, {String? activeItemId}) {
    if (_activeCanvas == null) return;
    _service.updatePresence(
      canvasId: _activeCanvas!.id,
      userId: userId,
      x: x,
      y: y,
      activeItemId: activeItemId,
    );
  }

  void closeCanvas() {
    _realtimeSubscription?.cancel();
    _presenceSubscription?.cancel();
    _activeCanvas = null;
    _activeItems = [];
    _presenceState = {};
    notifyListeners();
  }

  // ─── Items ────────────────────────────────────────────────────────────────────

  Future<void> addItem({
    required String authorId,
    required CanvasItemType type,
    required String content,
    required double xPos,
    required double yPos,
    double rotation = 0.0,
    String color = '#252930',
    DateTime? unlockAt,
  }) async {
    if (_activeCanvas == null) return;
    try {
      final item = await _service.addItem(
        canvasId: _activeCanvas!.id,
        authorId: authorId,
        type: type,
        content: content,
        xPos: xPos,
        yPos: yPos,
        rotation: rotation,
        color: color,
        unlockAt: unlockAt,
      );
      // Optimistic update — realtime will confirm
      _activeItems = [..._activeItems, item];
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> moveItem({
    required String itemId,
    required double xPos,
    required double yPos,
    double? rotation,
    double? scale,
    String? lastModifiedBy,
  }) async {
    if (_activeCanvas == null) return;
    
    // Check if locked
    final item = _activeItems.firstWhere((i) => i.id == itemId);
    if (item.isLocked && item.authorId != lastModifiedBy) return;

    // Optimistic local update
    _activeItems = _activeItems.map((item) {
      if (item.id == itemId) {
        return item.copyWith(
          xPos: xPos,
          yPos: yPos,
          rotation: rotation ?? item.rotation,
          scale: scale ?? item.scale,
          lastModifiedBy: lastModifiedBy,
        );
      }
      return item;
    }).toList();
    notifyListeners();

    try {
      await _service.updateItemTransform(
        itemId: itemId,
        xPos: xPos,
        yPos: yPos,
        rotation: rotation,
        scale: scale,
        lastModifiedBy: lastModifiedBy,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleReaction(String itemId, String userId, String emoji) async {
    try {
      // Optimistic update
      _activeItems = _activeItems.map((item) {
        if (item.id == itemId) {
          final reactions = Map<String, List<String>>.from(item.reactions);
          final List<String> users = reactions[emoji] != null ? List<String>.from(reactions[emoji]!) : <String>[];
          if (users.contains(userId)) {
            users.remove(userId);
          } else {
            users.add(userId);
          }
          if (users.isEmpty) {
            reactions.remove(emoji);
          } else {
            reactions[emoji] = users;
          }
          return item.copyWith(reactions: reactions);
        }
        return item;
      }).toList();
      notifyListeners();

      await _service.toggleReaction(itemId: itemId, userId: userId, emoji: emoji);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> setItemLock(String itemId, bool isLocked) async {
    try {
      // Optimistic
      _activeItems = _activeItems.map((item) {
        if (item.id == itemId) {
          return item.copyWith(isLocked: isLocked);
        }
        return item;
      }).toList();
      notifyListeners();

      await _service.updateItemLock(itemId, isLocked);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteItem(String itemId) async {
    _activeItems = _activeItems.where((i) => i.id != itemId).toList();
    notifyListeners();
    try {
      await _service.deleteItem(itemId);
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
    _canvases = [];
    _activeCanvas = null;
    _activeItems = [];
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
