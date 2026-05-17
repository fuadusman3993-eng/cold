import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:cold/core/providers/feed_provider.dart';

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

  static const Color _electricBlue = Color(0xFF0088FF);

  @override
  void dispose() {
    _videoController?.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );
      if (file != null) {
        setState(() {
          _videoFile = file;
          _isPlaying = true;
        });
        await _initializeVideoPlayer();
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
    }
  }

  Future<void> _initializeVideoPlayer() async {
    if (_videoController != null) {
      await _videoController!.dispose();
      _videoController = null;
    }

    if (kIsWeb) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(_videoFile!.path));
    } else {
      _videoController = VideoPlayerController.file(File(_videoFile!.path));
    }

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
        videoPath: _videoFile!.path,
        colors: const [Color(0xFFFF416C), Color(0xFFFF4B2B)], // Sleek custom Sunset Orange for newly posted videos
      );

      // Insert at Index 0 of both Following and For You feeds
      feedProvider.addVideoToForYou(newVideo);
      feedProvider.addVideoToFollowing(newVideo);

      setState(() {
        _isUploading = false;
      });
      // Screen must only close after the user explicitly taps 'Post' and it completes
      Navigator.pop(context); 
    }
  }

  void _clearSelection() {
    setState(() {
      _videoController?.dispose();
      _videoController = null;
      _videoFile = null;
      _descController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _videoFile == null ? _buildSelectionView() : _buildPreviewView(),
      ),
    );
  }

  // Pure black selection view
  Widget _buildSelectionView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 16),
              Text(
                'Create Post',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.03),
                  border: Border.all(color: Colors.white10, width: 2),
                ),
                child: const Icon(
                  Icons.videocam_outlined,
                  color: Colors.white54,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Share a video on Cold',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Capture live or upload from your library',
                style: GoogleFonts.inter(
                  color: Colors.white38,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 48),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  children: [
                    _buildSelectionCard(
                      icon: Icons.camera_enhance_outlined,
                      title: 'Record Live Video',
                      subtitle: 'Use your front or back camera',
                      onTap: () => _pickVideo(ImageSource.camera),
                    ),
                    const SizedBox(height: 16),
                    _buildSelectionCard(
                      icon: Icons.video_library_outlined,
                      title: 'Select from Gallery',
                      subtitle: 'Choose a saved video from your device',
                      onTap: () => _pickVideo(ImageSource.gallery),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildSelectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
