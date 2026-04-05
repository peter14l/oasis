import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oasis/features/messages/domain/models/message.dart';
import 'package:oasis/features/messages/domain/models/message_reaction.dart';

/// Grouped reaction for display in the UI.
class GroupedReaction {
  final String emoji;
  final int count;
  final List<String> usernames;
  final bool hasCurrentUserReacted;

  const GroupedReaction({
    required this.emoji,
    required this.count,
    required this.usernames,
    required this.hasCurrentUserReacted,
  });
}

/// Provider handling all message reaction logic.
/// Extracted from _ChatScreenState reaction methods in chat_screen.dart.
class ChatReactionsProvider with ChangeNotifier {
  /// Group individual reactions by emoji for display.
  /// Original: _groupReactions() in chat_screen.dart
  List<GroupedReaction> groupReactions(
    List<MessageReactionModel> reactions,
    String? currentUserId,
  ) {
    final groups = <String, GroupedReaction>{};

    for (final reaction in reactions) {
      if (groups.containsKey(reaction.reaction)) {
        final group = groups[reaction.reaction]!;
        groups[reaction.reaction] = GroupedReaction(
          emoji: group.emoji,
          count: group.count + 1,
          usernames: [...group.usernames, reaction.username],
          hasCurrentUserReacted:
              group.hasCurrentUserReacted || reaction.userId == currentUserId,
        );
      } else {
        groups[reaction.reaction] = GroupedReaction(
          emoji: reaction.reaction,
          count: 1,
          usernames: [reaction.username],
          hasCurrentUserReacted: reaction.userId == currentUserId,
        );
      }
    }
    return groups.values.toList();
  }

  /// Add, remove, or toggle a reaction on a message.
  /// Original: _onReactionSelected() in chat_screen.dart
  Future<void> onReactionSelected({
    required Message message,
    required String reaction,
    required String userId,
    required String username,
    required List<MessageReactionModel> currentReactions,
    required Function(List<MessageReactionModel>) onReactionsUpdated,
    Function(String)? onError,
  }) async {
    // Optimistic update
    final updatedReactions = List<MessageReactionModel>.from(currentReactions);

    final existingIndex = updatedReactions.indexWhere(
      (r) => r.userId == userId && r.reaction == reaction,
    );

    // Also check if user has ANY reaction to replace it
    final anyReactionIndex = updatedReactions.indexWhere(
      (r) => r.userId == userId,
    );

    if (existingIndex >= 0) {
      // Remove same reaction (toggle off)
      updatedReactions.removeAt(existingIndex);
    } else {
      // If user has a different reaction, remove it first (standard behavior)
      if (anyReactionIndex >= 0) {
        updatedReactions.removeAt(anyReactionIndex);
      }

      // Add new reaction
      updatedReactions.add(
        MessageReactionModel(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          messageId: message.id,
          userId: userId,
          username: username,
          reaction: reaction,
          createdAt: DateTime.now(),
        ),
      );
    }

    // Notify UI of optimistic update
    onReactionsUpdated(updatedReactions);

    try {
      if (existingIndex >= 0) {
        // Toggle off: remove reaction from DB
        await Supabase.instance.client
            .from('message_reactions')
            .delete()
            .eq('message_id', message.id)
            .eq('user_id', userId)
            .eq('emoji', reaction);
      } else {
        // Insert new reaction — split into delete+insert to avoid RLS blocking upsert
        // First remove any existing reaction from this user on this message
        await Supabase.instance.client
            .from('message_reactions')
            .delete()
            .eq('message_id', message.id)
            .eq('user_id', userId);

        // Then insert the new reaction
        await Supabase.instance.client.from('message_reactions').insert({
          'message_id': message.id,
          'user_id': userId,
          'emoji': reaction,
          'reaction': reaction,
          'username': username,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Error updating reaction: $e');
      onError?.call('Failed to update reaction');
      // Caller should revert optimistic update if needed
    }
  }
}
