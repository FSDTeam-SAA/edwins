import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../utils/app_style.dart';

class ChatMessage extends StatefulWidget {
  final String text;
  final bool isUser;
  final String? audioUrl;
  final bool showPlayButton;
  // Added optional translation parameter to handle the Map data
  final String? translation;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    this.audioUrl,
    this.showPlayButton = false,
    this.translation,
  });

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage>
    with SingleTickerProviderStateMixin {
  bool isPlaying = false;
  bool showTranslation = false;
  late AnimationController _playController;

  @override
  void initState() {
    super.initState();
    _playController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _playController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      isPlaying = !isPlaying;
    });

    if (isPlaying) {
      _playController.forward();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            isPlaying = false;
          });
          _playController.reverse();
        }
      });
    } else {
      _playController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Logic: Waveform appears for Avatar system messages OR User voice recordings
    final bool shouldShowWaveform = widget.showPlayButton && widget.audioUrl != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            widget.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // --- AUDIO WAVEFORM PLAYER ---
          // Now only shows when there is an actual audio component
          if (shouldShowWaveform)
            GestureDetector(
              onTap: _togglePlay,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryOrange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Flexible(
                      child: SizedBox(
                        height: 24,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(18, (index) {
                            final heights = [
                              12.0, 18.0, 14.0, 20.0, 16.0, 22.0,
                              18.0, 24.0, 20.0, 24.0, 18.0, 22.0,
                              16.0, 20.0, 14.0, 18.0, 12.0, 16.0
                            ];
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 2.5,
                              height: isPlaying ? heights[index] : 12.0,
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('1:34',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),

          // --- MESSAGE BUBBLE ---
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: widget.isUser ? AppColors.primaryGradient : null,
              color: widget.isUser ? null : AppColors.avatarBubbleBg,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft:
                    widget.isUser ? const Radius.circular(20) : Radius.zero,
                bottomRight:
                    widget.isUser ? Radius.zero : const Radius.circular(20),
              ),
              boxShadow: [
                if (widget.isUser)
                  BoxShadow(
                    color: AppColors.primaryOrange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: MarkdownBody(
              // Switch between original text and translation
              data: (showTranslation && widget.translation != null)
                  ? widget.translation!
                  : widget.text,
              styleSheet: MarkdownStyleSheet(
                p: widget.isUser
                    ? AppTypography.chatBubbleUser
                    : AppTypography.chatBubbleAvatar,
                strong: (widget.isUser
                        ? AppTypography.chatBubbleUser
                        : AppTypography.chatBubbleAvatar)
                    .copyWith(
                  fontWeight: FontWeight.bold,
                  backgroundColor: widget.isUser
                      ? Colors.white.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.15),
                ),
              ),
            ),
          ),

          // --- TRANSLATION & AUDIO TOOLS (Avatar Only) ---
          if (!widget.isUser)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (widget.translation != null) {
                        setState(() {
                          showTranslation = !showTranslation;
                        });
                      }
                    },
                    child: Icon(
                      Icons.language,
                      color: showTranslation 
                          ? Colors.orange 
                          : AppColors.suggestedWordBorder,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _togglePlay,
                    child: Icon(
                      Icons.volume_up,
                      color: isPlaying 
                          ? Colors.orange 
                          : AppColors.suggestedWordBorder,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_markdown/flutter_markdown.dart'; // Import this
// import '../../../../utils/app_style.dart';

// class ChatMessage extends StatefulWidget {
//   final String text;
//   final bool isUser;
//   final String? audioUrl;
//   final bool showPlayButton;


//   const ChatMessage({
//     super.key,
//     required this.text,
//     required this.isUser,
//     this.audioUrl,
//     this.showPlayButton = false,

//   });

//   @override
//   State<ChatMessage> createState() => _ChatMessageState();
// }

// class _ChatMessageState extends State<ChatMessage>
//     with SingleTickerProviderStateMixin {
//   bool isPlaying = false;
//   late AnimationController _playController;

//   @override
//   void initState() {
//     super.initState();
//     _playController = AnimationController(
//       duration: const Duration(milliseconds: 100),
//       vsync: this,
//     );
//   }

//   @override
//   void dispose() {
//     _playController.dispose();
//     super.dispose();
//   }

//   void _togglePlay() {
//     setState(() {
//       isPlaying = !isPlaying;
//     });

//     if (isPlaying) {
//       _playController.forward();
//       Future.delayed(const Duration(seconds: 2), () {
//         if (mounted) {
//           setState(() {
//             isPlaying = false;
//           });
//           _playController.reverse();
//         }
//       });
//     } else {
//       _playController.reverse();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {

//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: Column(
//         crossAxisAlignment:
//             widget.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           // Audio Player (unchanged)
//           if (widget.showPlayButton && widget.audioUrl != null)
//             GestureDetector(
//               onTap: _togglePlay,
//               child: Container(
//                 margin: const EdgeInsets.only(bottom: 8),
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                 constraints: BoxConstraints(
//                   maxWidth: MediaQuery.of(context).size.width * 0.75,
//                 ),
//                 decoration: BoxDecoration(
//                   gradient: AppColors.primaryGradient,
//                   borderRadius: BorderRadius.circular(25),
//                   boxShadow: [
//                     BoxShadow(
//                       color: AppColors.primaryOrange.withOpacity(0.3),
//                       blurRadius: 8,
//                       offset: const Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 22),
//                     const SizedBox(width: 10),
//                     Flexible(
//                       child: SizedBox(
//                         height: 24,
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: List.generate(18, (index) {
//                             final heights = [12.0, 18.0, 14.0, 20.0, 16.0, 22.0, 18.0, 24.0, 20.0, 24.0, 18.0, 22.0, 16.0, 20.0, 14.0, 18.0, 12.0, 16.0];
//                             return AnimatedContainer(
//                               duration: const Duration(milliseconds: 300),
//                               width: 2.5,
//                               height: isPlaying ? heights[index] : 12.0,
//                               margin: const EdgeInsets.symmetric(horizontal: 1.5),
//                               decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2),),
//                             );
//                           }),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     const Text('1:34', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
//                   ],
//                 ),
//               ),
//             ),

//           // --- UPDATED MESSAGE BUBBLE ---
//           Container(
//             constraints: BoxConstraints(
//               maxWidth: MediaQuery.of(context).size.width * 0.75,
//             ),
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
//             decoration: BoxDecoration(
//               gradient: widget.isUser ? AppColors.primaryGradient : null,
//               color: widget.isUser ? null : AppColors.avatarBubbleBg,
//               borderRadius: BorderRadius.only(
//                 topLeft: const Radius.circular(20),
//                 topRight: const Radius.circular(20),
//                 bottomLeft: widget.isUser ? const Radius.circular(20) : Radius.zero,
//                 bottomRight: widget.isUser ? Radius.zero : const Radius.circular(20),
//               ),
//               boxShadow: [
//                 if (widget.isUser)
//                   BoxShadow(
//                     color: AppColors.primaryOrange.withOpacity(0.3),
//                     blurRadius: 8,
//                     offset: const Offset(0, 4),
//                   ),
//               ],
//             ),
//             // Use MarkdownBody to handle the **text** formatting
//             child: MarkdownBody(
//               data: widget.text,
//               styleSheet: MarkdownStyleSheet(
//                 p: widget.isUser ? AppTypography.chatBubbleUser : AppTypography.chatBubbleAvatar,
//                 strong: (widget.isUser 
//                   ? AppTypography.chatBubbleUser 
//                   : AppTypography.chatBubbleAvatar).copyWith(
//                     fontWeight: FontWeight.bold,
//                     // This creates the highlight effect
//                     backgroundColor: widget.isUser 
//                         ? Colors.white.withOpacity(0.2) 
//                         : Colors.orange.withOpacity(0.2),
//                 ),
//               ),
//             ),
//           ),

//           // Translation and audio icons (unchanged)
//           if (!widget.isUser)
//             const Padding(
//               padding: const EdgeInsets.only(top: 8, left: 8),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(Icons.language, color: AppColors.suggestedWordBorder, size: 20),
//                    SizedBox(width: 12),
//                   Icon(Icons.volume_up, color: AppColors.suggestedWordBorder, size: 20),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// // import 'package:flutter/material.dart';
// // import '../../../../utils/app_style.dart';

// // class ChatMessage extends StatefulWidget {
// //   final String text;
// //   final bool isUser;
// //   final String? audioUrl;
// //   final bool showPlayButton;

// //   const ChatMessage({
// //     super.key,
// //     required this.text,
// //     required this.isUser,
// //     this.audioUrl,
// //     this.showPlayButton = false,
// //   });

// //   @override
// //   State<ChatMessage> createState() => _ChatMessageState();
// // }

// // class _ChatMessageState extends State<ChatMessage>
// //     with SingleTickerProviderStateMixin {
// //   bool isPlaying = false;
// //   late AnimationController _playController;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _playController = AnimationController(
// //       duration: const Duration(milliseconds: 100),
// //       vsync: this,
// //     );
// //   }

// //   @override
// //   void dispose() {
// //     _playController.dispose();
// //     super.dispose();
// //   }

// //   void _togglePlay() {
// //     setState(() {
// //       isPlaying = !isPlaying;
// //     });

// //     if (isPlaying) {
// //       _playController.forward();
// //       // Simulate audio playing for 2 seconds
// //       Future.delayed(const Duration(seconds: 2), () {
// //         if (mounted) {
// //           setState(() {
// //             isPlaying = false;
// //           });
// //           _playController.reverse();
// //         }
// //       });
// //     } else {
// //       _playController.reverse();
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 16),
// //       child: Column(
// //         crossAxisAlignment:
// //             widget.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
// //         children: [
// //           // Audio Player (for messages with audio)
// //           if (widget.showPlayButton && widget.audioUrl != null)
// //             GestureDetector(
// //               onTap: _togglePlay,
// //               child: Container(
// //                 margin: const EdgeInsets.only(bottom: 8),
// //                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
// //                 constraints: BoxConstraints(
// //                   maxWidth: MediaQuery.of(context).size.width * 0.75,
// //                 ),
// //                 decoration: BoxDecoration(
// //                   gradient: AppColors.primaryGradient,
// //                   borderRadius: BorderRadius.circular(25),
// //                   boxShadow: [
// //                     BoxShadow(
// //                       color: AppColors.primaryOrange.withOpacity(0.3),
// //                       blurRadius: 8,
// //                       offset: const Offset(0, 4),
// //                     ),
// //                   ],
// //                 ),
// //                 child: Row(
// //                   mainAxisSize: MainAxisSize.min,
// //                   children: [
// //                     Icon(
// //                       isPlaying ? Icons.pause : Icons.play_arrow,
// //                       color: Colors.white,
// //                       size: 22,
// //                     ),
// //                     const SizedBox(width: 10),
// //                     // Animated Waveform
// //                     Flexible(
// //                       child: SizedBox(
// //                         height: 24,
// //                         child: Row(
// //                           mainAxisSize: MainAxisSize.min,
// //                           children: List.generate(18, (index) {
// //                             final heights = [
// //                               12.0, 18.0, 14.0, 20.0, 16.0, 22.0, 
// //                               18.0, 24.0, 20.0, 24.0, 18.0, 22.0,
// //                               16.0, 20.0, 14.0, 18.0, 12.0, 16.0
// //                             ];
// //                             return AnimatedContainer(
// //                               duration: const Duration(milliseconds: 300),
// //                               width: 2.5,
// //                               height: isPlaying ? heights[index] : 12.0,
// //                               margin: const EdgeInsets.symmetric(horizontal: 1.5),
// //                               decoration: BoxDecoration(
// //                                 color: Colors.white,
// //                                 borderRadius: BorderRadius.circular(2),
// //                               ),
// //                             );
// //                           }),
// //                         ),
// //                       ),
// //                     ),
// //                     const SizedBox(width: 10),
// //                     const Text(
// //                       '1:34',
// //                       style: TextStyle(
// //                         color: Colors.white,
// //                         fontSize: 13,
// //                         fontWeight: FontWeight.w500,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),

// //           // Message Bubble
// //           Container(
// //             constraints: BoxConstraints(
// //               maxWidth: MediaQuery.of(context).size.width * 0.75,
// //             ),
// //             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
// //             decoration: BoxDecoration(
// //               gradient: widget.isUser ? AppColors.primaryGradient : null,
// //               color: widget.isUser ? null : AppColors.avatarBubbleBg,
// //               borderRadius: BorderRadius.only(
// //                 topLeft: const Radius.circular(20),
// //                 topRight: const Radius.circular(20),
// //                 bottomLeft: widget.isUser ? const Radius.circular(20) : Radius.zero,
// //                 bottomRight: widget.isUser ? Radius.zero : const Radius.circular(20),
// //               ),
// //               boxShadow: [
// //                 if (widget.isUser)
// //                   BoxShadow(
// //                     color: AppColors.primaryOrange.withOpacity(0.3),
// //                     blurRadius: 8,
// //                     offset: const Offset(0, 4),
// //                   ),
// //               ],
// //             ),
// //             child: Text(
// //               widget.text,
// //               style: widget.isUser
// //                   ? AppTypography.chatBubbleUser
// //                   : AppTypography.chatBubbleAvatar,
// //             ),
// //           ),

// //           // Translation and audio icons (for avatar messages)
// //           if (!widget.isUser)
// //             Padding(
// //               padding: const EdgeInsets.only(top: 8, left: 8),
// //               child: Row(
// //                 mainAxisSize: MainAxisSize.min,
// //                 children: [
// //                   Icon(
// //                     Icons.language,
// //                     color: AppColors.suggestedWordBorder,
// //                     size: 20,
// //                   ),
// //                   const SizedBox(width: 12),
// //                   Icon(
// //                     Icons.volume_up,
// //                     color: AppColors.suggestedWordBorder,
// //                     size: 20,
// //                   ),
// //                 ],
// //               ),
// //             ),
// //         ],
// //       ),
// //     );
// //   }
// // }