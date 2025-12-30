import 'package:flutter/material.dart';
import '../../../../utils/app_style.dart';
import '../../../../models/avatar_model.dart';

class AvatarCard extends StatefulWidget {
  final AvatarModel avatar;
  final VoidCallback? onSoundTap;

  const AvatarCard({super.key, required this.avatar, this.onSoundTap});

  @override
  State<AvatarCard> createState() => _AvatarCardState();
}

class _AvatarCardState extends State<AvatarCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Floating motion for the avatar character
    _floatAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Pulsing glow effect behind the avatar
    _glowAnimation = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.avatar.accentColor;

    return LayoutBuilder(builder: (context, constraints) {
      // Logic to determine if the card is in 'Mini' mode (shrunk by keyboard)
      bool isMini = constraints.maxHeight < 120;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.avatarCardBg,
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(isMini ? 16 : 24),
          border: Border.all(color: color.withOpacity(0.1), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isMini ? 16 : 24),
          child: Stack(
            children: [
              // 1. Background Animated Glow (Hide or adjust in mini mode)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: isMini ? const Alignment(-0.8, 0) : Alignment.center,
                          colors: [
                            color.withOpacity(0.15 * _glowAnimation.value),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 2. The Animated "Character"
              AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                alignment: isMini ? const Alignment(-0.85, 0) : Alignment.center,
                child: AnimatedBuilder(
                  animation: _floatAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      // Only float when in full size mode
                      offset: Offset(0, isMini ? 0 : _floatAnimation.value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isMini ? 50 : 100,
                        height: isMini ? 50 : 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: isMini ? 10 : 20,
                              spreadRadius: isMini ? 1 : 2,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              widget.avatar.id == 'clara'
                                  ? Icons.face_retouching_natural
                                  : Icons.face_unlock_rounded,
                              size: isMini ? 30 : 60,
                              color: color,
                            ),
                            // "Alive" indicator
                            Positioned(
                              bottom: isMini ? 2 : 10,
                              right: isMini ? 2 : 10,
                              child: Container(
                                width: isMini ? 8 : 12,
                                height: isMini ? 8 : 12,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: isMini ? 1.5 : 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 3. Name Badge / Label
              // In mini mode, we move it next to the avatar, otherwise top-left
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                top: isMini ? 28 : 16,
                left: isMini ? 75 : 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.avatar.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isMini ? 12 : 14,
                    ),
                  ),
                ),
              ),

              // 4. Sound Interaction Button (Hide in mini mode to save space)
              if (!isMini)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: widget.onSoundTap,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: Icon(Icons.volume_up, color: color, size: 20),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}