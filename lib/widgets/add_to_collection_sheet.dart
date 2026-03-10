import 'package:flutter/material.dart';
import 'package:morrow_v2/models/collection.dart';
import 'package:morrow_v2/services/collections_service.dart';

class AddToCollectionSheet extends StatefulWidget {
  final String postId;

  const AddToCollectionSheet({super.key, required this.postId});

  @override
  State<AddToCollectionSheet> createState() => _AddToCollectionSheetState();
}

class _AddToCollectionSheetState extends State<AddToCollectionSheet> {
  final _collectionsService = CollectionsService();
  List<Collection> _collections = [];
  Set<String> _selectedCollections = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    setState(() => _isLoading = true);
    try {
      final collections = await _collectionsService.getUserCollections();

      // Check which collections already contain this post
      final containingCollections = await _collectionsService
          .getCollectionsForPost(widget.postId);
      final containingIds = containingCollections.map((c) => c.id).toSet();

      if (mounted) {
        setState(() {
          _collections = collections;
          _selectedCollections = containingIds;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      // Get collections that were originally selected
      final originalCollections = await _collectionsService
          .getCollectionsForPost(widget.postId);
      final originalIds = originalCollections.map((c) => c.id).toSet();

      // Add to new collections
      for (final collectionId in _selectedCollections) {
        if (!originalIds.contains(collectionId)) {
          await _collectionsService.addToCollection(
            collectionId,
            widget.postId,
          );
        }
      }

      // Remove from deselected collections
      for (final collectionId in originalIds) {
        if (!_selectedCollections.contains(collectionId)) {
          await _collectionsService.removeFromCollection(
            collectionId,
            widget.postId,
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Collections updated')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _createNewCollection() async {
    final nameController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('New Collection'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'My Favorites',
              ),
              maxLength: 50,
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isNotEmpty) {
                    Navigator.of(context).pop(nameController.text.trim());
                  }
                },
                child: const Text('Create'),
              ),
            ],
          ),
    );

    if (result != null) {
      final collection = await _collectionsService.createCollection(
        name: result,
        isPrivate: true,
      );

      if (collection != null) {
        await _loadCollections();
        setState(() {
          _selectedCollections.add(collection.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Save to Collection',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_collections.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Text('No collections yet'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _createNewCollection,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Collection'),
                    ),
                  ],
                ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _collections.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      leading: const Icon(Icons.add_circle_outline),
                      title: const Text('Create new collection'),
                      onTap: _createNewCollection,
                    );
                  }

                  final collection = _collections[index - 1];
                  final isSelected = _selectedCollections.contains(
                    collection.id,
                  );

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedCollections.add(collection.id);
                        } else {
                          _selectedCollections.remove(collection.id);
                        }
                      });
                    },
                    title: Text(collection.name),
                    subtitle: Text('${collection.itemsCount} posts'),
                    secondary:
                        collection.isPrivate
                            ? const Icon(Icons.lock_outline, size: 20)
                            : null,
                  );
                },
              ),
            ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              child:
                  _isSaving
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
