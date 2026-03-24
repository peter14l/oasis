import 'package:universal_io/io.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:oasis_v2/services/auth_service.dart';
import 'package:oasis_v2/services/post_service.dart';
import 'package:oasis_v2/services/ai_content_service.dart';
import 'package:oasis_v2/providers/feed_provider.dart';
import 'package:oasis_v2/utils/responsive_layout.dart';
import 'package:oasis_v2/utils/haptic_utils.dart';
import 'package:oasis_v2/models/post_mood.dart';
import 'package:oasis_v2/models/enhanced_poll.dart';
import 'package:oasis_v2/widgets/mood_selector.dart';
import 'package:oasis_v2/widgets/polls/poll_widgets.dart';

class CreatePostScreen extends StatefulWidget {
  final String? communityId;

  const CreatePostScreen({super.key, this.communityId});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();
  // AIContentService is used statically

  List<XFile> _selectedImages = [];
  bool _isLoading = false;

  // Mood and Poll state
  PostMood? _selectedMood;
  EnhancedPoll? _attachedPoll;
  bool _showPollCreator = false;

  // AI suggestions
  List<String> _captionSuggestions = [];
  List<String> _hashtagSuggestions = [];
  bool _showAiSuggestions = false;
  bool _isLoadingAi = false;

  // Missing variables
  final List<String> _detectedLabels =
      []; // Mock or populated from image analysis
  final TextEditingController _locationController = TextEditingController();

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    if (hour < 21) return 'Evening';
    return 'Night';
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 85);

      if (images.isNotEmpty && mounted) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick images: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _createPost() async {
    if (_captionController.text.trim().isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a caption or image')),
      );
      return;
    }

    final userId = _authService.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to create a post')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create post
      final post = await _postService.createPost(
        userId: userId,
        communityId: widget.communityId,
        content:
            _captionController.text.trim().isEmpty
                ? null
                : _captionController.text.trim(),
        mediaFiles: _selectedImages.map((file) => File(file.path)).toList(),
        mediaTypes: List.filled(_selectedImages.length, 'image'),
      );

      if (!mounted) return;

      // Add post to feed provider
      context.read<FeedProvider>().addPost(post);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to feed
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/feed');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create post: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateAiSuggestions() async {
    if (_captionController.text.trim().isEmpty && _selectedImages.isEmpty) {
      return;
    }

    HapticUtils.lightImpact();
    setState(() {
      _isLoadingAi = true;
      _showAiSuggestions = true;
    });

    try {
      // Get suggestions based on current content

      final captions = AIContentService.generateCaptionSuggestions(
        detectedObjects: _detectedLabels,
        location: _locationController.text,
        mood: _selectedMood?.label,
        timeOfDay: _getTimeOfDay(),
      );

      final hashtags = AIContentService.generateHashtagSuggestions(
        detectedObjects: _detectedLabels,
        location: _locationController.text,
        mood: _selectedMood?.label,
      );

      if (mounted) {
        setState(() {
          _captionSuggestions = captions;
          _hashtagSuggestions = hashtags;
          _isLoadingAi = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAi = false;
        });
      }
    }
  }

  Future<void> _pickLocation() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        String tempLocation = '';
        return AlertDialog(
          title: const Text('Add Location'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Where are you?',
              prefixIcon: Icon(Icons.location_on),
            ),
            onChanged: (value) => tempLocation = value,
            onSubmitted: (value) => Navigator.pop(context, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, tempLocation),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _locationController.text = result;
      });
      HapticUtils.success();
    }
  }

  void _togglePollCreator() {
    HapticUtils.selectionClick();
    setState(() {
      _showPollCreator = !_showPollCreator;
      if (!_showPollCreator) {
        _attachedPoll = null;
      }
    });
  }

  void _onPollCreated(EnhancedPoll poll) {
    HapticUtils.success();
    setState(() {
      _attachedPoll = poll;
      _showPollCreator = false;
    });
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 14)),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    final formContent = SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Consumer<AuthService>(
              builder: (context, authService, child) {
                final user = authService.currentUser;
                final displayName =
                    user?.displayName ?? user?.username ?? 'User';
                final username =
                    user?.username != null ? '@${user!.username}' : '';
                final avatarUrl = user?.photoUrl;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        backgroundImage:
                            avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child:
                            avatarUrl == null
                                ? Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                )
                                : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (username.isNotEmpty)
                            Text(
                              username,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Caption field
            TextField(
              controller: _captionController,
              maxLines: 6,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'What\'s on your mind?',
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: theme.textTheme.bodyLarge,
              textCapitalization: TextCapitalization.sentences,
            ),

            // Image preview
            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  separatorBuilder:
                      (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final image = _selectedImages[index];
                    return Container(
                      width: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(File(image.path), fit: BoxFit.cover),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedImages.removeAt(index);
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Mood selector
            Text(
              'How are you feeling?',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            MoodSelector(
              selectedMood: _selectedMood,
              onMoodSelected: (mood) {
                HapticUtils.selectionClick();
                setState(() => _selectedMood = mood);
              },
            ),

            const SizedBox(height: 24),

            // Add to post options
            Text(
              'Add to your post',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildActionButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Photo',
                    onPressed: _pickImages,
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.poll_outlined,
                    label: 'Poll',
                    onPressed: _togglePollCreator,
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.auto_awesome,
                    label: 'AI Help',
                    onPressed: _generateAiSuggestions,
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.location_on_outlined,
                    label: _locationController.text.isNotEmpty ? 'Change Location' : 'Location',
                    onPressed: _pickLocation,
                  ),
                ],
              ),
            ),

            // Location display
            if (_locationController.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, size: 18, color: colorScheme.secondary),
                    const SizedBox(width: 8),
                    Text(
                      _locationController.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => setState(() => _locationController.clear()),
                      child: Icon(Icons.close, size: 16, color: colorScheme.secondary),
                    ),
                  ],
                ),
              ),
            ],

            // Poll creator
            if (_showPollCreator) ...[
              const SizedBox(height: 16),
              PollCreator(
                onPollCreated: _onPollCreated,
                onCancel: () => setState(() => _showPollCreator = false),
              ),
            ],

            // Attached poll preview
            if (_attachedPoll != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.poll, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _attachedPoll!.question,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _attachedPoll = null),
                    ),
                  ],
                ),
              ),
            ],

            // AI suggestions panel
            if (_showAiSuggestions) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer.withValues(alpha: 0.3),
                      colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI Suggestions',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed:
                              () => setState(() => _showAiSuggestions = false),
                        ),
                      ],
                    ),
                    if (_isLoadingAi)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      if (_captionSuggestions.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Caption ideas:',
                          style: theme.textTheme.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        ...(_captionSuggestions.map(
                          (caption) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () {
                                _captionController.text = caption;
                                HapticUtils.selectionClick();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  caption,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ),
                          ),
                        )),
                      ],
                      if (_hashtagSuggestions.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text('Hashtags:', style: theme.textTheme.labelMedium),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              _hashtagSuggestions
                                  .map(
                                    (tag) => ActionChip(
                                      label: Text('#$tag'),
                                      onPressed: () {
                                        _captionController.text += ' #$tag';
                                        HapticUtils.lightImpact();
                                      },
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],

            if (isDesktop) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _createPost,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Post to Feed', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      );

    if (isDesktop) {
      return Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Row(
                    children: [
                      Text(
                        'Create New Post',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Flexible(child: formContent),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Post',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilledButton.tonal(
              onPressed: _isLoading ? null : _createPost,
              style: FilledButton.styleFrom(
                backgroundColor:
                    _isLoading
                        ? colorScheme.primary.withValues(alpha: 0.1)
                        : colorScheme.primary,
                foregroundColor:
                    _isLoading
                        ? colorScheme.onSurface.withValues(alpha: 0.6)
                        : colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Text(
                        'Post',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
            ),
          ),
        ],
      ),
      body: formContent,
    );
  }
}
