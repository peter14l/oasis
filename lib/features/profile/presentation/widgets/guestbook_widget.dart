import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:oasis/features/profile/domain/models/guestbook_entry.dart';
import 'package:oasis/features/profile/data/guestbook_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class GuestbookWidget extends StatefulWidget {
  final String profileId;
  final String currentUserId;
  final bool isOwner;

  const GuestbookWidget({
    super.key,
    required this.profileId,
    required this.currentUserId,
    required this.isOwner,
  });

  @override
  State<GuestbookWidget> createState() => _GuestbookWidgetState();
}

class _GuestbookWidgetState extends State<GuestbookWidget> {
  final GuestbookService _service = GuestbookService();
  final TextEditingController _controller = TextEditingController();
  List<GuestbookEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final entries = await _service.getGuestbookEntries(widget.profileId);
    if (mounted) {
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    }
  }

  Future<void> _signGuestbook() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Optional: add optimistic UI update here
    final newEntry = await _service.signGuestbook(
      profileId: widget.profileId,
      visitorId: widget.currentUserId,
      message: text,
    );

    if (newEntry != null && mounted) {
      setState(() {
        _entries.insert(0, newEntry);
        _controller.clear();
      });
    }
  }

  Future<void> _deleteEntry(GuestbookEntry entry) async {
    // Only owner or author can delete
    if (widget.isOwner || entry.visitorId == widget.currentUserId) {
      await _service.removeEntry(entry.id);
      if (mounted) {
        setState(() {
          _entries.removeWhere((e) => e.id == entry.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FluentIcons.book_24_regular, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Guestbook',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_entries.length} signatures',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Sign form (only if not owner)
          if (!widget.isOwner) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLength: 100,
                    decoration: InputDecoration(
                      hintText: 'Leave a gentle signature...',
                      counterText: '',
                      filled: true,
                      fillColor: colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _signGuestbook,
                  icon: const Icon(Icons.send_rounded, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Entries list
          if (_isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ))
          else if (_entries.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Column(
                  children: [
                    Icon(FluentIcons.book_add_24_regular, size: 48, color: colorScheme.primary.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'No signatures yet',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _entries.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final entry = _entries[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: entry.visitorAvatar.isNotEmpty
                          ? CachedNetworkImageProvider(entry.visitorAvatar)
                          : null,
                      child: entry.visitorAvatar.isEmpty
                          ? const Icon(Icons.person, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                entry.visitorName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const Spacer(),
                              if (widget.isOwner || entry.visitorId == widget.currentUserId)
                                GestureDetector(
                                  onTap: () => _deleteEntry(entry),
                                  child: Icon(
                                    FluentIcons.delete_24_regular,
                                    size: 14,
                                    color: colorScheme.error.withValues(alpha: 0.7),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.message,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
