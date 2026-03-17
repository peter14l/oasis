import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:oasis_v2/models/canvas_item.dart';
import 'package:oasis_v2/models/oasis_canvas.dart';
import 'package:oasis_v2/services/canvas_service.dart';

class CanvasProvider extends ChangeNotifier {
  final CanvasService _service = CanvasService();

  List<OasisCanvas> _canvases = [];
  OasisCanvas? _activeCanvas;
  List<CanvasItem> _activeItems = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<CanvasItem>>? _realtimeSubscription;

  // ─── Getters ──────────────────────────────────────────────────────────────────
  List<OasisCanvas> get canvases => _canvases;
  OasisCanvas? get activeCanvas => _activeCanvas;
  List<CanvasItem> get activeItems => _activeItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ─── Canvas list ─────────────────────────────────────────────────────────────

  Future<void> loadCanvases(String userId) async {
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
  }) async {
    try {
      final canvas = await _service.createCanvas(
        createdBy: createdBy,
        title: title,
        coverColor: coverColor,
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

  // ─── Active canvas ────────────────────────────────────────────────────────────

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
  }

  void closeCanvas() {
    _realtimeSubscription?.cancel();
    _activeCanvas = null;
    _activeItems = [];
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
  }) async {
    if (_activeCanvas == null) return;
    // Optimistic local update
    _activeItems = _activeItems.map((item) {
      if (item.id == itemId) {
        return item.copyWith(
          xPos: xPos,
          yPos: yPos,
          rotation: rotation ?? item.rotation,
        );
      }
      return item;
    }).toList();
    notifyListeners();

    try {
      await _service.moveItem(
        itemId: itemId,
        canvasId: _activeCanvas!.id,
        xPos: xPos,
        yPos: yPos,
        rotation: rotation,
      );
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

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}
