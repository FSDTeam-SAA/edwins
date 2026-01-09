// import 'dart:math' as math;

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:language_app/features/home/home_view.dart';

// class DemoTestResult extends StatelessWidget {
//   const DemoTestResult({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       // appBar: AppBar(
//       //   backgroundColor: Colors.white,
//       //   elevation: 0,
//       //   leading: IconButton(
//       //     icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
//       //     onPressed: () => Navigator.pop(context),
//       //   ),
//       //   title: const Text(
//       //     'Test result',
//       //     style: TextStyle(
//       //         color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
//       //   ),
//       //   centerTitle: false,
//       // ),
//       body: Column(
//         children: [
//           const SizedBox(height: 60),
//           Expanded(
//             child: SingleChildScrollView(
//               child: Padding(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
//                 child: Column(
//                   children: [
//                     const SizedBox(height: 20),
//                     TweenAnimationBuilder<double>(
//                       tween: Tween(begin: 0.0, end: 1.0),
//                       duration: const Duration(milliseconds: 600),
//                       curve: Curves.easeOut,
//                       builder: (context, value, child) {
//                         return Transform.scale(
//                           scale: value,
//                           child: Opacity(
//                             opacity: value,
//                             child: child,
//                           ),
//                         );
//                       },
//                       child: const Column(
//                         children: [
//                           Text(
//                             'Your language level',
//                             style: TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.black,
//                             ),
//                           ),
//                           SizedBox(height: 12),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Text(
//                                 'B1',
//                                 style: TextStyle(
//                                   fontSize: 48,
//                                   fontWeight: FontWeight.bold,
//                                   color: Color(0xFFFF7043),
//                                   letterSpacing: 2,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 40),
//                     const RadarChartWidget(),
//                     const SizedBox(height: 60),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(24),
//             child: _AnimatedStartButton(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                       builder: (context) => const HomeView(
//                             initialHasStartedLearning: true,
//                           )),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _AnimatedStartButton extends StatefulWidget {
//   final VoidCallback onPressed;

//   const _AnimatedStartButton({required this.onPressed});

//   @override
//   State<_AnimatedStartButton> createState() => _AnimatedStartButtonState();
// }

