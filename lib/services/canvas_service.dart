import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:oasis_v2/models/oasis_canvas.dart';
import 'package:oasis_v2/models/canvas_item.dart';
import 'package:oasis_v2/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';


class CanvasService {
  final _supabase = SupabaseService().client;
  final _uuid = const Uuid();

  // ─── Canvases ────────────────────────────────────────────────────────────────

  /// Fetch all canvases the user is a member of.
  Future<List<OasisCanvas>> fetchUserCanvases(String userId) async {
    try {
      final response = await _supabase
          .from('canvases')
          .select('*, canvas_members!inner(user_id)')
          .eq('canvas_members.user_id', userId)
          .order('updated_at', ascending: false);

      return (response as List).map((row) {
        final canvasMap = Map<String, dynamic>.from(row);
        final memberRows = (canvasMap['canvas_members'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        canvasMap['member_ids'] = memberRows.map((m) => m['user_id'] as String).toList();
        return OasisCanvas.fromJson(canvasMap);
      }).toList();
    } catch (e) {
      debugPrint('CanvasService.fetchUserCanvases error: $e');
      rethrow;
    }
  }

  /// Create a new canvas (solo initially).
  Future<OasisCanvas> createCanvas({
    required String createdBy,
    required String title,
    required String coverColor,
  }) async {
    try {
      // 1. Create the canvas
      final canvasData = await _supabase
          .from('canvases')
          .insert({
            'title': title,
            'created_by': createdBy,
            'cover_color': coverColor,
          })
          .select()
          .single();

      final canvas = OasisCanvas.fromJson(canvasData);

      // 2. Add creator as owner
      await _supabase.from('canvas_members').insert({
        'canvas_id': canvas.id,
        'user_id': createdBy,
        'role': 'owner',
      });

      return canvas;
    } catch (e) {
      debugPrint('CanvasService.createCanvas error: $e');
      rethrow;
    }
  }

  /// Delete a canvas (only if owner).
  Future<void> deleteCanvas(String canvasId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // Check if user is owner
      final member = await _supabase
          .from('canvas_members')
          .select('role')
          .eq('canvas_id', canvasId)
          .eq('user_id', userId)
          .maybeSingle();

      if (member == null || member['role'] != 'owner') {
        throw Exception('Only the canvas creator can delete it');
      }

      await _supabase.from('canvases').delete().eq('id', canvasId);
    } catch (e) {
      debugPrint('CanvasService.deleteCanvas error: $e');
      rethrow;
    }
  }

  /// Fetch a single canvas by ID
  Future<OasisCanvas> getCanvas(String canvasId) async {
    try {
      final response = await _supabase
          .from('canvases')
          .select('*, canvas_members(user_id)')
          .eq('id', canvasId)
          .single();
          
      final canvasMap = Map<String, dynamic>.from(response);
      final memberRows = (canvasMap['canvas_members'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      canvasMap['member_ids'] = memberRows.map((m) => m['user_id'] as String).toList();
      
      return OasisCanvas.fromJson(canvasMap);
    } catch (e) {
      debugPrint('CanvasService.getCanvas error: $e');
      rethrow;
    }
  }

  // ─── Items ───────────────────────────────────────────────────────────────────

  /// Fetch all items for a specific canvas.
  Future<List<CanvasItem>> fetchCanvasItems(String canvasId) async {
    try {
      final response = await _supabase
          .from('canvas_items')
          .select('*')
          .eq('canvas_id', canvasId)
          .order('created_at', ascending: true);

      return (response as List).map((json) => CanvasItem.fromJson(json)).toList();
    } catch (e) {
      debugPrint('CanvasService.fetchCanvasItems error: $e');
      rethrow;
    }
  }

  /// Add an item to the canvas.
  Future<CanvasItem> addItem({
    required String canvasId,
    required String authorId,
    required CanvasItemType type,
    required String content,
    required double xPos,
    required double yPos,
    double rotation = 0.0,
    String color = '#252930',
  }) async {
    try {
      final data = await _supabase
          .from('canvas_items')
          .insert({
            'canvas_id': canvasId,
            'author_id': authorId,
            'type': type.name,
            'content': content,
            'x_pos': xPos,
            'y_pos': yPos,
            'rotation': rotation,
            'color': color,
          })
          .select()
          .single();

      return CanvasItem.fromJson(data);
    } catch (e) {
      debugPrint('CanvasService.addItem error: $e');
      rethrow;
    }
  }

  /// Delete an item from the canvas.
  Future<void> deleteItem(String itemId) async {
    try {
      await _supabase.from('canvas_items').delete().eq('id', itemId);
    } catch (e) {
      debugPrint('CanvasService.deleteItem error: $e');
      rethrow;
    }
  }

  /// Update item position/rotation.
  Future<void> updateItemTransform({
    required String itemId,
    required double xPos,
    required double yPos,
    double? rotation,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'x_pos': xPos,
        'y_pos': yPos,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (rotation != null) updates['rotation'] = rotation;

      await _supabase.from('canvas_items').update(updates).eq('id', itemId);
    } catch (e) {
      debugPrint('CanvasService.updateItemTransform error: $e');
      rethrow;
    }
  }

  /// Compatibility method for CanvasProvider
  Future<void> moveItem({
    required String itemId,
    required String canvasId,
    required double xPos,
    required double yPos,
    double? rotation,
  }) async {
    return updateItemTransform(itemId: itemId, xPos: xPos, yPos: yPos, rotation: rotation);
  }

  /// Upload an image to Supabase Storage for use on the canvas.
  Future<String> uploadCanvasImage(String canvasId, String filePath) async {
    try {
      final file = File(filePath);
      final ext = filePath.split('.').last;
      final fileName = 'canvas_${canvasId}_${_uuid.v4()}.$ext';

      await _supabase.storage.from('post-images').upload(fileName, file);
      return _supabase.storage.from('post-images').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('CanvasService.uploadCanvasImage error: $e');
      rethrow;
    }
  }

  /// Send a "Pulse" reaction to all members currently on the canvas.
  Future<void> sendPulse(String canvasId, String userId, {double intensity = 1.0}) async {
    try {
      final channel = _supabase.channel('canvas_items:$canvasId');
      await channel.sendBroadcastMessage(
        event: 'pulse',
        payload: {'user_id': userId, 'intensity': intensity, 'timestamp': DateTime.now().toIso8601String()},
      );
    } catch (e) {
      debugPrint('CanvasService.sendPulse error: $e');
    }
  }

  // ─── Realtime ────────────────────────────────────────────────────────────────

  /// Subscribe to live item changes for a canvas.
  Stream<List<CanvasItem>> subscribeToCanvas(String canvasId) {
    final controller = StreamController<List<CanvasItem>>.broadcast();

    final channel = _supabase.channel('canvas_items:$canvasId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'canvas_items',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'canvas_id',
            value: canvasId,
          ),
          callback: (payload) async {
            // Re-fetch all items to ensure correct order and local state sync
            final items = await fetchCanvasItems(canvasId);
            controller.add(items);
          },
        )
        .subscribe();

    // Cleanup on cancel
    controller.onCancel = () {
      _supabase.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }
}
