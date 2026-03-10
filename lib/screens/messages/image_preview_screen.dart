import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:morrow_v2/services/media_download_service.dart';

class ImagePreviewScreen extends StatelessWidget {
  final String imageUrl;
  final String? caption;

  const ImagePreviewScreen({super.key, required this.imageUrl, this.caption});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaDownloadService = MediaDownloadService();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              try {
                final success = await mediaDownloadService.downloadImage(
                  imageUrl,
                  context,
                );
                if (context.mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Image saved to gallery'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to download: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          PhotoView(
            imageProvider: CachedNetworkImageProvider(imageUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            initialScale: PhotoViewComputedScale.contained,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            loadingBuilder:
                (context, event) => Center(
                  child: CircularProgressIndicator(
                    value:
                        event == null
                            ? 0
                            : event.cumulativeBytesLoaded /
                                event.expectedTotalBytes!,
                  ),
                ),
            errorBuilder:
                (context, error, stackTrace) => const Center(
                  child: Icon(Icons.error, color: Colors.white, size: 48),
                ),
          ),
          if (caption != null && caption!.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                child: Text(
                  caption!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
