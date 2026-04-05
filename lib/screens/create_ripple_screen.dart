import 'package:universal_io/io.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oasis/core/network/supabase_client.dart';
import 'package:uuid/uuid.dart';

class CreateRippleScreen extends StatefulWidget {
  const CreateRippleScreen({super.key});

  @override
  State<CreateRippleScreen> createState() => _CreateRippleScreenState();
}

class _CreateRippleScreenState extends State<CreateRippleScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();
  final _uuid = const Uuid();
  
  File? _videoFile;
  VideoPlayerController? _videoController;
  bool _isLoading = false;

  @override
  void dispose() {
    _videoController?.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      _videoController?.dispose();
      final file = File(video.path);
      final controller = VideoPlayerController.file(file);
      try {
        await controller.initialize();
        if (mounted) {
          setState(() {
            _videoFile = file;
            _videoController = controller;
          });
          controller.setLooping(true);
          controller.play();
        }
      } catch (e) {
        debugPrint('Error initializing video: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not play this video: $e')),
          );
        }
      }
    }
  }

  Future<void> _uploadRipple() async {
    if (_videoFile == null) return;

    setState(() => _isLoading = true);

    try {
      final supabase = SupabaseService().client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // 1. Upload video
      final fileExt = _videoFile!.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4()}.$fileExt';
      final storagePath = '$userId/$fileName';

      await supabase.storage.from('ripples-videos').upload(storagePath, _videoFile!);
      final videoUrl = supabase.storage.from('ripples-videos').getPublicUrl(storagePath);

      // 2. Create DB record
      await supabase.from('ripples').insert({
        'user_id': userId,
        'video_url': videoUrl,
        'caption': _captionController.text.trim(),
        'is_private': false, // Logic for private/public can be added based on user profile
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ripple shared!')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    final content = SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 32.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickVideo,
                child: AspectRatio(
                  aspectRatio: 9/16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: _videoController != null && _videoController!.value.isInitialized
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: VideoPlayer(_videoController!),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(FluentIcons.video_add_24_regular, color: Colors.white54, size: 48),
                            const SizedBox(height: 12),
                            Text('Select a video', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white54)),
                          ],
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _captionController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Add a caption...',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (isDesktop && _videoFile != null) ...[
                const SizedBox(height: 32),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _uploadRipple,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Share Ripple', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ],
          ),
        ),
      );

    if (isDesktop) {
      return Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Row(
                    children: [
                      const Text('New Ripple', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10),
                Flexible(child: content),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(FluentIcons.dismiss_24_filled, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('New Ripple', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (_videoFile != null)
            TextButton(
              onPressed: _isLoading ? null : _uploadRipple,
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Share', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
        ],
      ),
      body: content,
    );
  }
}
