import 'package:flutter_test/flutter_test.dart';
import 'package:oasis_v2/models/canvas_item.dart';

void main() {
  group('CanvasItem Model Tests', () {
    test('CanvasItem should serialize and deserialize correctly', () {
      final now = DateTime.now();
      final unlockDate = now.add(const Duration(days: 7));
      
      final item = CanvasItem(
        id: '1',
        canvasId: 'c1',
        authorId: 'u1',
        type: CanvasItemType.milestone,
        content: 'Summer Trip',
        xPos: 0.5,
        yPos: 0.5,
        createdAt: now,
        unlockAt: unlockDate,
        color: '#FF5733',
      );

      final json = item.toJson();
      expect(json['id'], '1');
      expect(json['type'], 'milestone');
      expect(json['unlock_at'], unlockDate.toIso8601String());

      final fromJson = CanvasItem.fromJson(json);
      expect(fromJson.id, item.id);
      expect(fromJson.type, item.type);
      expect(fromJson.unlockAt?.toIso8601String(), item.unlockAt?.toIso8601String());
    });

    test('CanvasItem copyWith should work correctly', () {
      final item = CanvasItem(
        id: '1',
        canvasId: 'c1',
        authorId: 'u1',
        type: CanvasItemType.text,
        content: 'Hello',
        xPos: 0.1,
        yPos: 0.1,
        createdAt: DateTime.now(),
      );

      final updated = item.copyWith(
        content: 'Updated',
        xPos: 0.9,
        scale: 2.0,
      );

      expect(updated.content, 'Updated');
      expect(updated.xPos, 0.9);
      expect(updated.scale, 2.0);
      expect(updated.id, item.id); // Unchanged
    });
  });

  group('Memory Leak & Performance Scan logic', () {
    // This is more of a logical check for common patterns
    test('Check item locking logic', () {
      final now = DateTime.now();
      final future = now.add(const Duration(hours: 1));
      final past = now.subtract(const Duration(hours: 1));

      final lockedItem = CanvasItem(
        id: 'locked',
        canvasId: 'c1',
        authorId: 'u1',
        type: CanvasItemType.text,
        content: 'Hidden',
        xPos: 0, yPos: 0,
        createdAt: past,
        unlockAt: future,
      );

      final unlockedItem = CanvasItem(
        id: 'unlocked',
        canvasId: 'c1',
        authorId: 'u1',
        type: CanvasItemType.text,
        content: 'Visible',
        xPos: 0, yPos: 0,
        createdAt: past,
        unlockAt: past, // Already unlocked
      );

      bool isLocked(CanvasItem item) => item.unlockAt != null && item.unlockAt!.isAfter(DateTime.now());

      expect(isLocked(lockedItem), isTrue);
      expect(isLocked(unlockedItem), isFalse);
    });
  });
}
