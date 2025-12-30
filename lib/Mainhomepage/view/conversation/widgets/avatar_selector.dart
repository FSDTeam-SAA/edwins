import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../models/avatar_model.dart';

class AvatarSelector extends StatefulWidget {
  final AvatarModel selectedAvatar;
  final Function(AvatarModel) onAvatarSelected;

  const AvatarSelector({
    super.key,
    required this.selectedAvatar,
    required this.onAvatarSelected,
  });

  @override
  State<AvatarSelector> createState() => _AvatarSelectorState();
}

class _AvatarSelectorState extends State<AvatarSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Animated Avatar Display
        Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.35,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFFF3E0),
                widget.selectedAvatar.accentColor.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: widget.selectedAvatar.accentColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Animated gradient background
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(
                              _animationController.value - 0.5,
                              _animationController.value - 0.5,
                            ),
                            colors: [
                              widget.selectedAvatar.accentColor.withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Main Avatar Icon
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _floatAnimation.value),
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: widget.selectedAvatar.accentColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.selectedAvatar.accentColor.withOpacity(0.3),
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            widget.selectedAvatar.id == 'clara'
                                ? Icons.face
                                : Icons.face_outlined,
                            size: 100,
                            color: widget.selectedAvatar.accentColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Floating particles
                ...List.generate(8, (index) {
                  final angle = (index * 45) * math.pi / 180;
                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      final distance = 80 + (20 * _animationController.value);
                      final screenWidth = MediaQuery.of(context).size.width;
                      final containerHeight = MediaQuery.of(context).size.height * 0.35;
                      
                      return Positioned(
                        left: (screenWidth / 2) - 4 + distance * math.cos(angle),
                        top: (containerHeight / 2) - 4 + distance * math.sin(angle),
                        child: Opacity(
                          opacity: 0.6 * (1 - _animationController.value),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.selectedAvatar.accentColor,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),

                // Info badge
                Positioned(
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: widget.selectedAvatar.accentColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'AI Powered Companion',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Avatar Info
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Column(
            key: ValueKey(widget.selectedAvatar.id),
            children: [
              Text(
                widget.selectedAvatar.name,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: widget.selectedAvatar.accentColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.selectedAvatar.description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Avatar Selection Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: AvatarModel.all.map((avatar) {
            final isSelected = avatar.id == widget.selectedAvatar.id;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: GestureDetector(
                onTap: () => widget.onAvatarSelected(avatar),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: isSelected ? 90 : 70,
                  height: isSelected ? 90 : 70,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              avatar.accentColor.withOpacity(0.3),
                              avatar.accentColor.withOpacity(0.1),
                            ],
                          )
                        : null,
                    color: !isSelected
                        ? avatar.accentColor.withOpacity(0.1)
                        : null,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? avatar.accentColor
                          : Colors.grey[300]!,
                      width: isSelected ? 3 : 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: avatar.accentColor.withOpacity(0.4),
                              blurRadius: 15,
                              spreadRadius: 2,
                              offset: const Offset(0, 5),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        avatar.name[0],
                        style: TextStyle(
                          fontSize: isSelected ? 36 : 28,
                          fontWeight: FontWeight.bold,
                          color: avatar.accentColor,
                        ),
                      ),
                      if (isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 20,
                          height: 3,
                          decoration: BoxDecoration(
                            color: avatar.accentColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Avatar names
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: AvatarModel.all.map((avatar) {
            final isSelected = avatar.id == widget.selectedAvatar.id;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 23.0),
              child: Text(
                avatar.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? avatar.accentColor : Colors.grey[500],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}