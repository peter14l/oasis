import 'package:flutter/material.dart';
import 'package:oasis_v2/models/post.dart';
import 'package:oasis_v2/services/collections_service.dart';
import 'package:oasis_v2/widgets/post_card.dart';
import 'package:go_router/go_router.dart';

class CollectionDetailScreen extends StatefulWidget {
  final String collectionId;

  const CollectionDetailScreen({super.key, required this.collectionId});

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  final _collectionsService = CollectionsService();
  List<Post> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCollectionData();
  }

  Future<void> _loadCollectionData() async {
    setState(() => _isLoading = true);
    try {
      final items = await _collectionsService.getCollectionItems(
        widget.collectionId,
      );

      if (mounted) {
        setState(() {
          _posts = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading collection: $e')));
      }
    }
  }

  Future<void> _deleteCollection() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Collection'),
            content: const Text(
              'Are you sure you want to delete this collection? The posts will not be deleted.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _collectionsService.deleteCollection(widget.collectionId);
        if (mounted) {
          context.pop(); // Go back to collections list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting collection: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection'), // We could pass the name if we had it
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteCollection,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _posts.isEmpty
              ? const Center(child: Text('No posts in this collection'))
              : ListView.builder(
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  return PostCard(
                    post: _posts[index],
                    onLike: () {},
                    onComment: () {},
                    onShare: () {},
                  );
                },
              ),
    );
  }
}