// class _AnimatedStartButtonState extends State<_AnimatedStartButton>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _scaleAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 150),
//       vsync: this,
//     );
//     _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
//     );
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ScaleTransition(
//       scale: _scaleAnimation,
//       child: SizedBox(
//         width: double.infinity,
//         height: 56,
//         child: DecoratedBox(
//           decoration: BoxDecoration(
//             gradient: const LinearGradient(
//               colors: [Color(0xFFFF609D), Color(0xFFFF7A06)],
//             ),
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(
//                 color: const Color(0xFFFF609D).withOpacity(0.3),
//                 blurRadius: 15,
//                 offset: const Offset(0, 5),
//               )
//             ],
//           ),
//           child: ElevatedButton(
//             onPressed: () async {
//               HapticFeedback.mediumImpact();
//               await _controller.forward();
//               await _controller.reverse();
//               widget.onPressed();
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.transparent,
//               shadowColor: Colors.transparent,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             child: const Text(
//               'Continue Learning',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class RadarChartWidget extends StatelessWidget {
//   const RadarChartWidget({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return TweenAnimationBuilder<double>(
//       tween: Tween(begin: 0.0, end: 1.0),
//       duration: const Duration(milliseconds: 1000),
//       curve: Curves.easeOutCubic,
//       builder: (context, value, child) {
//         return SizedBox(
//           width: 320,
//           height: 320,
//           child: CustomPaint(
//             painter: RadarChartPainter(animationValue: value),
//           ),
//         );
//       },
//     );
//   }
// }

// class RadarChartPainter extends CustomPainter {
//   final double animationValue;

//   RadarChartPainter({this.animationValue = 1.0});

//   final List<String> labels = [
//     'Grammar\n20%',
//     'Speaking\n30%',
//     'Listening\n15%',
//     'Conversation\n25%',
//     'Vocabulary\n10%',
//   ];

//   final List<double> values = [20, 30, 15, 25, 10];

//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(size.width / 2, size.height / 2);
//     final radius = math.min(size.width, size.height) / 2 - 60;
//     const sides = 5;
//     final angle = (2 * math.pi) / sides;

//     final bgPaint = Paint()
//       ..color = const Color(0xFFFFF9C4).withOpacity(0.3)
//       ..style = PaintingStyle.fill;
//     canvas.drawCircle(center, radius + 20, bgPaint);

//     final webPaint = Paint()
//       ..color = const Color(0xFFE0E0E0)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1;

//     for (int level = 1; level <= 5; level++) {
//       final levelRadius = (radius * level) / 5;
//       final path = Path();
//       for (int i = 0; i < sides; i++) {
//         final x = center.dx + levelRadius * math.cos(angle * i - math.pi / 2);
//         final y = center.dy + levelRadius * math.sin(angle * i - math.pi / 2);
//         i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
//       }
//       path.close();
//       canvas.drawPath(path, webPaint);
//     }

//     final linePaint = Paint()
//       ..color = const Color(0xFFE0E0E0)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1;

//     for (int i = 0; i < sides; i++) {
//       final x = center.dx + radius * math.cos(angle * i - math.pi / 2);
//       final y = center.dy + radius * math.sin(angle * i - math.pi / 2);
//       canvas.drawLine(center, Offset(x, y), linePaint);
//     }

//     final dataPath = Path();
//     final dataPaint = Paint()
//       ..color = const Color(0xFFFFB74D).withOpacity(0.5)
//       ..style = PaintingStyle.fill;

//     final dataBorderPaint = Paint()
//       ..color = const Color(0xFFFF9800)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2;

//     for (int i = 0; i < sides; i++) {
//       final percentage = (values[i] / 100) * animationValue;
//       final dataRadius = radius * percentage;
//       final x = center.dx + dataRadius * math.cos(angle * i - math.pi / 2);
//       final y = center.dy + dataRadius * math.sin(angle * i - math.pi / 2);
//       i == 0 ? dataPath.moveTo(x, y) : dataPath.lineTo(x, y);
//     }
//     dataPath.close();
//     canvas.drawPath(dataPath, dataPaint);
//     canvas.drawPath(dataPath, dataBorderPaint);

//     final pointPaint = Paint()..color = const Color(0xFFFF9800);
//     for (int i = 0; i < sides; i++) {
//       final percentage = (values[i] / 100) * animationValue;
//       final dataRadius = radius * percentage;
//       final x = center.dx + dataRadius * math.cos(angle * i - math.pi / 2);
//       final y = center.dy + dataRadius * math.sin(angle * i - math.pi / 2);
//       canvas.drawCircle(Offset(x, y), 4, pointPaint);
//     }

//     const textStyle = TextStyle(
//       color: Color(0xFF757575),
//       fontSize: 12,
//       fontWeight: FontWeight.w500,
//     );

//     for (int i = 0; i < sides; i++) {
//       final labelRadius = radius + 35;
//       final x = center.dx + labelRadius * math.cos(angle * i - math.pi / 2);
//       final y = center.dy + labelRadius * math.sin(angle * i - math.pi / 2);

//       final textPainter = TextPainter(
//         text: TextSpan(text: labels[i], style: textStyle),
//         textAlign: TextAlign.center,
//         textDirection: TextDirection.ltr,
//       );
//       textPainter.layout();

//       double offsetX = x - textPainter.width / 2;
//       double offsetY = y - textPainter.height / 2;

//       if (i == 0) {
//         offsetY -= 10;
//       } else if (i == 1) {
//         offsetX += 5;
//         offsetY -= 5;
//       } else if (i == 2) {
//         offsetX += 5;
//         offsetY += 5;
//       } else if (i == 3) {
//         offsetX -= 5;
//         offsetY += 5;
//       } else if (i == 4) {
//         offsetX -= 5;
//         offsetY -= 5;
//       }

//       textPainter.paint(canvas, Offset(offsetX, offsetY));
//     }
//   }

//   @override
//   bool shouldRepaint(RadarChartPainter oldDelegate) {
//     return oldDelegate.animationValue != animationValue;
//   }
// }
