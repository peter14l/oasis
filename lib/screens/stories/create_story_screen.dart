import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oasis_v2/services/stories_service.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final _storiesService = StoriesService();
  final _captionController = TextEditingController();
  final _imagePicker = ImagePicker();

  File? _selectedFile;
  String _mediaType = 'image';
  bool _isUploading = false;
  bool _isCaptionVisible = false;
  
  // Text Overlay State
  int _textBackgroundMode = 0; // 0: None, 1: Solid, 2: Translucent
  TextAlign _textAlign = TextAlign.center;
  Color _textColor = Colors.white;
  final List<String> _fontStyles = ['Classic', 'Neon', 'Typewriter', 'Strong'];
  int _selectedFontIndex = 0;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(ImageSource source, {bool isVideo = false}) async {
    try {
      XFile? file;
      if (isVideo) {
        file = await _imagePicker.pickVideo(
          source: source,
          maxDuration: const Duration(seconds: 30),
        );
      } else {
        file = await _imagePicker.pickImage(
          source: source,
          maxWidth: 1080,
          maxHeight: 1920,
          imageQuality: 85,
        );
      }

      if (file != null) {
        setState(() {
          _selectedFile = File(file!.path);
          _mediaType = isVideo ? 'video' : 'image';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking media: $e')),
        );
      }
    }
  }

  Future<void> _createStory() async {
    if (_selectedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final story = await _storiesService.createStory(
        file: _selectedFile!,
        mediaType: _mediaType,
        caption: _captionController.text.trim().isEmpty
            ? null
            : _captionController.text.trim(),
      );

      if (story != null && mounted) {
        context.pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story shared successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        throw Exception('Failed to create story');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating story: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _toggleTextBackground() {
    setState(() {
      _textBackgroundMode = (_textBackgroundMode + 1) % 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Force a black background for the entire screen area
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Stack(
          children: [
            // ── Main Content Area ──
            if (_selectedFile != null)
              _buildImmersivePreview()
            else
              _buildEmptyState(),

            // ── Dynamic Editing UI (Only when media selected) ──
            if (_selectedFile != null) ...[
              // Cinematic Gradients for controls visibility
              _buildCinematicGradients(),
              
              // Side Toolbar
              if (!_isCaptionVisible) _buildSideToolbar(),
              
              // Top Action Buttons
              _buildTopToolbar(),
              
              // Text Editor Overlay
              if (_isCaptionVisible) _buildTextEditor(),
              
              // Bottom Sharing bar
              if (!_isCaptionVisible) _buildBottomActionBar(),
            ],
            
            // ── Back Button (Always visible when empty) ──
            if (_selectedFile == null)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildBlurButton(
                    icon: Icons.close_rounded,
                    onTap: () => context.pop(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImmersivePreview() {
    return Positioned.fill(
      child: FadeIn(
        duration: const Duration(milliseconds: 400),
        child: Hero(
          tag: 'story_preview',
          child: _mediaType == 'video'
              ? Container(
                  color: Colors.black,
                  child: const Center(
                    child: Icon(Icons.play_circle_fill, color: Colors.white54, size: 80),
                  ),
                )
              : Image.file(_selectedFile!, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildCinematicGradients() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.7),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: 0.7),
              ],
              stops: const [0.0, 0.2, 0.8, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopToolbar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildBlurButton(
              icon: Icons.close_rounded,
              onTap: () => setState(() => _selectedFile = null),
            ),
            Row(
              children: [
                _buildBlurButton(
                  icon: Icons.music_note_rounded,
                  onTap: () {}, // Add music
                ),
                const SizedBox(width: 12),
                _buildBlurButton(
                  icon: Icons.face_retouching_natural_rounded,
                  onTap: () {}, // Effects
                ),
                const SizedBox(width: 12),
                _buildBlurButton(
                  icon: Icons.download_rounded,
                  onTap: () {}, // Save locally
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideToolbar() {
    return Positioned(
      right: 16,
      top: MediaQuery.of(context).size.height * 0.25,
      child: FadeInRight(
        duration: const Duration(milliseconds: 300),
        child: Column(
          children: [
            _buildSideTool(
              icon: Icons.text_fields_rounded,
              label: 'Aa',
              onTap: () => setState(() => _isCaptionVisible = true),
            ),
            const SizedBox(height: 20),
            _buildSideTool(
              icon: Icons.sticky_note_2_rounded,
              label: 'Stickers',
              onTap: () {},
            ),
            const SizedBox(height: 20),
            _buildSideTool(
              icon: Icons.gesture_rounded,
              label: 'Draw',
              onTap: () {},
            ),
            const SizedBox(height: 20),
            _buildSideTool(
              icon: Icons.auto_awesome_rounded,
              label: 'Filters',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      left: 20,
      right: 20,
      child: FadeInUp(
        duration: const Duration(milliseconds: 400),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _isUploading ? null : _createStory,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isUploading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Your Story',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: -0.5,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildCircleActionButton(
              icon: Icons.chevron_right_rounded,
              onTap: () {
                // Future: Show specific person list
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextEditor() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Column(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildBlurButton(
                        icon: Icons.align_horizontal_center_rounded,
                        onTap: () {}, // Cycle alignment
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _toggleTextBackground,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _textBackgroundMode > 0 ? Colors.white : Colors.white24,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.format_color_text_rounded,
                            color: _textBackgroundMode > 0 ? Colors.black : Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: () => setState(() => _isCaptionVisible = false),
                        child: const Text(
                          'Done',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: TextField(
                      controller: _captionController,
                      autofocus: true,
                      maxLines: null,
                      textAlign: _textAlign,
                      cursorColor: Colors.white,
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        backgroundColor: _textBackgroundMode == 1 
                            ? Colors.white 
                            : _textBackgroundMode == 2 
                                ? Colors.black54 
                                : null,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Type something...',
                        hintStyle: TextStyle(color: Colors.white38),
                      ),
                    ),
                  ),
                ),
              ),
              // Font Picker
              Container(
                height: 80,
                padding: const EdgeInsets.only(bottom: 20),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _fontStyles.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedFontIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFontIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white10,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: isSelected ? Colors.white : Colors.white24),
                        ),
                        child: Center(
                          child: Text(
                            _fontStyles[index],
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ZoomIn(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
                child: const Icon(Icons.auto_awesome_mosaic_rounded, size: 60, color: Colors.white70),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Create a Story',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share a moment with your friends',
              style: TextStyle(color: Colors.white38, fontSize: 16),
            ),
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildModernPickerItem(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  color: const Color(0xFF3D8BFF),
                  onTap: () => _pickMedia(ImageSource.camera),
                ),
                const SizedBox(width: 24),
                _buildModernPickerItem(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  color: const Color(0xFFFF4B8B),
                  onTap: () => _pickMedia(ImageSource.gallery),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernPickerItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white.withValues(alpha: 0.1),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildSideTool({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          _buildBlurButton(icon: icon, onTap: onTap),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleActionButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black, size: 24),
      ),
    );
  }
}
