import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:oasis_v2/models/commitment.dart';

class CommitmentCard extends StatelessWidget {
  final Commitment commitment;
  final String currentUserId;
  final VoidCallback onMarkComplete;
  final void Function(MemberIntent intent) onSetIntent;

  const CommitmentCard({
    super.key,
    required this.commitment,
    required this.currentUserId,
    required this.onMarkComplete,
    required this.onSetIntent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myResponse = commitment.responses[currentUserId];
    final isCompleted = myResponse?.completed ?? false;
    final intent = myResponse?.intent;

    final totalResponses = commitment.responses.length;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surface,
        border: Border.all(
          color: isCompleted
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.colorScheme.outline.withValues(alpha: 0.15),
          width: isCompleted ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title row ─────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Completion check icon
                GestureDetector(
                  onTap: isCompleted ? null : onMarkComplete,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: isCompleted
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: isCompleted
                        ? const Icon(
                            FluentIcons.checkmark_16_filled,
                            size: 16,
                            color: Colors.white,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    commitment.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                          : null,
                    ),
                  ),
                ),
              ],
            ),

            // ── Description ──────────────────────────────────────────
            if (commitment.description != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Text(
                  commitment.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ── Progress dots ────────────────────────────────────────
            if (totalResponses > 0) ...[
              _MemberProgressRow(commitment: commitment),
              const SizedBox(height: 12),
            ],

            // ── Intent buttons ───────────────────────────────────────
            if (!isCompleted) ...[
              Row(
                children: [
                  _IntentChip(
                    label: "I'm In 👊",
                    isSelected: intent == MemberIntent.inTrying,
                    onTap: () => onSetIntent(MemberIntent.inTrying),
                    activeColor: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  _IntentChip(
                    label: "Skip today",
                    isSelected: intent == MemberIntent.out,
                    onTap: () => onSetIntent(MemberIntent.out),
                    activeColor: theme.colorScheme.error,
                  ),
                  const Spacer(),
                  if (intent == MemberIntent.inTrying)
                    TextButton(
                      onPressed: onMarkComplete,
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            FluentIcons.checkmark_circle_24_regular,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text('Done!'),
                        ],
                      ),
                    ),
                ],
              ),
            ] else ...[
              // Show completion note if any
              if (myResponse?.note != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color:
                        theme.colorScheme.primary.withValues(alpha: 0.08),
                  ),
                  child: Text(
                    '"${myResponse!.note}"',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── sub-widgets ─────────────────────────────────────────────────────────────

class _IntentChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;

  const _IntentChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? activeColor
                : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isSelected
                ? activeColor
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _MemberProgressRow extends StatelessWidget {
  final Commitment commitment;
  const _MemberProgressRow({required this.commitment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responses = commitment.responses.values.toList();

    return Row(
      children: [
        ...responses.take(5).map((r) {
          final done = r.completed;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.4),
              ),
            ),
          );
        }),
        const SizedBox(width: 6),
        Text(
          '${responses.where((r) => r.completed).length}/${responses.length} done',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
