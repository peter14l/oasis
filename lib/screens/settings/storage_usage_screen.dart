import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StorageUsageScreen extends StatefulWidget {
  const StorageUsageScreen({super.key});

  @override
  State<StorageUsageScreen> createState() => _StorageUsageScreenState();
}

class _StorageUsageScreenState extends State<StorageUsageScreen> {
  // Placeholder values for storage usage
  final double _imageSize = 45.2; // MB
  final double _videoSize = 12.8; // MB
  final double _otherSize = 5.4; // MB

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalSize = _imageSize + _videoSize + _otherSize;
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    final content = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStorageBar(context, totalSize),
          const SizedBox(height: 24),
          _buildUsageItem(
            context,
            'Images',
            '${_imageSize.toStringAsFixed(1)} MB',
            Colors.blue,
          ),
          _buildUsageItem(
            context,
            'Videos',
            '${_videoSize.toStringAsFixed(1)} MB',
            Colors.green,
          ),
          _buildUsageItem(
            context,
            'Other Files',
            '${_otherSize.toStringAsFixed(1)} MB',
            Colors.amber,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              // TODO: Logic to Clear Cache
              // For now, simulator success
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Cache cleared!')));
            },
            icon: const Icon(Icons.delete_sweep_outlined),
            label: const Text('Clear All Cache'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.onErrorContainer,
            ),
          ),
        ],
      );

    if (isDesktop) return Material(color: Colors.transparent, child: content);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Usage'),
        centerTitle: true,
      ),
      body: content,
    );
  }

  Widget _buildStorageBar(BuildContext context, double totalSize) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Usage',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${totalSize.toStringAsFixed(1)} MB',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: totalSize / 100, // 100MB as max for display
            minHeight: 12,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsageItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
