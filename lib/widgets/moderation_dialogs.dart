import 'package:flutter/material.dart';
import 'package:oasis/services/moderation_service.dart';
import 'package:oasis/models/moderation.dart';
import 'package:oasis/themes/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportDialog extends StatefulWidget {
  final String? userId;
  final String? postId;
  final String? commentId;
  final String? messageId;

  const ReportDialog({
    super.key,
    this.userId,
    this.postId,
    this.commentId,
    this.messageId,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _moderationService = ModerationService();
  final _descriptionController = TextEditingController();

  String _selectedCategory = ReportCategory.spam;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    setState(() => _isSubmitting = true);

    try {
      final categoryName = ReportCategory.getDisplayName(_selectedCategory);
      final details = _descriptionController.text.trim();

      final reportId = await _moderationService.submitReport(
        reportedUserId: widget.userId,
        postId: widget.postId,
        commentId: widget.commentId,
        messageId: widget.messageId,
        category: _selectedCategory,
        reason: categoryName,
        description: details.isEmpty ? null : details,
      );

      if (reportId != null && mounted) {
        // Launch email for support notification as requested
        await _launchSupportEmail(categoryName, details);

        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report submitted successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting report: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _launchSupportEmail(String category, String details) async {
    final type =
        widget.messageId != null
            ? 'Message'
            : widget.postId != null
            ? 'Post'
            : widget.commentId != null
            ? 'Comment'
            : 'User';

    final id =
        widget.messageId ??
        widget.postId ??
        widget.commentId ??
        widget.userId ??
        'N/A';

    final body = '''
New Report Submitted:
--------------------
Type: $type
Target ID: $id
Reported User ID: ${widget.userId ?? 'N/A'}
Category: $category
Details: ${details.isEmpty ? 'None provided' : details}

This report was also submitted to our moderation system.
''';

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'oasis.officialsupport@outlook.com',
      query:
          'subject=${Uri.encodeComponent('New Report: $category ($type)')}&body=${Uri.encodeComponent(body)}',
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      }
    } catch (e) {
      debugPrint('Could not launch email client: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appTheme = theme.extension<AppThemeExtension>()!;

    return AlertDialog(
      title: const Text('Report'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Why are you reporting this?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ...ReportCategory.all.map((category) {
              return RadioListTile<String>(
                value: category,
                groupValue: _selectedCategory,
                title: Text(ReportCategory.getDisplayName(category)),
                onChanged: (value) {
                  setState(() => _selectedCategory = value!);
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            }),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Details',
                hintText: 'Provide more context for our team...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: appTheme.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: appTheme.info.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: appTheme.info),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Note: Report details will be shared with Oasis Support via email for further review.',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child:
              _isSubmitting
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : const Text('Submit Report'),
        ),
      ],
    );
  }
}

class BlockUserDialog extends StatelessWidget {
  final String userId;
  final String username;

  const BlockUserDialog({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    final moderationService = ModerationService();

    return AlertDialog(
      title: const Text('Block User'),
      content: Text(
        'Are you sure you want to block @$username? They won\'t be able to see your posts or contact you.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final success = await moderationService.blockUser(userId);
            if (context.mounted) {
              Navigator.of(context).pop(success);
              if (success) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Blocked @$username')));
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Block'),
        ),
      ],
    );
  }
}

class MuteUserDialog extends StatefulWidget {
  final String userId;
  final String username;

  const MuteUserDialog({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<MuteUserDialog> createState() => _MuteUserDialogState();
}

class _MuteUserDialogState extends State<MuteUserDialog> {
  Duration? _duration;

  final List<MapEntry<String, Duration?>> _durationOptions = [
    const MapEntry('24 hours', Duration(hours: 24)),
    const MapEntry('7 days', Duration(days: 7)),
    const MapEntry('30 days', Duration(days: 30)),
    const MapEntry('Forever', null),
  ];

  @override
  Widget build(BuildContext context) {
    final moderationService = ModerationService();

    return AlertDialog(
      title: const Text('Mute User'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('You won\'t see posts from @${widget.username} in your feed.'),
          const SizedBox(height: 16),
          const Text(
            'Duration:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          RadioGroup<Duration?>(
            groupValue: _duration,
            onChanged: (value) {
              setState(() => _duration = value);
            },
            child: Column(
              children:
                  _durationOptions.map((option) {
                    return RadioListTile<Duration?>(
                      value: option.value,
                      title: Text(option.key),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed:
              _duration == null && _durationOptions.last.value != null
                  ? null
                  : () async {
                    final success = await moderationService.muteUser(
                      widget.userId,
                      duration: _duration,
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop(success);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Muted @${widget.username}')),
                        );
                      }
                    }
                  },
          child: const Text('Mute'),
        ),
      ],
    );
  }
}
