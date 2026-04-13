import 'package:flutter/material.dart';
import 'package:oasis/features/messages/domain/models/message.dart';
import 'package:oasis/features/messages/presentation/providers/chat_provider.dart';
import 'package:oasis/features/messages/presentation/screens/live_location_screen.dart';
import 'package:provider/provider.dart';

class LocationBubble extends StatelessWidget {
  const LocationBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.conversationId,
  });

  final Message message;
  final bool isMe;
  final String conversationId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLive = message.locationData != null && message.locationData!['is_live'] == true;
    final hasExpired = message.expiresAt != null && DateTime.now().isAfter(message.expiresAt!);
    final isActuallyLive = isLive && !hasExpired;

    return InkWell(
      onTap: () {
        if (message.locationData == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LiveLocationScreen(message: message),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActuallyLive ? Colors.green.withValues(alpha: 0.5) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Center(
                child: Icon(
                  Icons.map,
                  size: 48,
                  color: isActuallyLive ? Colors.green : theme.colorScheme.primary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isActuallyLive ? 'Live Location' : 'Location Ended',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isActuallyLive ? Colors.green : theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isActuallyLive ? 'Updating in real-time' : 'Sharing is stopped',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (isActuallyLive && isMe) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.withValues(alpha: 0.1),
                          foregroundColor: Colors.red,
                        ),
                        onPressed: () {
                          context.read<ChatProvider>().stopLiveLocation();
                        },
                        child: const Text('Stop Sharing'),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
