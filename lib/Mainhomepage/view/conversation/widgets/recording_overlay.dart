import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../utils/app_style.dart';

class RecordingOverlay extends StatefulWidget {
  final VoidCallback onRecordingComplete;

  const RecordingOverlay({
    super.key,
    required this.onRecordingComplete,
  });

  @override
  State<RecordingOverlay> createState() => _RecordingOverlayState();
}

class _RecordingOverlayState extends State<RecordingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _glowController;
  final List<double> _waveHeights = List.generate(20, (index) => 0.3);

  @override
  void initState() {
    super.initState();

    // Waveform animation
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    )..repeat();

    // Glow pulse animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _waveController.addListener(() {
      setState(() {
        for (int i = 0; i < _waveHeights.length; i++) {
          _waveHeights[i] = 0.3 +
              math.Random().nextDouble() * 0.7 +
              math.sin((i + _waveController.value * 10) * 0.5) * 0.3;
        }
      });
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // Prevent taps from going through
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Stack(
          children: [
            // Waveform in the center
            Center(
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(_waveHeights.length, (index) {
                      return Container(
                        width: 4,
                        height: 80 * _waveHeights[index],
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF609D),
                              Color(0xFFFF7A06),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),

            // Microphone button at bottom center
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTapUp: (_) => widget.onRecordingComplete(),
                  onTapCancel: () => widget.onRecordingComplete(),
                  child: AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow ring
                          Container(
                            width: 180 + (20 * _glowController.value),
                            height: 180 + (20 * _glowController.value),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.micButtonOrange.withOpacity(
                                      0.4 * (1 - _glowController.value)),
                                  AppColors.micButtonPink.withOpacity(
                                      0.2 * (1 - _glowController.value)),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                          // Middle glow ring
                          Container(
                            width: 150 + (15 * _glowController.value),
                            height: 150 + (15 * _glowController.value),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.micButtonOrange.withOpacity(
                                      0.5 * (1 - _glowController.value)),
                                  AppColors.micButtonPink.withOpacity(
                                      0.3 * (1 - _glowController.value)),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.6, 1.0],
                              ),
                            ),
                          ),
                          // Inner glow
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.micButtonOrange.withOpacity(0.6),
                                  AppColors.micButtonPink.withOpacity(0.4),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.7, 1.0],
                              ),
                            ),
                          ),
                          // Main microphone button
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              gradient: AppColors.micGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.micButtonOrange.withOpacity(0.6),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.mic,
                              color: Colors.white,
                              size: 45,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}