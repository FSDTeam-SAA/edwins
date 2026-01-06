import 'package:flutter/material.dart';
import 'package:language_app/app/theme/app_style.dart';

enum VoiceState { normal, voiceReady, recording }

class VoiceRecorderUI extends StatelessWidget {
  final VoiceState state;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onCancel;

  const VoiceRecorderUI({
    super.key,
    required this.state,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // Determine active UI state based on the enum
    final bool isRecording = state == VoiceState.recording;

    return GestureDetector(
      // Allow tapping the background to close only when not actively recording
      onTap: isRecording ? null : onCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: double.infinity,
        height: double.infinity,
        // State 2 (Recording) has a translucent grey background
        // State 1 (Ready) has a solid white background
        color: isRecording ? Colors.black.withOpacity(0.4) : Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // Header with Back Button
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios,
                      color:
                          isRecording ? Colors.white : AppColors.primaryOrange),
                  onPressed: onCancel,
                ),
              ),

              const Spacer(flex: 2),

              // Waveform Display (State 2 only)
              if (isRecording)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Image.asset(
                    "assets/waveform.png", // Ensure this matches your pubspec.yaml
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                )
              else
                const SizedBox(height: 120),

              const Spacer(flex: 3),

              // Interactive Microphone Area
              GestureDetector(
                onLongPressStart: (_) => onStartRecording(),
                onLongPressEnd: (_) => onStopRecording(),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Concentric Ripple Rings
                    _buildRippleCircle(
                        size: 160, opacity: isRecording ? 0.2 : 0.1),
                    _buildRippleCircle(
                        size: 200, opacity: isRecording ? 0.15 : 0.06),
                    _buildRippleCircle(
                        size: 240, opacity: isRecording ? 0.1 : 0.03),

                    // Main Gradient Microphone Button
                    Container(
                      height: 110,
                      width: 110,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: isRecording ? 60 : 50,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to build the ripple effect rings
  Widget _buildRippleCircle({required double size, required double opacity}) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // We use a light orange/peach tint for ripples as seen in your screenshots
        color: const Color(0xFFFF8C42).withOpacity(opacity),
      ),
    );
  }
}
