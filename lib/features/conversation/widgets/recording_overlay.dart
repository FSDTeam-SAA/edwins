import 'dart:async';
import 'package:flutter/material.dart';
import 'package:language_app/app/theme/app_style.dart';

class RecordingOverlay extends StatefulWidget {
  final VoidCallback onRecordingComplete;
  final VoidCallback onRecordingCancelled; // NEW callback

  const RecordingOverlay({
    super.key,
    required this.onRecordingComplete,
    required this.onRecordingCancelled,
  });

  @override
  State<RecordingOverlay> createState() => _RecordingOverlayState();
}

class _RecordingOverlayState extends State<RecordingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  Timer? _timer;
  int _seconds = 0;

  // NEW: Track drag offset
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String get _timerText {
    final minutes = _seconds ~/ 60;
    final seconds = _seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(color: Colors.transparent),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // A. Mic Icon (Changes to Trash Bin when dragging far left)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _dragOffset < -100 // Threshold check
                        ? const Icon(
                            Icons.delete_outline,
                            key: ValueKey("trash"),
                            color: Colors.red,
                            size: 28,
                          )
                        : FadeTransition(
                            key: const ValueKey("mic"),
                            opacity: _blinkController,
                            child: const Icon(
                              Icons.mic,
                              color: Colors.red,
                              size: 28,
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),

                  // B. Timer
                  Text(
                    _timerText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontFamily: "Inter",
                    ),
                  ),

                  // C. SLIDE TO CANCEL AREA
                  Expanded(
                    child: GestureDetector(
                      // 1. Detect Drag Update
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          // Only allow dragging to the left (negative values)
                          if (details.primaryDelta! < 0 || _dragOffset < 0) {
                            _dragOffset += details.primaryDelta!;
                          }
                        });
                      },
                      // 2. Detect Drag End
                      onHorizontalDragEnd: (details) {
                        // If dragged significantly to the left (e.g., -100 pixels)
                        if (_dragOffset < -100) {
                          widget.onRecordingCancelled();
                        } else {
                          // Snap back if not dragged enough
                          setState(() {
                            _dragOffset = 0.0;
                          });
                        }
                      },
                      child: Container(
                        // Important: Transparent color ensures the whole area captures touches
                        color: Colors.transparent,
                        height: 50,
                        alignment: Alignment.centerRight,
                        child: Transform.translate(
                          offset: Offset(_dragOffset, 0),
                          child: Opacity(
                            // Fade out as you drag left
                            opacity: (1 - (-_dragOffset / 150)).clamp(0.0, 1.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ShimmerText(
                                  text: "Slide to cancel",
                                  textColor: Colors.grey[400]!,
                                ),
                                const SizedBox(
                                    width: 20), // Spacing from send button
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // D. Send Button (Scales down when dragging to cancel)
                  AnimatedScale(
                    scale: _dragOffset < -50 ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: GestureDetector(
                      onTap: widget.onRecordingComplete,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryOrange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// (ShimmerText remains the same as previous)
class ShimmerText extends StatefulWidget {
  final String text;
  final Color textColor;

  const ShimmerText({super.key, required this.text, required this.textColor});

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.translate(
              offset: Offset(-5 * _controller.value, 0),
              child:
                  Icon(Icons.chevron_left, color: widget.textColor, size: 18),
            ),
            Text(
              widget.text,
              style: TextStyle(
                color: widget.textColor,
                fontSize: 14,
              ),
            ),
          ],
        );
      },
    );
  }
}
