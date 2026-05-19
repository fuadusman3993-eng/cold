import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:cold/core/providers/feed_provider.dart';
import 'package:cold/core/utils/video_player_helper.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

enum PostStep { select, preview }

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _videoFile;
  VideoPlayerController? _videoController;
  final TextEditingController _descController = TextEditingController();
  
  bool _isUploading = false;
  bool _isPlaying = true;
  bool _isProcessingMedia = false; // Transition Lock to prevent duplicate launches
  PostStep _currentStep = PostStep.select; // Cleared lifecycle steps

  // Camera package variables
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isRecording = false;

  // Camera permissions state (Ask Only Once)
  static bool _permissionsRequested = false;
  static bool _hasCameraPermission = false;

  // Camera zoom variables
  double _currentZoomLevel = 1.0;
  double _baseZoomLevel = 1.0;
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;

  // Recording progress animation variables
  double _progressValue = 0.0;
  Timer? _progressTimer;

  // Camera Grid Line Toggle
  bool _showGrid = true;

  // Transition overlay opacity
  double _transitionOverlayOpacity = 0.0;

  // Optional gallery thumbnail path
  String? _galleryThumbnailPath;

  // Camera creation UI state variables
  bool _isFlashOn = false;
  String _selectedSpeed = '1x'; // '0.5x', '1x', '2x', '3x'
  bool _isTimerActive = false;
  int _selectedDuration = 15; // 15, 30, 60
  bool _isFrontCamera = false;
  String _selectedMode = 'REEL'; // 'REEL', 'TEMPLATES'
  bool _isRecordingSimulated = false;

  static const Color _electricBlue = Color(0xFF0088FF);

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    try {
      final cameraStatus = await Permission.camera.status;
      final microphoneStatus = await Permission.microphone.status;

      if (cameraStatus.isGranted && microphoneStatus.isGranted) {
        _hasCameraPermission = true;
        _initializeCamera();
        return;
      }

      if (_permissionsRequested) {
        debugPrint("Permissions previously requested. Skipping prompt.");
        return;
      }

      _permissionsRequested = true;

      final statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      if (statuses[Permission.camera]?.isGranted == true &&
          statuses[Permission.microphone]?.isGranted == true) {
        _hasCameraPermission = true;
        _initializeCamera();
      } else {
        _hasCameraPermission = false;
        debugPrint("Permissions denied by user.");
      }
    } catch (e) {
      debugPrint("Error handling permissions: $e");
      // Gracefully fall back
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (!_hasCameraPermission) {
      debugPrint("Skipping camera initialization: Permission not granted.");
      return;
    }

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
    _progressTimer?.cancel();
    _cameraController?.dispose();
    _videoController?.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo(ImageSource source) async {
    // 1. Loading/Transition Lock: Return early if media is already processing
    if (_isProcessingMedia) return;
    
    setState(() {
      _isProcessingMedia = true;
    });

    try {
      XFile? file;
      if (source == ImageSource.gallery) {
        // Use pickMedia to invoke Android/iOS native visual gallery/photo picker instead of file explorer
        file = await _picker.pickMedia();
        if (file != null) {
          final isVideo = file.path.toLowerCase().contains('.mp4') ||
              file.path.toLowerCase().contains('.mov') ||
              file.path.toLowerCase().contains('.avi') ||
              file.path.toLowerCase().contains('.mkv') ||
              file.path.toLowerCase().contains('.webm') ||
              (file.mimeType != null && file.mimeType!.startsWith('video/'));
          if (!isVideo) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.redAccent,
                  content: Text(
                    'Please select a video file.',
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              );
            }
            file = null;
          }
        }
      } else {
        file = await _picker.pickVideo(
          source: source,
          maxDuration: const Duration(minutes: 5),
        );
      }

      if (file != null) {
        // Trigger smooth fade-out animation first
        setState(() {
          _transitionOverlayOpacity = 1.0;
        });
        
        await Future.delayed(const Duration(milliseconds: 250));

        setState(() {
          _videoFile = file;
          _galleryThumbnailPath = file.path;
          _isPlaying = true;
          _currentStep = PostStep.preview; // Set step to preview UI
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
          _transitionOverlayOpacity = 0.0; // Smoothly fade back in
        });
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _pickVideo(ImageSource.camera);
      return;
    }

    if (_isRecording) {
      _progressTimer?.cancel();
      _progressTimer = null;
      
      // Trigger smooth fade-out animation first
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
          _currentStep = PostStep.preview;
        });
        await _cameraController?.dispose();
        _cameraController = null;
        await _initializeVideoPlayer();
      } catch (e) {
        debugPrint('Error stopping video recording: $e');
        setState(() {
          _isRecording = false;
          _progressValue = 0.0;
          _currentStep = PostStep.select;
        });
      } finally {
        if (mounted) {
          setState(() {
            _transitionOverlayOpacity = 0.0; // Smoothly fade back in
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
    if (_videoFile == null || _isUploading) return;

    setState(() {
      _isUploading = true;
    });

    // Asynchronous upload task simulated pipeline
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      final feedProvider = Provider.of<FeedProvider>(context, listen: false);
      
      final newVideo = VideoModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _descController.text.trim().isEmpty 
            ? 'New premium dynamic post description!' 
            : _descController.text.trim(),
        username: 'you',
        url: _videoFile!.path,
        likesCount: 0,
        commentsCount: 0,
        colors: const [Color(0xFFFF416C), Color(0xFFFF4B2B)],
      );

      feedProvider.addVideoToForYou(newVideo);
      feedProvider.addVideoToFollowing(newVideo);

      setState(() {
        _isUploading = false;
      });

      // 3. Reset State & Dispose on Pop: Clear out active players to avoid ghost leak threads
      _videoController?.dispose();
      _videoController = null;
      _videoFile = null;

      Navigator.pop(context); 
    }
  }

  void _clearSelection() {
    _progressTimer?.cancel();
    _progressTimer = null;
    setState(() {
      _progressValue = 0.0;
      _videoController?.dispose();
      _videoController = null;
      _videoFile = null;
      _currentStep = PostStep.select;
      _descController.clear();
    });
    _initializeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _currentStep == PostStep.select 
              ? _buildSelectionView() 
              : SafeArea(child: _buildPreviewView()),
          
          // Cinematic smooth transition fade-out overlay
          IgnorePointer(
            ignoring: _transitionOverlayOpacity == 0.0,
            child: AnimatedOpacity(
              opacity: _transitionOverlayOpacity,
              duration: const Duration(milliseconds: 250),
              child: Container(
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Premium immersive Reels-style camera selection view
  Widget _buildSelectionView() {
    return Stack(
      children: [
        // 1. Simulated Camera Viewfinder Layer
        Positioned.fill(
          child: Container(
            color: const Color(0xFF000000), // Pure black base
            child: Stack(
              children: [
                if (_cameraController != null && _cameraController!.value.isInitialized)
                  Positioned.fill(
                    child: GestureDetector(
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
                  )
                else
                  // Premium HSL gradient overlay mimicking a dark live viewfinder
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
                // Camera Grid Lines (Rule of Thirds)
                if (_showGrid)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CameraGridPainter(),
                    ),
                  ),
                // Camera Corner Framing Brackets
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CameraCornerBracketsPainter(),
                  ),
                ),
                // Pulsing REC indicator + mode status at top center
                Positioned(
                  top: 54, // Adjusted below status bar
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
                // Zoom Slider
                if (_cameraController != null && _cameraController!.value.isInitialized && _maxZoomLevel > _minZoomLevel)
                  Positioned(
                    bottom: 120,
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
                // Tech Specs Metadata (ISO, FPS)
                Positioned(
                  bottom: 180,
                  left: 24,
                  child: Text(
                    'ISO 250   1080P   60FPS',
                    style: GoogleFonts.inter(
                      color: Colors.white30,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Top Control Bar (Left close 'X', Right horizontal tools row)
        Positioned(
          top: 48, // Balanced with the REC indicator
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Close Action
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
              // Right: Horizontal sleek thin-stroke tools row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Flash Toggle
                    _buildTopToolItem(
                      icon: _isFlashOn ? LucideIcons.zap : LucideIcons.zapOff,
                      color: _isFlashOn ? const Color(0xFFFFCC00) : Colors.white,
                      onTap: _toggleFlash,
                    ),
                    const SizedBox(width: 16),
                    // Speed multiplier
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
                    // Timer
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
                    // Settings Gear
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

        // 3. Left Aligned Vertical Tool Column
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
              // Duration Dotted Selector
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_selectedDuration == 15) _selectedDuration = 30;
                    else if (_selectedDuration == 30) _selectedDuration = 60;
                    else _selectedDuration = 15;
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white70,
                          width: 1.5,
                        ),
                        color: Colors.black45,
                      ),
                      child: Center(
                        child: Text(
                          _selectedDuration.toString(),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Length',
                      style: GoogleFonts.inter(
                        color: Colors.white60,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 4. Bottom Control Dock
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
                // Shutter, Picker, and Flip Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Gallery Picker (Left of Shutter)
                      GestureDetector(
                        onTap: () => _pickVideo(ImageSource.gallery),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
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
                      // Pristine White Shutter Recording Button (Center)
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
                          GestureDetector(
                            onTap: _toggleRecording,
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
                      // Camera Flip Toggle (Right of Shutter)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isFrontCamera = !_isFrontCamera;
                          });
                          _initializeCamera();
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black38,
                          ),
                          child: const Center(
                            child: Icon(LucideIcons.switchCamera, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Mode Horizontal Slider properly padded
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildModeText('REEL'),
                    const SizedBox(width: 32),
                    _buildModeText('TEMPLATES'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopToolItem({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color, size: 18),
    );
  }

  Widget _buildLeftColumnToolItem({required IconData icon, required String label, required VoidCallback onTap, Color color = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black45,
            ),
            child: Center(
              child: Icon(icon, color: color, size: 16),
            ),
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
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _buildModeText(String mode) {
    final bool isActive = _selectedMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      child: Text(
        mode,
        style: GoogleFonts.inter(
          color: isActive ? Colors.white : Colors.white38,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  // Previews selected video & shows Post controls
  Widget _buildPreviewView() {
    final bool isInitialized = _videoController != null && _videoController!.value.isInitialized;

    return Column(
      children: [
        // Custom top navigation bar
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
              const SizedBox(width: 48), // Spacer to balance cancel button
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Video Preview Player Layer
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    height: 360,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isInitialized)
                          Positioned.fill(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _videoController!.value.size.width,
                                height: _videoController!.value.size.height,
                                child: VideoPlayer(_videoController!),
                              ),
                            ),
                          )
                        else
                          const Center(
                            child: CircularProgressIndicator(
                              color: _electricBlue,
                            ),
                          ),

                        // Animated Play/Pause overlay
                        if (!_isPlaying)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.5),
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Description input field
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: TextField(
                    controller: _descController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    cursorColor: _electricBlue,
                    decoration: InputDecoration(
                      hintText: 'Write a description, add #tags...',
                      hintStyle: GoogleFonts.inter(
                        color: Colors.white30,
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Prominent high-contrast Post button
                ElevatedButton(
                  onPressed: _isUploading ? null : _handlePost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF111111),
                    foregroundColor: Colors.black,
                    disabledForegroundColor: Colors.white24,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          'Post',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ==================== Premium Viewfinder Custom Widgets & Painters ====================

class _RecordingStatusDot extends StatefulWidget {
  @override
  State<_RecordingStatusDot> createState() => _RecordingStatusDotState();
}

class _RecordingStatusDotState extends State<_RecordingStatusDot> with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFFF2D55), // Pulsing red dot
        ),
      ),
    );
  }
}

class _CameraGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1.0;

    // Draw vertical lines
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), paint);

    // Draw horizontal lines
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, size.height * 2 / 3), Offset(size.width, size.height * 2 / 3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CameraCornerBracketsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const length = 20.0;
    const margin = 24.0;

    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(margin, margin + length + 20.0) // Pushed slightly down for aesthetics
        ..lineTo(margin, margin + 20.0)
        ..lineTo(margin + length, margin + 20.0),
      paint,
    );

    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - margin - length, margin + 20.0)
        ..lineTo(size.width - margin, margin + 20.0)
        ..lineTo(size.width - margin, margin + length + 20.0),
      paint,
    );

    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(margin, size.height - margin - length - 60.0) // Kept above bottom controls
        ..lineTo(margin, size.height - margin - 60.0)
        ..lineTo(margin + length, size.height - margin - 60.0),
      paint,
    );

    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - margin - length, size.height - margin - 60.0)
        ..lineTo(size.width - margin, size.height - margin - 60.0)
        ..lineTo(size.width - margin, size.height - margin - length - 60.0),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
