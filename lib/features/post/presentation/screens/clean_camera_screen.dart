import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:cold/core/providers/feed_provider.dart';
import 'package:cold/core/utils/video_player_helper.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

enum CameraStep { select, preview }

class CleanCameraScreen extends StatefulWidget {
  const CleanCameraScreen({super.key});

  @override
  State<CleanCameraScreen> createState() => _CleanCameraScreenState();
}

class _CleanCameraScreenState extends State<CleanCameraScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _videoFile;
  VideoPlayerController? _videoController;
  final TextEditingController _descController = TextEditingController();
  
  bool _isUploading = false;
  bool _isPlaying = true;
  bool _isRecording = false;
  CameraStep _currentStep = CameraStep.select;

  // Camera Controller properties
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  bool _isProcessingMedia = false;

  // Zoom levels
  double _currentZoomLevel = 1.0;
  double _baseZoomLevel = 1.0;
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;

  // Recording progress animation variables
  double _progressValue = 0.0;
  Timer? _progressTimer;

  // Grid toggle
  bool _showGrid = true;

  // Transition overlay opacity
  double _transitionOverlayOpacity = 0.0;

  // Gallery thumbnail path
  String? _galleryThumbnailPath;

  // Camera creation UI variables
  bool _isFlashOn = false;
  String _selectedSpeed = '1x'; // '0.5x', '1x', '2x', '3x'
  bool _isTimerActive = false;
  int _selectedDuration = 15; // 15, 60, 120
  bool _isFrontCamera = false;
  String _selectedMode = '15s'; // '2m', '60s', '15s', 'photo', 'Text'
  
  late final PageController _modePageController;
  final List<String> _creationModes = ['2m', '60s', '15s', 'photo', 'Text'];
  final TextEditingController _creationTextController = TextEditingController();
  int _activeGradientIndex = 0;

  final List<List<Color>> _textGradients = [
    [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
    [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
    [const Color(0xFF11998E), const Color(0xFF38EF7D)],
    [const Color(0xFF00c6ff), const Color(0xFF0072ff)],
    [const Color(0xFFf12711), const Color(0xFFf5af19)],
  ];

  static const Color _electricBlue = Color(0xFF0088FF);

  @override
  void initState() {
    super.initState();
    // Initialize PageController with default mode '15s' (index 2)
    int initialIndex = _creationModes.indexOf(_selectedMode);
    if (initialIndex == -1) initialIndex = 2;
    _modePageController = PageController(
      initialPage: initialIndex,
      viewportFraction: 0.12,
    );
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        if (_cameraController != null) {
          await _cameraController!.dispose();
          _cameraController = null;
        }

        final selectedCamera = _cameras.firstWhere(
          (camera) => _isFrontCamera 
              ? camera.lensDirection == CameraLensDirection.front 
              : camera.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras.first,
        );

        _cameraController = CameraController(
          selectedCamera,
          ResolutionPreset.high,
          enableAudio: true,
        );

        await _cameraController!.initialize();

        // Get available zoom levels
        try {
          _minZoomLevel = await _cameraController!.getMinZoomLevel();
          _maxZoomLevel = await _cameraController!.getMaxZoomLevel();
          _currentZoomLevel = _minZoomLevel;
        } catch (zoomError) {
          debugPrint("Failed to get zoom levels: $zoomError");
          _minZoomLevel = 1.0;
          _maxZoomLevel = 1.0;
          _currentZoomLevel = 1.0;
        }

        await _updateCameraMode();

        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _modePageController.dispose();
    _progressTimer?.cancel();
    _cameraController?.dispose();
    _videoController?.dispose();
    _descController.dispose();
    _creationTextController.dispose();
    super.dispose();
  }

  void _onModeChanged(String mode) {
    if (_selectedMode == mode) return;
    setState(() {
      _selectedMode = mode;
      if (mode == '15s') {
        _selectedDuration = 15;
      } else if (mode == '60s') {
        _selectedDuration = 60;
      } else if (mode == '2m') {
        _selectedDuration = 120;
      }
    });
    _updateCameraMode();
  }

  Future<void> _updateCameraMode() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    final bool isVideoMode = _selectedMode == '15s' || _selectedMode == '60s' || _selectedMode == '2m';
    if (isVideoMode) {
      try {
        await _cameraController!.prepareForVideoRecording();
        debugPrint('Camera state updated: prepared for Video capture mode.');
      } catch (e) {
        debugPrint('Failed to prepare for video recording: $e');
      }
    } else if (_selectedMode == 'photo') {
      debugPrint('Camera state updated: switched to Photo capture mode.');
    }
  }

  Widget _applyFilter(Widget child) {
    return child; // Minimalist clean camera feed
  }

  void _cycleGradient() {
    setState(() {
      _activeGradientIndex = (_activeGradientIndex + 1) % _textGradients.length;
    });
  }

  void _proceedTextToPreview() {
    if (_creationTextController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please write something first.',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() {
      _currentStep = CameraStep.preview;
    });
  }

  Future<void> _pickVideo(ImageSource source) async {
    if (_isProcessingMedia) return;
    
    setState(() {
      _isProcessingMedia = true;
    });

    try {
      XFile? file;
      if (source == ImageSource.gallery) {
        file = await _picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(minutes: 5),
        );
      } else {
        file = await _picker.pickVideo(
          source: source,
          maxDuration: const Duration(minutes: 5),
        );
      }

      if (file != null) {
        final pickedFile = file;
        setState(() {
          _transitionOverlayOpacity = 1.0;
        });
        
        await Future.delayed(const Duration(milliseconds: 250));

        setState(() {
          _videoFile = pickedFile;
          _galleryThumbnailPath = pickedFile.path;
          _isPlaying = true;
          _currentStep = CameraStep.preview;
        });

        if (_cameraController != null) {
          await _cameraController!.dispose();
          _cameraController = null;
        }

        await _initializeVideoPlayer();
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingMedia = false;
          _transitionOverlayOpacity = 0.0;
        });
      }
    }
  }

  Future<void> _takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      setState(() {
        _transitionOverlayOpacity = 1.0;
      });
      await Future.delayed(const Duration(milliseconds: 250));
      
      final XFile photo = await _cameraController!.takePicture();
      setState(() {
        _videoFile = photo;
        _galleryThumbnailPath = photo.path;
        _currentStep = CameraStep.preview;
      });
      if (_cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    } finally {
      if (mounted) {
        setState(() {
          _transitionOverlayOpacity = 0.0;
        });
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (_selectedMode == 'Text') {
      _proceedTextToPreview();
      return;
    }
    
    if (_selectedMode == 'photo') {
      await _takePhoto();
      return;
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _pickVideo(ImageSource.camera);
      return;
    }

    if (_isRecording) {
      _progressTimer?.cancel();
      _progressTimer = null;
      
      setState(() {
        _transitionOverlayOpacity = 1.0;
      });
      
      await Future.delayed(const Duration(milliseconds: 250));

      try {
        final XFile file = await _cameraController!.stopVideoRecording();
        setState(() {
          _isRecording = false;
          _progressValue = 0.0;
          _videoFile = file;
          _galleryThumbnailPath = file.path;
          _isPlaying = true;
          _currentStep = CameraStep.preview;
        });
        await _cameraController?.dispose();
        _cameraController = null;
        await _initializeVideoPlayer();
      } catch (e) {
        debugPrint('Error stopping video recording: $e');
        setState(() {
          _isRecording = false;
          _progressValue = 0.0;
          _currentStep = CameraStep.select;
        });
      } finally {
        if (mounted) {
          setState(() {
            _transitionOverlayOpacity = 0.0;
          });
        }
      }
    } else {
      try {
        await _cameraController!.startVideoRecording();
        setState(() {
          _isRecording = true;
          _progressValue = 0.0;
        });

        final maxDurationMs = _selectedDuration * 1000;
        int elapsedMs = 0;
        _progressTimer?.cancel();
        _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
          elapsedMs += 50;
          if (mounted) {
            setState(() {
              _progressValue = elapsedMs / maxDurationMs;
            });
          }
          if (elapsedMs >= maxDurationMs) {
            timer.cancel();
            if (_isRecording) {
              _toggleRecording();
            }
          }
        });
      } catch (e) {
        debugPrint('Error starting video recording: $e');
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
      return;
    }

    try {
      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
        setState(() {
          _isFlashOn = false;
        });
      } else {
        await _cameraController!.setFlashMode(FlashMode.torch);
        setState(() {
          _isFlashOn = true;
        });
      }
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  Future<void> _initializeVideoPlayer() async {
    if (_videoFile == null) return;

    final path = _videoFile!.path.toLowerCase();
    final isPhoto = path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.heic') ||
        path.endsWith('.webp');
    if (isPhoto) return;

    if (_videoController != null) {
      await _videoController!.dispose();
      _videoController = null;
    }

    _videoController = createVideoPlayerController(_videoFile!.path);

    try {
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      await _videoController!.play();
      setState(() {});
    } catch (e) {
      debugPrint('Error initializing video controller: $e');
    }
  }

  void _togglePlayPause() {
    if (_videoController == null || !_videoController!.value.isInitialized) return;

    setState(() {
      if (_isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
      } else {
        _videoController!.play();
        _isPlaying = true;
      }
    });
  }

  Future<void> _handlePost() async {
    final bool isTextMode = _selectedMode == 'Text';
    if (!isTextMode && _videoFile == null) return;
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(color: Color(0xFF38EF7D), strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(
                'Islamic AI Engine: Scanning content...',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0D1F1D),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.shieldCheck, color: Color(0xFF38EF7D), size: 18),
              const SizedBox(width: 12),
              Text(
                'Passed community standards & Halal guidelines!',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0D1F1D),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      final feedProvider = Provider.of<FeedProvider>(context, listen: false);
      
      final String postTitle = isTextMode
          ? (_creationTextController.text.trim().isEmpty 
              ? 'Inspiring post from Creator!' 
              : _creationTextController.text.trim())
          : (_descController.text.trim().isEmpty
              ? 'New premium post!'
              : _descController.text.trim());

      final newVideo = VideoModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: postTitle,
        username: 'you',
        url: isTextMode ? '' : _videoFile!.path,
        likesCount: 0,
        commentsCount: 0,
        colors: isTextMode 
            ? _textGradients[_activeGradientIndex]
            : const [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
      );

      feedProvider.addVideoToForYou(newVideo);
      feedProvider.addVideoToFollowing(newVideo);

      setState(() {
        _isUploading = false;
        _creationTextController.clear();
      });

      _videoController?.dispose();
      _videoController = null;
      _videoFile = null;

      Navigator.pop(context);
    }
  }

  void _clearSelection() {
    _videoController?.dispose();
    _videoController = null;
    setState(() {
      _videoFile = null;
      _currentStep = CameraStep.select;
    });
    _initializeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Pure Black Theme Layer
      body: Stack(
        children: [
          _currentStep == CameraStep.select ? _buildCameraSelectorView() : _buildPreviewView(),
          
          // Cinematic smooth transition fade-out overlay
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _transitionOverlayOpacity,
              duration: const Duration(milliseconds: 250),
              child: Container(
                color: const Color(0xFF000000),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraSelectorView() {
    final bool isTextMode = _selectedMode == 'Text';

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: const Color(0xFF000000),
            child: Stack(
              children: [
                if (isTextMode)
                  Positioned.fill(
                    child: _buildTextCreationCanvas(),
                  )
                else if (_cameraController != null && _cameraController!.value.isInitialized)
                  Positioned.fill(
                    child: _applyFilter(
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onScaleStart: (details) {
                          _baseZoomLevel = _currentZoomLevel;
                        },
                        onScaleUpdate: (details) async {
                          if (_cameraController == null || !_cameraController!.value.isInitialized) return;
                          double newZoom = _baseZoomLevel * details.scale;
                          newZoom = newZoom.clamp(_minZoomLevel, _maxZoomLevel);
                          if (newZoom != _currentZoomLevel) {
                            _currentZoomLevel = newZoom;
                            await _cameraController!.setZoomLevel(newZoom);
                            setState(() {});
                          }
                        },
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final size = constraints.biggest;
                            var scale = size.aspectRatio * _cameraController!.value.aspectRatio;
                            if (scale < 1) scale = 1 / scale;
                            return Transform.scale(
                              scale: scale,
                              child: Center(
                                child: CameraPreview(_cameraController!),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  )
                else
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF151820).withOpacity(0.4),
                            const Color(0xFF08090C),
                          ],
                          radius: 1.2,
                          center: Alignment.center,
                        ),
                      ),
                    ),
                  ),

                if (_showGrid && !isTextMode)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CameraGridPainter(),
                    ),
                  ),
                if (!isTextMode)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CameraCornerBracketsPainter(),
                    ),
                  ),

                Positioned(
                  top: 54,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isRecording) ...[
                            _RecordingStatusDot(),
                            const SizedBox(width: 8),
                            Text(
                              'REC',
                              style: GoogleFonts.inter(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('|', style: TextStyle(color: Colors.white24)),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            _selectedMode,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (_cameraController != null && _cameraController!.value.isInitialized && _maxZoomLevel > _minZoomLevel && !isTextMode)
                  Positioned(
                    bottom: 154,
                    left: 48,
                    right: 48,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_minZoomLevel.toStringAsFixed(1)}x',
                              style: GoogleFonts.inter(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Text(
                                '${_currentZoomLevel.toStringAsFixed(1)}x',
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                              ),
                            ),
                            Text(
                              '${_maxZoomLevel.toStringAsFixed(1)}x',
                              style: GoogleFonts.inter(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: Colors.white,
                            trackHeight: 2.0,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                          ),
                          child: Slider(
                            value: _currentZoomLevel,
                            min: _minZoomLevel,
                            max: _maxZoomLevel,
                            onChanged: (value) async {
                              setState(() {
                                _currentZoomLevel = value;
                              });
                              try {
                                await _cameraController!.setZoomLevel(value);
                              } catch (e) {
                                debugPrint("Error setting zoom level: $e");
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        Positioned(
          top: 48,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black38,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                ),
              ),
              if (!isTextMode)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTopToolItem(
                        icon: _isFlashOn ? LucideIcons.zap : LucideIcons.zapOff,
                        color: _isFlashOn ? const Color(0xFFFFCC00) : Colors.white,
                        onTap: _toggleFlash,
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_selectedSpeed == '1x') _selectedSpeed = '2x';
                            else if (_selectedSpeed == '2x') _selectedSpeed = '3x';
                            else if (_selectedSpeed == '3x') _selectedSpeed = '0.5x';
                            else _selectedSpeed = '1x';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white60, width: 1.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _selectedSpeed,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildTopToolItem(
                        icon: LucideIcons.timer,
                        color: _isTimerActive ? const Color(0xFF0088FF) : Colors.white,
                        onTap: () {
                          setState(() {
                            _isTimerActive = !_isTimerActive;
                          });
                        },
                      ),
                      const SizedBox(width: 16),
                      _buildTopToolItem(
                        icon: LucideIcons.settings,
                        color: Colors.white,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        if (!isTextMode)
          Positioned(
            left: 16,
            top: 110,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildLeftColumnToolItem(
                  icon: LucideIcons.music,
                  label: 'Audio',
                  onTap: () {},
                ),
                _buildLeftColumnToolItem(
                  icon: LucideIcons.sparkles,
                  label: 'Effects',
                  onTap: () {},
                ),
                _buildLeftColumnToolItem(
                  icon: LucideIcons.smile,
                  label: 'Screen',
                  onTap: () {},
                ),
                _buildLeftColumnToolItem(
                  icon: LucideIcons.wand,
                  label: 'Retouch',
                  onTap: () {},
                ),
                _buildLeftColumnToolItem(
                  icon: LucideIcons.grid,
                  label: 'Grid',
                  color: _showGrid ? const Color(0xFF0088FF) : Colors.white,
                  onTap: () {
                    setState(() {
                      _showGrid = !_showGrid;
                    });
                  },
                ),
              ],
            ),
          ),

        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.only(bottom: 34, top: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black87,
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 40,
                  child: PageView.builder(
                    controller: _modePageController,
                    itemCount: _creationModes.length,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                      _onModeChanged(_creationModes[index]);
                    },
                    itemBuilder: (context, index) {
                      final mode = _creationModes[index];
                      final bool isActive = _selectedMode == mode;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _modePageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 50),
                            curve: Curves.linear,
                          );
                        },
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 50),
                            style: GoogleFonts.inter(
                              color: isActive ? Colors.white : Colors.white38,
                              fontWeight: FontWeight.w800,
                              fontSize: isActive ? 13 : 11,
                              letterSpacing: 1.0,
                            ),
                            child: Text(mode),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => _pickVideo(ImageSource.gallery),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white38, width: 1.5),
                            color: Colors.white.withOpacity(0.05),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _galleryThumbnailPath != null
                              ? Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFF8E2DE2),
                                              Color(0xFF4A00E0),
                                            ],
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.play_circle_outline, color: Colors.white, size: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : const Center(
                                  child: Icon(LucideIcons.image, color: Colors.white70, size: 18),
                                ),
                        ),
                      ),

                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_isRecording)
                            SizedBox(
                              width: 88,
                              height: 88,
                              child: CircularProgressIndicator(
                                value: _progressValue,
                                strokeWidth: 4,
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF2D55)),
                                backgroundColor: Colors.white24,
                              ),
                            ),
                          InkWell(
                            onTap: _toggleRecording,
                            borderRadius: BorderRadius.circular(38),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                              ),
                              padding: EdgeInsets.all(_isRecording ? 18 : 4),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                decoration: BoxDecoration(
                                  shape: _isRecording ? BoxShape.rectangle : BoxShape.circle,
                                  color: _isRecording ? const Color(0xFFFF2D55) : Colors.white,
                                  borderRadius: _isRecording ? BorderRadius.circular(6) : null,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      GestureDetector(
                        onTap: () {
                          if (isTextMode) {
                            _cycleGradient();
                          } else {
                            _initializeCamera(); // Swap cameras
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12, width: 1.2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isTextMode ? LucideIcons.palette : LucideIcons.refreshCw,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isTextMode ? 'GRADIENT' : 'FLIP',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextCreationCanvas() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _textGradients[_activeGradientIndex],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: TextField(
            controller: _creationTextController,
            maxLines: null,
            autofocus: true,
            textAlign: TextAlign.center,
            cursorColor: Colors.white,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.3,
              shadows: [
                const Shadow(color: Colors.black45, blurRadius: 8),
              ],
            ),
            decoration: InputDecoration(
              hintText: 'Share an inspiring thought...',
              hintStyle: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewView() {
    final bool isTextMode = _selectedMode == 'Text';
    final String? path = _videoFile?.path.toLowerCase();
    final bool isPhoto = path != null && (
      path.endsWith('.jpg') ||
      path.endsWith('.jpeg') ||
      path.endsWith('.png') ||
      path.endsWith('.heic') ||
      path.endsWith('.webp')
    );
    final bool isInitialized = _videoController != null && _videoController!.value.isInitialized;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _isUploading ? null : _clearSelection,
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'Preview Post',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: isPhoto ? null : _togglePlayPause,
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0F13),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isTextMode)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: _textGradients[_activeGradientIndex],
                                  ),
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Text(
                                      _creationTextController.text,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        shadows: [const Shadow(color: Colors.black38, blurRadius: 6)],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else if (isPhoto)
                            Positioned.fill(
                              child: Image.file(
                                File(_videoFile!.path),
                                fit: BoxFit.cover,
                              ),
                            )
                          else if (isInitialized)
                            Positioned.fill(
                              child: VideoPlayer(_videoController!),
                            )
                          else
                            const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          
                          if (!isPhoto && !isTextMode && isInitialized && !_isPlaying)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Colors.black38,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1F1D),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1B3D39), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.shieldCheck, color: Color(0xFF38EF7D), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Islamic AI Moderation Engine Active',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'This content will be scanned for Halal and community guidelines.',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _descController,
                  maxLines: 3,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Write a caption...',
                    hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFF15151A),
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isUploading ? null : _handlePost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white24,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                        )
                      : Text(
                          'Post to Feed',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopToolItem({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildLeftColumnToolItem({
    required IconData icon,
    required String label,
    Color color = Colors.white,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black38,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordingStatusDot extends StatefulWidget {
  @override
  _RecordingStatusDotState createState() => _RecordingStatusDotState();
}

class _RecordingStatusDotState extends State<_RecordingStatusDot> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animController,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _CameraGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.0;

    final double thirdWidth = size.width / 3;
    final double thirdHeight = size.height / 3;

    canvas.drawLine(Offset(thirdWidth, 0), Offset(thirdWidth, size.height), paint);
    canvas.drawLine(Offset(thirdWidth * 2, 0), Offset(thirdWidth * 2, size.height), paint);

    canvas.drawLine(Offset(0, thirdHeight), Offset(size.width, thirdHeight), paint);
    canvas.drawLine(Offset(0, thirdHeight * 2), Offset(size.width, thirdHeight * 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CameraCornerBracketsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white30
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const double margin = 40.0;
    const double len = 15.0;

    canvas.drawPath(
      Path()
        ..moveTo(margin, margin + len)
        ..lineTo(margin, margin)
        ..lineTo(margin + len, margin),
      paint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(size.width - margin - len, margin)
        ..lineTo(size.width - margin, margin)
        ..lineTo(size.width - margin, margin + len),
      paint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(margin, size.height - margin - len)
        ..lineTo(margin, size.height - margin)
        ..lineTo(margin + len, size.height - margin),
      paint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(size.width - margin - len, size.height - margin)
        ..lineTo(size.width - margin, size.height - margin)
        ..lineTo(size.width - margin, size.height - margin - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
