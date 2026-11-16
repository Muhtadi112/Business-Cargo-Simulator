import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Full-screen branded intro. The supplied MP4 is streamed from its source URL
/// so the intro remains functional until the video is added to the local assets.
class SplashScreen extends StatefulWidget {
  const SplashScreen({required this.child, super.key});

  final Widget child;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static final Uri _videoUri = Uri.parse(
    'https://www.image2url.com/r2/default/videos/'
    '1794798370170-df28608c-1810-41c7-9f1f-ff76652d6644.mp4',
  );

  VideoPlayerController? _controller;
  bool _finished = false;
  bool _videoUnavailable = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeVideo());
  }

  Future<void> _initializeVideo() async {
    final controller = VideoPlayerController.networkUrl(_videoUri);
    _controller = controller;
    controller.addListener(_onVideoChanged);

    try {
      await controller.initialize();
      if (!mounted || _finished) return;
      await controller.setLooping(false);
      await controller.play();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _videoUnavailable = true);
    }
  }

  void _onVideoChanged() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final duration = controller.value.duration;
    if (duration > Duration.zero &&
        controller.value.position >= duration &&
        !_finished) {
      _continue();
    }
    if (mounted) setState(() {});
  }

  void _continue() {
    if (_finished) return;
    setState(() => _finished = true);
    _controller?.pause();
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return widget.child;

    final controller = _controller;
    final ready = controller?.value.isInitialized ?? false;
    final progress = ready && controller!.value.duration > Duration.zero
        ? (controller.value.position.inMilliseconds /
                controller.value.duration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0D151A),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _continue,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (ready)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller!.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              )
            else
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1B3035), Color(0xFF0D151A)],
                  ),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.18),
                    const Color(0xFF0D151A).withValues(alpha: 0.94),
                  ],
                  stops: const [0, 0.48, 1],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26, 30, 26, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(),
                    const Icon(
                      Icons.local_shipping_rounded,
                      color: Color(0xFFE0B867),
                      size: 58,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'BUSINESS CARGO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.2,
                      ),
                    ),
                    const Text(
                      'SIMULATOR',
                      style: TextStyle(
                        color: Color(0xFFE0B867),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 5,
                      ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: ready ? progress : null,
                          minHeight: 5,
                          color: const Color(0xFFE0B867),
                          backgroundColor: Colors.white24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _videoUnavailable
                          ? 'VIDEO TIDAK TERSEDIA • TAP UNTUK LANJUT'
                          : 'TAP TO START',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'BUILD YOUR LOGISTICS EMPIRE',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 9,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
