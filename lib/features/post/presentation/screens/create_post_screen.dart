import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isPosting = false;

  static const Color _electricBlue = Color(0xFF0088FF);

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _handlePost() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() {
      _isPosting = true;
    });

    // Mock Islamic AI Analysis Engine pipeline scan
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _isPosting = false;
      });
      Navigator.pop(context); // Close after successful post
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasText = _textController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(hasText),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCompositionArea(),
                    const SizedBox(height: 24),
                    _buildMediaPickerStrip(),
                  ],
                ),
              ),
            ),
            _buildActionToolbar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool hasText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () {
              if (!_isPosting) Navigator.pop(context);
            },
          ),
          ElevatedButton(
            onPressed: (hasText && !_isPosting) ? _handlePost : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _electricBlue,
              disabledBackgroundColor: const Color(0xFF111111),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white24,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: _isPosting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Post',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompositionArea() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white10,
          child: Icon(Icons.person, color: Colors.white54),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                cursorColor: _electricBlue,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                onChanged: (text) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: "What's happening?",
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 18),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.public, color: _electricBlue, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        "Everyone can reply",
                        style: GoogleFonts.inter(
                          color: _electricBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.white.withOpacity(0.1), thickness: 0.5),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMediaPickerStrip() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        padding: const EdgeInsets.only(left: 52), // Align with text area
        itemBuilder: (context, index) {
          final isCamera = index == 0;
          return Container(
            width: 90,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isCamera ? Colors.transparent : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCamera ? Colors.white38 : Colors.transparent,
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                isCamera ? Icons.camera_alt_outlined : Icons.image_outlined,
                color: isCamera ? Colors.white : Colors.white24,
                size: isCamera ? 32 : 24,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionToolbar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildToolbarIcon(Icons.image_outlined),
          _buildToolbarIcon(Icons.gif_box_outlined),
          _buildToolbarIcon(Icons.poll_outlined),
          _buildToolbarIcon(Icons.location_on_outlined),
          _buildToolbarIcon(Icons.mic_none_outlined),
        ],
      ),
    );
  }

  Widget _buildToolbarIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Icon(icon, color: _electricBlue, size: 24),
        ),
      ),
    );
  }
}
