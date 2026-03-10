import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:morrow_v2/services/stories_service.dart';
import 'package:go_router/go_router.dart';

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
          const SnackBar(content: Text('Story shared successfully!')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main Content Area
          if (_selectedFile != null)
            Positioned.fill(
              child: _mediaType == 'video'
                  ? const Center(child: Icon(Icons.videocam, color: Colors.white24, size: 100)) // Video placeholder
                  : Image.file(_selectedFile!, fit: BoxFit.cover),
            )
          else
            _buildEmptyState(),

          // Overlay Controls (Gradient)
          if (_selectedFile != null)
             Positioned.fill(
               child: Container(
                 decoration: const BoxDecoration(
                   gradient: LinearGradient(
                     begin: Alignment.topCenter,
                     end: Alignment.bottomCenter,
                     colors: [
                       Colors.black54,
                       Colors.transparent,
                       Colors.transparent,
                       Colors.black87,
                     ],
                     stops: [0.0, 0.2, 0.7, 1.0],
                   ),
                 ),
               ),
             ),

          // Top App Bar Controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => context.pop(),
                  ),
                  if (_selectedFile != null)
                    Row(
                      children: [
                        IconButton(
                           icon: Icon(
                             _isCaptionVisible ? Icons.text_fields : Icons.text_fields_outlined,
                             color: Colors.white,
                             size: 28,
                           ),
                           onPressed: () {
                             setState(() {
                               _isCaptionVisible = !_isCaptionVisible;
                             });
                           },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.crop_rotate, color: Colors.white, size: 28),
                          onPressed: () {
                            // TODO: Implement simple rotate or crop
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Editing tools coming soon!')),
                            );
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Caption Input Overlay
          if (_isCaptionVisible && _selectedFile != null)
            Positioned(
              left: 20,
              right: 20,
              top: MediaQuery.of(context).size.height / 3,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _captionController,
                  autofocus: true,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Type something...',
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                  maxLines: 5,
                  minLines: 1,
                ),
              ),
            ),

          // Bottom Controls (Post Button)
          if (_selectedFile != null)
            Positioned(
              bottom: 30,
              right: 20,
              left: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Change Media Button
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _selectedFile = null;
                      _isCaptionVisible = false;
                      _captionController.clear();
                    }),
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text('Retake', style: TextStyle(color: Colors.white)),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white10,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),

                  // Post Button
                  FilledButton.icon(
                    onPressed: _isUploading ? null : _createStory,
                    icon: _isUploading 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.send_rounded, size: 20),
                    label: Text(_isUploading ? 'Sharing...' : 'Share Story'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_a_photo_outlined, size: 60, color: Colors.white38),
          const SizedBox(height: 20),
          const Text(
            'Add to Story',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               _buildPickerButton(
                 icon: Icons.camera_alt_rounded,
                 label: 'Camera',
                 onTap: () => _pickMedia(ImageSource.camera),
               ),
               const SizedBox(width: 20),
               _buildPickerButton(
                 icon: Icons.photo_library_rounded,
                 label: 'Gallery',
                 onTap: () => _pickMedia(ImageSource.gallery),
               ),
            ],
          ),
          const SizedBox(height: 20),
           _buildPickerButton(
             icon: Icons.videocam_rounded,
             label: 'Video',
             onTap: () => _pickMedia(ImageSource.gallery, isVideo: true),
             isSmall: true,
           ),
        ],
      ),
    );
  }

  Widget _buildPickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSmall = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: isSmall ? 140 : 120,
        height: isSmall ? 50 : 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: isSmall 
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 40),
                const SizedBox(height: 12),
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
      ),
    );
  }
}
