import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oasis/features/messages/domain/models/message.dart';
import 'package:oasis/features/messages/presentation/providers/chat_provider.dart';
import 'package:oasis/features/messages/presentation/screens/live_location_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationBubble extends StatefulWidget {
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
  State<LocationBubble> createState() => _LocationBubbleState();
}

class _LocationBubbleState extends State<LocationBubble> {
  late Message _currentMessage;
  RealtimeChannel? _channel;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _currentMessage = widget.message;
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    // Realtime subscription for location updates
    _channel = Supabase.instance.client
        .channel('live_loc_bubble_${_currentMessage.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: _currentMessage.id,
          ),
          callback: (payload) {
            if (mounted) {
              setState(() {
                _currentMessage = Message.fromJson(payload.newRecord);
              });
            }
          },
        )
        .subscribe();

    // Polling fallback - refresh location every 15 seconds if realtime fails
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _pollLocationUpdate();
    });
  }

  Future<void> _pollLocationUpdate() async {
    try {
      final response = await Supabase.instance.client
          .from('messages')
          .select('location_data')
          .eq('id', _currentMessage.id)
          .maybeSingle();

      if (response != null && mounted && response['location_data'] != null) {
        final locData = response['location_data'] as Map<String, dynamic>;
        if (locData['latitude'] != _currentMessage.locationData?['latitude'] ||
            locData['longitude'] !=
                _currentMessage.locationData?['longitude']) {
          setState(() {
            _currentMessage = _currentMessage.copyWith(locationData: locData);
          });
        }
      }
    } catch (e) {
      debugPrint('Location polling error: $e');
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLive =
        _currentMessage.locationData != null &&
        _currentMessage.locationData!['is_live'] == true;
    final hasExpired =
        _currentMessage.expiresAt != null &&
        DateTime.now().isAfter(_currentMessage.expiresAt!);
    final isActuallyLive = isLive && !hasExpired;

    // Get coordinates for map
    LatLng? mapCenter;
    if (_currentMessage.locationData != null) {
      final lat = _currentMessage.locationData!['latitude'];
      final lng = _currentMessage.locationData!['longitude'];
      if (lat != null && lng != null) {
        mapCenter = LatLng(lat as double, lng as double);
      }
    }

    return InkWell(
      onTap: () {
        if (_currentMessage.locationData == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LiveLocationScreen(message: _currentMessage),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActuallyLive
                ? Colors.green.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Map Preview
            SizedBox(
              height: 120,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: mapCenter != null
                    ? _LiveLocationMapPreview(
                        center: mapCenter,
                        isLive: isActuallyLive,
                      )
                    : Container(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.5,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.map,
                            size: 48,
                            color: isActuallyLive
                                ? Colors.green
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isActuallyLive)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Text(
                        isActuallyLive ? 'Live Location' : 'Location Ended',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isActuallyLive
                              ? Colors.green
                              : theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isActuallyLive
                        ? 'Tap to view on map'
                        : 'Sharing is stopped',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (isActuallyLive && widget.isMe) ...[
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
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mini map preview for the bubble - shows static map with marker
class _LiveLocationMapPreview extends StatelessWidget {
  final LatLng center;
  final bool isLive;

  const _LiveLocationMapPreview({required this.center, required this.isLive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Using static map image as preview (more reliable than live map in bubble)
    // The full LiveLocationScreen has the interactive map
    return Stack(
      fit: StackFit.expand,
      children: [
        // Static map preview using Google Maps static API would be ideal
        // For now, show a styled placeholder with location indicator
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
                theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isLive ? Colors.green : theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isLive ? Colors.green : theme.colorScheme.primary)
                                .withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(Icons.location_on, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 8),
                if (isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Map overlay pattern to simulate map tiles
        CustomPaint(painter: _MapGridPainter()),
      ],
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw grid lines to simulate map
    const spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
