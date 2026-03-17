import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:oasis_v2/models/circle.dart';
import 'package:oasis_v2/models/commitment.dart';
import 'package:oasis_v2/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class CircleService {
  final _supabase = SupabaseService().client;
  final _uuid = const Uuid();

  // ─── Circles ─────────────────────────────────────────────────────────────────

  /// Fetch all circles the current user belongs to.
  Future<List<Circle>> fetchUserCircles(String userId) async {
    try {
      final response = await _supabase
          .from('circle_members')
          .select('circle_id, circles(*, circle_members(user_id))')
          .eq('user_id', userId)
          .order('created_at', referencedTable: 'circles', ascending: false);

      return (response as List).map<Circle>((row) {
        final circle = row['circles'] as Map<String, dynamic>;
        final memberRows =
            (circle['circle_members'] as List?)?.cast<Map<String, dynamic>>() ??
                [];
        circle['member_ids'] =
            memberRows.map((m) => m['user_id'] as String).toList();
        return Circle.fromJson(circle);
      }).toList();
    } catch (e) {
      debugPrint('CircleService.fetchUserCircles error: $e');
      return [];
    }
  }

  /// Create a new circle and add members.
  Future<Circle> createCircle({
    required String createdBy,
    required String name,
    required String emoji,
    required List<String> memberIds,
  }) async {
    try {
      final circleId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      await _supabase.from('circles').insert({
        'id': circleId,
        'name': name,
        'emoji': emoji,
        'created_by': createdBy,
        'streak_count': 0,
        'created_at': now,
      });

      final allMembers = {createdBy, ...memberIds};
      await _supabase.from('circle_members').insert(
        allMembers
            .map((uid) => {
                  'circle_id': circleId,
                  'user_id': uid,
                  'role': uid == createdBy ? 'admin' : 'member',
                  'joined_at': now,
                })
            .toList(),
      );

      // Send notifications to invited members
      for (final memberId in memberIds) {
        await _supabase.from('notifications').insert({
          'user_id': memberId,
          'type': 'circle_invite',
          'title': 'You\'re in a Circle! $emoji',
          'body': 'You\'ve been added to "$name"',
          'data': {'circle_id': circleId},
          'created_at': now,
        });
      }

      return Circle(
        id: circleId,
        name: name,
        emoji: emoji,
        createdBy: createdBy,
        createdAt: DateTime.now(),
        streakCount: 0,
        memberIds: allMembers.toList(),
      );
    } catch (e) {
      debugPrint('CircleService.createCircle error: $e');
      rethrow;
    }
  }

  /// Fetch a single circle by ID
  Future<Circle> getCircle(String circleId) async {
    try {
      final response = await _supabase
          .from('circles')
          .select('*, circle_members(user_id)')
          .eq('id', circleId)
          .single();
          
      final circleMap = Map<String, dynamic>.from(response);
      final memberRows = (circleMap['circle_members'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      circleMap['member_ids'] = memberRows.map((m) => m['user_id'] as String).toList();
      
      return Circle.fromJson(circleMap);
    } catch (e) {
      debugPrint('CircleService.getCircle error: $e');
      rethrow;
    }
  }

  // ─── Commitments ─────────────────────────────────────────────────────────────

  /// Fetch all commitments for a circle on a specific date.
  Future<List<Commitment>> fetchCommitments(
    String circleId, {
    DateTime? date,
  }) async {
    try {
      final targetDate = date ?? DateTime.now();
      final dateStr =
          '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';

      final response = await _supabase
          .from('commitments')
          .select('*, commitment_responses(*)')
          .eq('circle_id', circleId)
          .eq('due_date', dateStr)
          .order('created_at', ascending: true);

      return (response as List).map<Commitment>((row) {
        // Build responses map from the joined rows
        final rawResponses =
            (row['commitment_responses'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        final responsesMap = <String, CommitmentResponse>{};
        for (final r in rawResponses) {
          final cr = CommitmentResponse.fromJson(r);
          responsesMap[cr.userId] = cr;
        }
        final json = Map<String, dynamic>.from(row);
        json['responses'] =
            responsesMap.map((k, v) => MapEntry(k, v.toJson()));
        return Commitment.fromJson(json);
      }).toList();
    } catch (e) {
      debugPrint('CircleService.fetchCommitments error: $e');
      return [];
    }
  }

  /// Create a new commitment in a circle.
  Future<Commitment> createCommitment({
    required String circleId,
    required String createdBy,
    required String title,
    String? description,
    DateTime? dueDate,
  }) async {
    try {
      final id = _uuid.v4();
      final now = DateTime.now();
      final due = dueDate ?? now;
      final dateStr =
          '${due.year}-${due.month.toString().padLeft(2, '0')}-${due.day.toString().padLeft(2, '0')}';

      final data = {
        'id': id,
        'circle_id': circleId,
        'created_by': createdBy,
        'title': title,
        'description': description,
        'due_date': dateStr,
        'status': 'open',
        'created_at': now.toIso8601String(),
      };

      await _supabase.from('commitments').insert(data);

      return Commitment(
        id: id,
        circleId: circleId,
        createdBy: createdBy,
        title: title,
        description: description,
        dueDate: due,
        status: CommitmentStatus.open,
        responses: const {},
        createdAt: now,
      );
    } catch (e) {
      debugPrint('CircleService.createCommitment error: $e');
      rethrow;
    }
  }

  /// Set member intent (I'm In / Out) for a commitment.
  Future<void> setIntent({
    required String commitmentId,
    required String userId,
    required MemberIntent intent,
  }) async {
    try {
      await _supabase.from('commitment_responses').upsert({
        'commitment_id': commitmentId,
        'user_id': userId,
        'intent': intent.name,
        'completed': false,
      }, onConflict: 'commitment_id,user_id');
    } catch (e) {
      debugPrint('CircleService.setIntent error: $e');
      rethrow;
    }
  }

  /// Mark a commitment as completed by the current user.
  Future<void> markComplete({
    required String commitmentId,
    required String userId,
    String? note,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      await _supabase.from('commitment_responses').upsert({
        'commitment_id': commitmentId,
        'user_id': userId,
        'intent': MemberIntent.inTrying.name,
        'completed': true,
        'completed_at': now,
        'note': note,
      }, onConflict: 'commitment_id,user_id');
    } catch (e) {
      debugPrint('CircleService.markComplete error: $e');
      rethrow;
    }
  }

  // ─── Realtime ─────────────────────────────────────────────────────────────────

  /// Subscribe to live commitment + response changes for a circle.
  Stream<List<Commitment>> subscribeToCommitments(
    String circleId, {
    DateTime? date,
  }) {
    final controller = StreamController<List<Commitment>>.broadcast();

    final channel = _supabase.channel('commitments:$circleId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'commitments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'circle_id',
            value: circleId,
          ),
          callback: (_) async {
            final items = await fetchCommitments(circleId, date: date);
            if (!controller.isClosed) controller.add(items);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'commitment_responses',
          callback: (_) async {
            final items = await fetchCommitments(circleId, date: date);
            if (!controller.isClosed) controller.add(items);
          },
        )
        .subscribe();

    controller.onCancel = () {
      _supabase.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }
}
