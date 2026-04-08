import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oasis/features/calling/domain/models/call_entity.dart';
import 'package:oasis/services/call_service.dart';
import 'package:provider/provider.dart';

class IncomingCallOverlay extends StatelessWidget {
  final CallEntity call;

  const IncomingCallOverlay({super.key, required this.call});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.withValues(alpha: 0.2),
              child: Icon(
                call.type == CallType.video ? Icons.videocam : Icons.call,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Incoming ${call.type.name} call',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    call.channelName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                context.read<CallService>().endCall(call.id);
              },
              icon: const Icon(Icons.close, color: Colors.red),
            ),
            IconButton(
              onPressed: () {
                context.read<CallService>().answerCall(call);
                context.pushNamed(
                  'active_call',
                  pathParameters: {'callId': call.id},
                  extra: call,
                );
              },
              icon: const Icon(Icons.check, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
