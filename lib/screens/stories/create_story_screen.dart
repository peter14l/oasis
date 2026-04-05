import 'package:universal_io/io.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oasis/services/stories_service.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:oasis/services/app_initializer.dart';
import 'package:oasis/core/utils/haptic_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:oasis/widgets/stories/music_picker_sheet.dart';
import 'package:oasis/models/story_model.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final _storiesService = StoriesService();
  final _captionController = TextEditingController();
  final _imagePicker = ImagePicker();
  final GlobalKey _boundaryKey = GlobalKey();

  File? _selectedFile;
  String _mediaType = 'image';
  bool _isUploading = false;
  bool _isCaptionVisible = false;
  bool _isDrawingMode = false;
  bool _isFilterPickerVisible = false;
  StoryMusic? _selectedMusic;

  // Text Overlay State
  List<StoryText> _texts = [];
  int? _editingTextIndex;
  bool _isDraggingText = false;
  bool _isTextOverTrash = false;
  int _textBackgroundMode = 0;
  final TextAlign _textAlign = TextAlign.center;
  Color _textColor = Colors.white;
  int _selectedFontIndex = 0;

  // Drawing State
  List<List<DrawingPoint>> _strokes = [];
  List<DrawingPoint> _currentStroke = [];
  Color _selectedColor = Colors.white;
  final double _strokeWidth = 5.0;
  bool _isEraserMode = false;

  // Filter State
  int _selectedFilterIndex = 0;
  final List<Map<String, dynamic>> _filterPresets = [
    {
      'name': 'Normal',
      'matrix': <double>[
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ],
    },
    {
      'name': 'Clarendon',
      'matrix': <double>[
        1.2,
        0,
        0,
        0,
        0,
        0,
        1.1,
        0,
        0,
        0,
        0,
        0,
        1.5,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ],
    },
    {
      'name': 'Gingham',
      'matrix': <double>[
        0.9,
        0,
        0,
        0,
        0,
        0,
        0.9,
        0,
        0,
        0,
        0,
        0,
        0.9,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ],
    },
    {
      'name': 'Moon',
      'matrix': <double>[
        0.21,
        0.71,
        0.07,
        0,
        0,
        0.21,
        0.71,
        0.07,
        0,
        0,
        0.21,
        0.71,
        0.07,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ],
    },
    {
      'name': 'Lark',
      'matrix': <double>[
        1.1,
        0,
        0,
        0,
        0,
        0,
        1.1,
        0,
        0,
        0,
        0,
        0,
        1.3,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ],
    },
    {
      'name': 'Reyes',
      'matrix': <double>[
        1,
        0,
        0,
        0,
        50,
        0,
        1,
        0,
        0,
        50,
        0,
        0,
        1,
        0,
        20,
        0,
        0,
        0,
        1,
        0,
      ],
    },
    {
      'name': 'Juno',
      'matrix': <double>[
        1.1,
        0,
        0,
        0,
        0,
        0,
        1.3,
        0,
        0,
        0,
        0,
        0,
        1.1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ],
    },
  ];

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<File?> _captureCompositeImage() async {
    try {
      final boundary =
          _boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/composite_story_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(byteData.buffer.asUint8List());
      return file;
    } catch (e) {
      debugPrint('Error capturing composite image: $e');
      return null;
    }
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
          maxWidth: 1440,
          maxHeight: 2560,
          imageQuality: 90,
        );
      }

      if (file != null) {
        setState(() {
          _selectedFile = File(file!.path);
          _mediaType = isVideo ? 'video' : 'image';
          _texts = [];
          _strokes = [];
          _currentStroke = [];
          _selectedFilterIndex = 0;
          _selectedMusic = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _undoDrawing() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
      });
    }
  }

  Future<void> _saveToGallery() async {
    if (_selectedFile == null) return;
    setState(() => _isUploading = true);
    try {
      final composite = await _captureCompositeImage();
      if (composite != null) {
        await Gal.putImage(composite.path);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Saved to gallery!')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _createStory() async {
    if (_selectedFile == null) return;
    setState(() => _isUploading = true);

    try {
      final finalFile = await _captureCompositeImage() ?? _selectedFile!;

      // Prepare interactive metadata for text layers
      final interactiveMetadata =
          _texts
              .map(
                (t) => {
                  'type': 'text',
                  'data': {
                    'text': t.text,
                    'color': '#${t.color.toARGB32().toRadixString(16)}',
                    'background_mode': t.backgroundMode,
                  },
                  'x': t.position.dx / MediaQuery.of(context).size.width,
                  'y': t.position.dy / MediaQuery.of(context).size.height,
                },
              )
              .toList();

      final story = await _storiesService.createStory(
        file: finalFile,
        mediaType: _mediaType,
        musicId: _selectedMusic?.trackId,
        musicMetadata: _selectedMusic?.toJson(),
        interactiveMetadata: interactiveMetadata,
      );

      if (story != null && mounted) {
        context.pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story shared!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _addNewText() {
    setState(() {
      _captionController.clear();
      _editingTextIndex = null;
      _isCaptionVisible = true;
      _textColor = Colors.white;
      _textBackgroundMode = 0;
      _selectedFontIndex = 0;
    });
  }

  void _finishTextEditing() {
    if (_captionController.text.trim().isEmpty) {
      if (_editingTextIndex != null) {
        setState(() => _texts.removeAt(_editingTextIndex!));
      }
      setState(() {
        _isCaptionVisible = false;
        _editingTextIndex = null;
      });
      return;
    }

    setState(() {
      final newText = StoryText(
        text: _captionController.text.trim(),
        position:
            _editingTextIndex != null
                ? _texts[_editingTextIndex!].position
                : Offset(
                  MediaQuery.of(context).size.width / 2,
                  MediaQuery.of(context).size.height / 2.5,
                ),
        color: _textColor,
        backgroundMode: _textBackgroundMode,
        fontIndex: _selectedFontIndex,
        align: _textAlign,
      );

      if (_editingTextIndex != null) {
        _texts[_editingTextIndex!] = newText;
      } else {
        _texts.add(newText);
      }

      _isCaptionVisible = false;
      _editingTextIndex = null;
    });
  }

  void _openMusicPicker() async {
    final StoryMusic? result = await showModalBottomSheet<StoryMusic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MusicPickerSheet(),
    );

    if (result != null) {
      setState(() {
        _selectedMusic = result;
      });
      HapticUtils.success();
    }
  }

  void _openStickerTray() {
    final isM3E =
        Provider.of<ThemeProvider>(context, listen: false).isM3EEnabled;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isM3E ? 48 : 20),
        ),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: 9,
              itemBuilder:
                  (context, index) => Container(
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(isM3E ? 24 : 15),
                    ),
                    child: const Icon(
                      Icons.emoji_emotions_outlined,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── Composite Area (Captured via RepaintBoundary) ──
          RepaintBoundary(
            key: _boundaryKey,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
              child: Stack(
                children: [
                  if (_selectedFile != null) ...[
                    Positioned.fill(
                      child: ColorFiltered(
                        colorFilter: ui.ColorFilter.matrix(
                          _filterPresets[_selectedFilterIndex]['matrix'],
                        ),
                        child: Image.file(_selectedFile!, fit: BoxFit.cover),
                      ),
                    ),

                    // Music Sticker (Rendered into composite)
                    if (_selectedMusic != null)
                      _buildMusicStickerWidget(_selectedMusic!),

                    Positioned.fill(
                      child: CustomPaint(
                        painter: DrawingPainter(
                          strokes: _strokes,
                          currentStroke: _currentStroke,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                    ..._texts.asMap().entries.map((entry) {
                      final i = entry.key;
                      final t = entry.value;
                      final isM3E =
                          Provider.of<ThemeProvider>(
                            context,
                            listen: false,
                          ).isM3EEnabled;
                      return Positioned(
                        left: t.position.dx - 100,
                        top: t.position.dy - 25,
                        child: GestureDetector(
                          onTap: () {
                            if (_isDraggingText) return;
                            setState(() {
                              _editingTextIndex = i;
                              _captionController.text = t.text;
                              _textColor = t.color;
                              _textBackgroundMode = t.backgroundMode;
                              _selectedFontIndex = t.fontIndex;
                              _isCaptionVisible = true;
                            });
                          },
                          onPanStart: (_) {
                            setState(() => _isDraggingText = true);
                            HapticFeedback.selectionClick();
                          },
                          onPanUpdate: (details) {
                            setState(() {
                              t.position += details.delta;
                              final screenWidth =
                                  MediaQuery.of(context).size.width;
                              final screenHeight =
                                  MediaQuery.of(context).size.height;
                              final trashPos = Offset(
                                screenWidth / 2,
                                screenHeight - 100,
                              );
                              final distance = (t.position - trashPos).distance;
                              if (distance < 120 && !_isTextOverTrash) {
                                _isTextOverTrash = true;
                                HapticFeedback.mediumImpact();
                              } else if (distance >= 120 && _isTextOverTrash) {
                                _isTextOverTrash = false;
                              }
                            });
                          },
                          onPanEnd: (_) {
                            if (_isTextOverTrash) {
                              setState(() {
                                _texts.removeAt(i);
                              });
                              HapticFeedback.heavyImpact();
                            }
                            setState(() {
                              _isDraggingText = false;
                              _isTextOverTrash = false;
                            });
                          },
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 100),
                            scale:
                                _isDraggingText && _isTextOverTrash ? 0.5 : 1.0,
                            child: Opacity(
                              opacity:
                                  _isDraggingText && _isTextOverTrash
                                      ? 0.5
                                      : 1.0,
                              child: Container(
                                width: 200,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      t.backgroundMode == 1
                                          ? t.color.withValues(alpha: 0.9)
                                          : (t.backgroundMode == 2
                                              ? Colors.black54
                                              : Colors.transparent),
                                  borderRadius: BorderRadius.circular(
                                    isM3E ? 16 : 8,
                                  ),
                                ),
                                child: Text(
                                  t.text,
                                  textAlign: t.align,
                                  style: TextStyle(
                                    color:
                                        t.backgroundMode == 1
                                            ? (t.color.computeLuminance() > 0.5
                                                ? Colors.black
                                                : Colors.white)
                                            : t.color,
                                    fontSize: 28,
                                    fontWeight:
                                        isM3E
                                            ? FontWeight.w900
                                            : FontWeight.bold,
                                    letterSpacing: isM3E ? -0.5 : 0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ] else
                    _buildEmptyState(),
                ],
              ),
            ),
          ),

          // ── Drawing INTERACTION Layer ──
          if (_selectedFile != null && _isDrawingMode)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) {
                  setState(() {
                    _currentStroke = [
                      DrawingPoint(
                        details.localPosition,
                        Paint()
                          ..color =
                              _isEraserMode
                                  ? Colors.transparent
                                  : _selectedColor
                          ..strokeWidth = _isEraserMode ? 30.0 : _strokeWidth
                          ..strokeCap = StrokeCap.round
                          ..blendMode =
                              _isEraserMode
                                  ? BlendMode.clear
                                  : BlendMode.srcOver
                          ..style = PaintingStyle.stroke
                          ..isAntiAlias = true,
                      ),
                    ];
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _currentStroke.add(
                      DrawingPoint(
                        details.localPosition,
                        Paint()
                          ..color =
                              _isEraserMode
                                  ? Colors.transparent
                                  : _selectedColor
                          ..strokeWidth = _isEraserMode ? 30.0 : _strokeWidth
                          ..strokeCap = StrokeCap.round
                          ..blendMode =
                              _isEraserMode
                                  ? BlendMode.clear
                                  : BlendMode.srcOver
                          ..style = PaintingStyle.stroke
                          ..isAntiAlias = true,
                      ),
                    );
                  });
                },
                onPanEnd: (details) {
                  setState(() {
                    _strokes.add(List.from(_currentStroke));
                    _currentStroke = [];
                  });
                },
              ),
            ),

          // ── UI Overlays ──
          if (_selectedFile != null) ...[
            _buildCinematicGradients(),
            if (_isDraggingText)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: 0.4,
                    duration: const Duration(milliseconds: 200),
                    child: Container(color: Colors.black),
                  ),
                ),
              ),
            if (!_isCaptionVisible &&
                !_isDrawingMode &&
                !_isFilterPickerVisible &&
                !_isDraggingText)
              _buildSideToolbar(),
            _buildTopToolbar(),
            if (_isFilterPickerVisible) _buildFilterPicker(),
            if (_isCaptionVisible) _buildTextEditor(),
            if (!_isCaptionVisible && !_isDrawingMode && !_isDraggingText)
              _buildBottomActionBar(),
            if (_isDrawingMode) _buildDrawingTools(),
            if (_isDraggingText) _buildTrashArea(),
          ],

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
    );
  }

  Widget _buildTrashArea() {
    final isM3E = Provider.of<ThemeProvider>(context).isM3EEnabled;
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: EdgeInsets.all(_isTextOverTrash ? 25 : 18),
                decoration: BoxDecoration(
                  color:
                      _isTextOverTrash
                          ? Colors.red.withValues(alpha: 0.9)
                          : Colors.black45,
                  shape: isM3E ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: isM3E ? BorderRadius.circular(24) : null,
                  border: Border.all(
                    color: _isTextOverTrash ? Colors.white : Colors.white38,
                    width: 2,
                  ),
                  boxShadow: [
                    if (_isTextOverTrash)
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                  ],
                ),
                child: Icon(
                  _isTextOverTrash
                      ? Icons.delete_forever_rounded
                      : Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: _isTextOverTrash ? 36 : 30,
                ),
              ),
              const SizedBox(height: 12),
              AnimatedOpacity(
                opacity: _isTextOverTrash ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: Text(
                  'Remove',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: isM3E ? FontWeight.w900 : FontWeight.bold,
                    letterSpacing: isM3E ? -0.5 : 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isM3E = themeProvider.isM3EEnabled;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isM3E
                  ? [colorScheme.surfaceContainerHighest, colorScheme.surface]
                  : [const Color(0xFF1A1A1A), const Color(0xFF000000)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ZoomIn(
            child: Icon(
              isM3E
                  ? Icons.auto_awesome_mosaic_rounded
                  : Icons.auto_awesome_mosaic_rounded,
              size: isM3E ? 100 : 80,
              color:
                  isM3E
                      ? colorScheme.primary.withValues(alpha: 0.3)
                      : Colors.white24,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Create Story',
            style: TextStyle(
              color: isM3E ? colorScheme.onSurface : Colors.white,
              fontSize: isM3E ? 36 : 32,
              fontWeight: isM3E ? FontWeight.w800 : FontWeight.w900,
              letterSpacing: isM3E ? -1.5 : null,
            ),
          ),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildModernPickerItem(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                color: isM3E ? colorScheme.primary : Colors.blue,
                onTap: () => _pickMedia(ImageSource.camera),
                isM3E: isM3E,
              ),
              const SizedBox(width: 40),
              _buildModernPickerItem(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                color: isM3E ? colorScheme.tertiary : Colors.pink,
                onTap: () => _pickMedia(ImageSource.gallery),
                isM3E: isM3E,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextEditor() {
    final isM3E = Provider.of<ThemeProvider>(context).isM3EEnabled;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.8),
        child: Column(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildBlurButton(
                      icon: Icons.align_horizontal_left_rounded,
                      onTap: () {},
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap:
                          () => setState(
                            () =>
                                _textBackgroundMode =
                                    (_textBackgroundMode + 1) % 3,
                          ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              _textBackgroundMode > 0
                                  ? Colors.white
                                  : Colors.white10,
                          borderRadius: BorderRadius.circular(isM3E ? 12 : 8),
                        ),
                        child: Icon(
                          Icons.format_color_text_rounded,
                          color:
                              _textBackgroundMode > 0
                                  ? Colors.black
                                  : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: _finishTextEditing,
                      child: Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: isM3E ? FontWeight.w900 : FontWeight.bold,
                          letterSpacing: isM3E ? -0.5 : 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: TextField(
                  controller: _captionController,
                  autofocus: true,
                  textAlign: _textAlign,
                  maxLines: null,
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 36,
                    fontWeight: isM3E ? FontWeight.w900 : FontWeight.bold,
                    letterSpacing: isM3E ? -1.0 : 0,
                    backgroundColor:
                        _textBackgroundMode == 1
                            ? Colors.white
                            : (_textBackgroundMode == 2
                                ? Colors.black54
                                : null),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Type...',
                    hintStyle: TextStyle(color: Colors.white24),
                  ),
                ),
              ),
            ),
            _buildColorPicker(),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    final isM3E = Provider.of<ThemeProvider>(context).isM3EEnabled;
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 40),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: Colors.primaries.length,
        itemBuilder:
            (context, index) => GestureDetector(
              onTap: () => setState(() => _textColor = Colors.primaries[index]),
              child: Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: Colors.primaries[index],
                  shape: isM3E ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: isM3E ? BorderRadius.circular(8) : null,
                  border: Border.all(
                    color:
                        _textColor == Colors.primaries[index]
                            ? Colors.white
                            : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildFilterPicker() {
    final isM3E = Provider.of<ThemeProvider>(context).isM3EEnabled;
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: FadeInUp(
        duration: const Duration(milliseconds: 300),
        child: Column(
          children: [
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filterPresets.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedFilterIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilterIndex = index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 15),
                      child: Column(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                isM3E ? 24 : 12,
                              ),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? Colors.white
                                        : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: ColorFiltered(
                              colorFilter: ui.ColorFilter.matrix(
                                _filterPresets[index]['matrix'],
                              ),
                              child: Image.file(
                                _selectedFile!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _filterPresets[index]['name'],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white60,
                              fontSize: 12,
                              fontWeight:
                                  isSelected
                                      ? (isM3E
                                          ? FontWeight.w900
                                          : FontWeight.bold)
                                      : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => setState(() => _isFilterPickerVisible = false),
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
      child: Column(
        children: [
          _buildSideTool(
            icon: Icons.text_fields_rounded,
            label: 'Aa',
            onTap: _addNewText,
          ),
          const SizedBox(height: 24),
          _buildSideTool(
            icon: Icons.sticky_note_2_rounded,
            label: 'Stickers',
            onTap: _openStickerTray,
          ),
          const SizedBox(height: 24),
          _buildSideTool(
            icon: Icons.gesture_rounded,
            label: 'Draw',
            onTap: () => setState(() => _isDrawingMode = true),
          ),
          const SizedBox(height: 24),
          _buildSideTool(
            icon: Icons.auto_awesome_rounded,
            label: 'Filters',
            onTap: () => setState(() => _isFilterPickerVisible = true),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildBlurButton(icon: Icons.download_rounded, onTap: _saveToGallery),
          const Spacer(),
          _buildCircleActionButton(
            icon:
                _isUploading
                    ? Icons.hourglass_empty
                    : Icons.chevron_right_rounded,
            onTap: _isUploading ? () {} : _createStory,
          ),
        ],
      ),
    );
  }

  Widget _buildTopToolbar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildBlurButton(
              icon: Icons.close_rounded,
              onTap: () {
                if (_isDrawingMode) {
                  setState(() => _isDrawingMode = false);
                } else if (_isFilterPickerVisible) {
                  setState(() => _isFilterPickerVisible = false);
                } else {
                  setState(() => _selectedFile = null);
                }
              },
            ),
            if (!_isCaptionVisible && !_isDrawingMode) ...[
              const Spacer(),
              _buildBlurButton(
                icon: Icons.music_note_rounded,
                onTap: _openMusicPicker,
              ),
              const SizedBox(width: 12),
              _buildBlurButton(
                icon: Icons.face_retouching_natural_rounded,
                onTap: () {},
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDrawingTools() {
    final isM3E =
        Provider.of<ThemeProvider>(context, listen: false).isM3EEnabled;
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBlurButton(icon: Icons.undo_rounded, onTap: _undoDrawing),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => setState(() => _isEraserMode = !_isEraserMode),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isEraserMode ? Colors.white : Colors.white10,
                      borderRadius: BorderRadius.circular(isM3E ? 12 : 20),
                    ),
                    child: Icon(
                      _isEraserMode
                          ? Icons.auto_fix_high_rounded
                          : Icons.auto_fix_off_rounded,
                      color: _isEraserMode ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildColorPickerForDrawing(),
          const SizedBox(height: 20),
          _buildCircleActionButton(
            icon: Icons.check_rounded,
            onTap: () => setState(() => _isDrawingMode = false),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPickerForDrawing() {
    final isM3E = Provider.of<ThemeProvider>(context).isM3EEnabled;
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: Colors.primaries.length,
        itemBuilder:
            (context, index) => GestureDetector(
              onTap:
                  () => setState(() {
                    _selectedColor = Colors.primaries[index];
                    _isEraserMode = false;
                  }),
              child: Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: Colors.primaries[index],
                  shape: isM3E ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: isM3E ? BorderRadius.circular(8) : null,
                  border: Border.all(
                    color:
                        _selectedColor == Colors.primaries[index] &&
                                !_isEraserMode
                            ? Colors.white
                            : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildCinematicGradients() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black54,
                Colors.transparent,
                Colors.transparent,
                Colors.black54,
              ],
              stops: [0.0, 0.15, 0.85, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernPickerItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isM3E = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: isM3E ? 90 : 80,
            height: isM3E ? 90 : 80,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: isM3E ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: isM3E ? BorderRadius.circular(28) : null,
              border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            ),
            child: Icon(icon, color: color, size: isM3E ? 36 : 32),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color:
                  isM3E
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.white,
              fontWeight: isM3E ? FontWeight.bold : FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isM3E = themeProvider.isM3EEnabled;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isM3E ? 16 : 20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(10),
            color: isM3E ? Colors.white.withValues(alpha: 0.2) : Colors.white10,
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildSideTool({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isM3E = Provider.of<ThemeProvider>(context).isM3EEnabled;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          _buildBlurButton(icon: icon, onTap: onTap),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: isM3E ? FontWeight.w900 : FontWeight.bold,
              letterSpacing: isM3E ? -0.2 : 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isM3E = themeProvider.isM3EEnabled;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: isM3E ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: isM3E ? BorderRadius.circular(24) : null,
          boxShadow:
              isM3E
                  ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: Icon(icon, color: Colors.black, size: 24),
      ),
    );
  }

  Widget _buildMusicStickerWidget(StoryMusic music) {
    final isM3E = Provider.of<ThemeProvider>(context).isM3EEnabled;
    return Center(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMusic = null),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isM3E ? 20 : 12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(isM3E ? 8 : 4),
                child: CachedNetworkImage(
                  imageUrl: music.albumArtUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    music.title,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: isM3E ? FontWeight.w900 : FontWeight.bold,
                    ),
                  ),
                  Text(
                    music.artist,
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              const Icon(Icons.music_note, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }
}

class StoryText {
  String text;
  Offset position;
  Color color;
  int backgroundMode;
  int fontIndex;
  TextAlign align;
  StoryText({
    required this.text,
    required this.position,
    this.color = Colors.white,
    this.backgroundMode = 0,
    this.fontIndex = 0,
    this.align = TextAlign.center,
  });
}

class DrawingPoint {
  Offset point;
  Paint areaPaint;
  DrawingPoint(this.point, this.areaPaint);
}

class DrawingPainter extends CustomPainter {
  final List<List<DrawingPoint>> strokes;
  final List<DrawingPoint> currentStroke;
  DrawingPainter({required this.strokes, required this.currentStroke});
  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    _drawStroke(canvas, currentStroke);
    canvas.restore();
  }

  void _drawStroke(ui.Canvas canvas, List<DrawingPoint> stroke) {
    if (stroke.isEmpty) return;
    if (stroke.length == 1) {
      canvas.drawCircle(
        stroke[0].point,
        stroke[0].areaPaint.strokeWidth / 2,
        stroke[0].areaPaint,
      );
      return;
    }
    final path = ui.Path();
    path.moveTo(stroke[0].point.dx, stroke[0].point.dy);
    for (int i = 1; i < stroke.length; i++) {
      path.lineTo(stroke[i].point.dx, stroke[i].point.dy);
    }
    canvas.drawPath(path, stroke[0].areaPaint);
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}
