import 'package:universal_io/io.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:oasis/services/auth_service.dart';
import 'package:oasis/services/post_service.dart';
import 'package:oasis/services/ai_content_service.dart';
import 'package:oasis/services/app_initializer.dart';
import 'package:oasis/features/feed/presentation/providers/feed_provider.dart';
import 'package:oasis/core/utils/responsive_layout.dart';
import 'package:oasis/core/utils/haptic_utils.dart';
import 'package:oasis/features/feed/domain/models/post_mood.dart';
import 'package:oasis/features/feed/domain/models/enhanced_poll.dart';
import 'package:oasis/widgets/mood_selector.dart';
import 'package:oasis/widgets/polls/poll_widgets.dart';

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
    bool isM3E = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: isM3E ? 20 : 18),
      label: Text(
        label, 
        style: TextStyle(
          fontSize: 14,
          fontWeight: isM3E ? FontWeight.bold : null,
        )
      ),
      style: FilledButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: isM3E ? 20 : 16, vertical: isM3E ? 12 : 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isM3E ? 16 : 12)),
        backgroundColor: isM3E ? colorScheme.secondaryContainer.withValues(alpha: 0.7) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 1000;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isM3E = themeProvider.isM3EEnabled;
    final disableTransparency = themeProvider.isM3ETransparencyDisabled;

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
                    color: isM3E 
                      ? (disableTransparency ? colorScheme.surfaceContainer : colorScheme.surfaceContainer.withValues(alpha: 0.5))
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(isM3E ? 24 : 16),
                    border: isM3E ? Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)) : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isM3E ? Border.all(color: colorScheme.primary.withValues(alpha: 0.2), width: 2) : null,
                        ),
                        padding: EdgeInsets.all(isM3E ? 2 : 0),
                        child: CircleAvatar(
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
                                      fontWeight: isM3E ? FontWeight.w800 : FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  )
                                  : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: isM3E ? FontWeight.bold : FontWeight.w600,
                              letterSpacing: isM3E ? -0.5 : null,
                            ),
                          ),
                          if (username.isNotEmpty)
                            Text(
                              username,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: isM3E ? FontWeight.w500 : null,
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
                hintStyle: (isM3E ? theme.textTheme.titleMedium : theme.textTheme.bodyLarge)?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontWeight: isM3E ? FontWeight.w500 : null,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: (isM3E ? theme.textTheme.titleMedium : theme.textTheme.bodyLarge)?.copyWith(
                height: 1.5,
              ),
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
                      (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final image = _selectedImages[index];
                    return Container(
                      width: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(isM3E ? 24 : 16),
                        border: Border.all(
                          color: colorScheme.outlineVariant,
                          width: 1,
                        ),
                        boxShadow: isM3E ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ] : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(isM3E ? 24 : 16),
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
              style: (isM3E ? theme.textTheme.titleSmall : theme.textTheme.titleSmall)?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: isM3E ? FontWeight.bold : FontWeight.w500,
                letterSpacing: isM3E ? 0.5 : null,
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
              style: (isM3E ? theme.textTheme.titleSmall : theme.textTheme.titleSmall)?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: isM3E ? FontWeight.bold : FontWeight.w500,
                letterSpacing: isM3E ? 0.5 : null,
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
                    isM3E: isM3E,
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.poll_outlined,
                    label: 'Poll',
                    onPressed: _togglePollCreator,
                    isM3E: isM3E,
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.auto_awesome,
                    label: 'AI Help',
                    onPressed: _generateAiSuggestions,
                    isM3E: isM3E,
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.location_on_outlined,
                    label: _locationController.text.isNotEmpty ? 'Change Location' : 'Location',
                    onPressed: _pickLocation,
                    isM3E: isM3E,
                  ),
                ],
              ),
            ),

            // Location display
            if (_locationController.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isM3E ? colorScheme.secondaryContainer : colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(isM3E ? 20 : 12),
                  border: Border.all(
                    color: colorScheme.secondary.withValues(alpha: isM3E ? 0.5 : 0.3),
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
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: isM3E ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => setState(() => _locationController.clear()),
                      child: Icon(Icons.close, size: 16, color: colorScheme.onSecondaryContainer),
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isM3E ? colorScheme.primaryContainer : colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(isM3E ? 20 : 12),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: isM3E ? 0.5 : 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.poll, color: colorScheme.onPrimaryContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _attachedPoll!.question,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isM3E ? FontWeight.bold : null,
                          color: colorScheme.onPrimaryContainer,
                        ),
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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer.withValues(alpha: isM3E ? 0.8 : 0.3),
                      colorScheme.tertiaryContainer.withValues(alpha: isM3E ? 0.8 : 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(isM3E ? 32 : 16),
                  border: isM3E ? Border.all(color: colorScheme.primary.withValues(alpha: 0.2)) : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: colorScheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'AI Suggestions',
                          style: (isM3E ? theme.textTheme.titleMedium : theme.textTheme.titleSmall)?.copyWith(
                            fontWeight: isM3E ? FontWeight.w800 : FontWeight.w600,
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
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      if (_captionSuggestions.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Caption ideas:',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: isM3E ? FontWeight.bold : null,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...(_captionSuggestions.map(
                          (caption) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () {
                                _captionController.text = caption;
                                HapticUtils.selectionClick();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(isM3E ? 16 : 8),
                                  border: isM3E ? Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)) : null,
                                ),
                                child: Text(
                                  caption,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )),
                      ],
                      if (_hashtagSuggestions.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Hashtags:', 
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: isM3E ? FontWeight.bold : null,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children:
                              _hashtagSuggestions
                                  .map(
                                    (tag) => ActionChip(
                                      label: Text('#$tag'),
                                      padding: isM3E ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8) : null,
                                      shape: isM3E ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)) : null,
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isM3E ? 20 : 12)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Post to Feed', style: TextStyle(fontWeight: isM3E ? FontWeight.w800 : FontWeight.bold)),
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
              borderRadius: BorderRadius.circular(isM3E ? 36 : 24),
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
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: isM3E ? FontWeight.w800 : FontWeight.bold,
                          letterSpacing: isM3E ? -1 : null,
                        ),
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
          style: (isM3E ? theme.textTheme.headlineSmall : theme.textTheme.titleLarge)?.copyWith(
            fontWeight: isM3E ? FontWeight.w800 : FontWeight.bold,
            letterSpacing: isM3E ? -1 : null,
          ),
        ),
        centerTitle: isM3E,
        elevation: 0,
        scrolledUnderElevation: isM3E ? 0 : 1,
        backgroundColor: isM3E ? colorScheme.surface : null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Center(
              child: FilledButton(
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
                    borderRadius: BorderRadius.circular(isM3E ? 16 : 12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  elevation: isM3E ? 0 : null,
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
                        : Text(
                          'Post',
                          style: TextStyle(
                            fontWeight: isM3E ? FontWeight.w800 : FontWeight.w600,
                            letterSpacing: isM3E ? 0.5 : null,
                          ),
                        ),
              ),
            ),
          ),
        ],
      ),
      body: formContent,
    );
  }
}
