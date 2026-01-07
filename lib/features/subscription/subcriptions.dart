import 'package:flutter/material.dart';

// --- Data Model ---
class SubscriptionPlan {
  final String title;
  final String price;
  final String tests;
  final bool isSubscribed;

  SubscriptionPlan({
    required this.title,
    required this.price,
    required this.tests,
    this.isSubscribed = false,
  });
}

// --- Main Page with Animations ---
class SubscriptionMainPage extends StatefulWidget {
  const SubscriptionMainPage({super.key});

  @override
  State<SubscriptionMainPage> createState() => _SubscriptionMainPageState();
}

class _SubscriptionMainPageState extends State<SubscriptionMainPage>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      2,
      (index) => AnimationController(
        duration: Duration(milliseconds: 600 + (index * 100)),
        vsync: this,
      ),
    );

    _fadeAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
    }).toList();

    _slideAnimations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));
    }).toList();

    // Start animations with delay
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    final List<SubscriptionPlan> plans = [
      SubscriptionPlan(
          title: "Basic", price: "0.00", tests: "200", isSubscribed: true),
      SubscriptionPlan(
          title: "Basic", price: "8.99", tests: "300", isSubscribed: false),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.orange,
            size: isTablet ? 24 : 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Subscription',
          style: TextStyle(
            color: Colors.orange,
            fontSize: isTablet ? 22 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal =
              constraints.maxWidth > 600 ? constraints.maxWidth * 0.15 : 20.0;

          return ListView.separated(
            padding: EdgeInsets.symmetric(
              horizontal: horizontal,
              vertical: isTablet ? 20 : 10,
            ),
            itemCount: plans.length,
            separatorBuilder: (context, index) => SizedBox(
              height: isTablet ? 35 : 25,
            ),
            itemBuilder: (context, index) {
              final plan = plans[index];
              return FadeTransition(
                opacity: _fadeAnimations[index],
                child: SlideTransition(
                  position: _slideAnimations[index],
                  child: SubscriptionCard(
                    plan: plan,
                    onTap: () {
                      if (plan.isSubscribed) {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    SubscriptionDetailPage(plan: plan),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.0, 0.1),
                                    end: Offset.zero,
                                  ).animate(CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  )),
                                  child: child,
                                ),
                              );
                            },
                            transitionDuration:
                                const Duration(milliseconds: 400),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("Please subscribe first!"),
                            backgroundColor: const Color(0xFFFF7A06),
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.all(isTablet ? 30 : 20),
                            duration: const Duration(milliseconds: 2000),
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- Animated Subscription Card ---
class SubscriptionCard extends StatefulWidget {
  final SubscriptionPlan plan;
  final VoidCallback? onTap;
  final bool isDetailPage;

  const SubscriptionCard({
    super.key,
    required this.plan,
    this.onTap,
    this.isDetailPage = false,
  });

  @override
  State<SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends State<SubscriptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );

    _elevationAnimation = Tween<double>(begin: 0.06, end: 0.12).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final maxWidth = isTablet ? 600.0 : double.infinity;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          child: MouseRegion(
            onEnter: (_) => _hoverController.forward(),
            onExit: (_) => _hoverController.reverse(),
            child: AnimatedBuilder(
              animation: _hoverController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isPressed ? 0.98 : _scaleAnimation.value,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(_elevationAnimation.value),
                          blurRadius: 15 + (_elevationAnimation.value * 50),
                          offset:
                              Offset(0, 8 + (_elevationAnimation.value * 20)),
                        ),
                      ],
                    ),
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isTablet ? 24 : 20),
                      topRight: Radius.circular(isTablet ? 24 : 20),
                    ),
                    child: SizedBox(
                      height: isTablet ? 200 : 160,
                      width: double.infinity,
                      child: const AnimatedWaveBackground(),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      isTablet ? 32 : 24,
                      isTablet ? 16 : 10,
                      isTablet ? 32 : 24,
                      isTablet ? 32 : 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.plan.title,
                          style: TextStyle(
                            fontSize: isTablet ? 34 : 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        SizedBox(height: isTablet ? 12 : 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              "\$ ${widget.plan.price}",
                              style: TextStyle(
                                fontSize: isTablet ? 42 : 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            Text(
                              " /month",
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 16,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isTablet ? 16 : 12),
                        Text(
                          "Enjoy your ${widget.plan.tests} Test every year",
                          style: TextStyle(
                            color: const Color(0xFF7D848D),
                            fontSize: isTablet ? 18 : 16.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: isTablet ? 14 : 10),
                        Divider(
                          color: Colors.orange,
                          thickness: isTablet ? 1.5 : 1.2,
                        ),
                        SizedBox(height: isTablet ? 30 : 25),
                        if (widget.isDetailPage)
                          _buildDetailPageButtons(isTablet)
                        else
                          _buildSubscribeButton(isTablet),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailPageButtons(bool isTablet) {
    return Row(
      children: [
        Expanded(
          child: AnimatedButton(
            onPressed: () {},
            isOutlined: true,
            child: Text(
              "Cancel",
              style: TextStyle(
                color: const Color(0xFFFF609D),
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 16 : 14,
              ),
            ),
          ),
        ),
        SizedBox(width: isTablet ? 20 : 15),
        Expanded(
          child: AnimatedButton(
            onPressed: () {},
            isGradient: true,
            child: Text(
              "Pause",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 16 : 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscribeButton(bool isTablet) {
    return AnimatedButton(
      onPressed: widget.onTap,
      isGradient: !widget.plan.isSubscribed,
      backgroundColor:
          widget.plan.isSubscribed ? const Color(0xFFC7B8B8) : null,
      child: Text(
        widget.plan.isSubscribed ? "Subscribed" : "Subscribe",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: isTablet ? 18 : 16,
        ),
      ),
    );
  }
}

// --- Animated Button Widget ---
class AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isOutlined;
  final bool isGradient;
  final Color? backgroundColor;

  const AnimatedButton({
    super.key,
    this.onPressed,
    required this.child,
    this.isOutlined = false,
    this.isGradient = false,
    this.backgroundColor,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: widget.backgroundColor,
            border: widget.isOutlined
                ? const Border.fromBorderSide(
                    BorderSide(color: Color(0xFFFF609D), width: 2))
                : null,
            gradient: widget.isGradient
                ? const LinearGradient(
                    colors: [Color(0xFFFF609D), Color(0xFFFF7A06)],
                  )
                : null,
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

// --- Animated Wave Background ---
class AnimatedWaveBackground extends StatefulWidget {
  const AnimatedWaveBackground({super.key});

  @override
  State<AnimatedWaveBackground> createState() => _AnimatedWaveBackgroundState();
}

class _AnimatedWaveBackgroundState extends State<AnimatedWaveBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
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
        return CustomPaint(
          painter: AnimatedWavePainter(_controller.value),
        );
      },
    );
  }
}

// --- Animated Wave Painter ---
class AnimatedWavePainter extends CustomPainter {
  final double animationValue;

  AnimatedWavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Layer 1 - Bottom wave
    Paint p1 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.fromARGB(255, 239, 109, 159),
          Color.fromARGB(255, 246, 158, 111)
        ],
      ).createShader(rect);

    Path path1 = Path();
    path1.lineTo(0, size.height * (0.45 + animationValue * 0.02));
    path1.cubicTo(
      size.width * -0.3,
      size.height * (-0.01 + animationValue * 0.02),
      size.width * 0.8,
      size.height * (0.6 + animationValue * 0.03),
      size.width,
      size.height * 1.0,
    );
    path1.lineTo(size.width, 0);
    path1.close();
    canvas.drawPath(path1, p1);

    // Layer 2 - Middle wave
    Paint p2 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF718B), Color.fromARGB(255, 250, 132, 81)],
      ).createShader(rect);

    Path path2 = Path();
    path2.lineTo(0, size.height * (0.3 + animationValue * 0.015));
    path2.cubicTo(
      size.width * -0.20,
      size.height * (0.01 + animationValue * 0.015),
      size.width * 0.7,
      size.height * (0.4 + animationValue * 0.025),
      size.width,
      size.height * (0.8 - animationValue * 0.02),
    );
    path2.lineTo(size.width, 0);
    path2.close();
    canvas.drawPath(path2, p2);

    // Layer 3 - Top wave
    Paint p3 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF8199), Color.fromARGB(255, 255, 142, 98)],
      ).createShader(rect);

    Path path3 = Path();
    path3.lineTo(0, size.height * (0.15 + animationValue * 0.01));
    path3.cubicTo(
      size.width * -0.20,
      size.height * (0.01 + animationValue * 0.01),
      size.width * 0.6,
      size.height * (0.1 + animationValue * 0.02),
      size.width,
      size.height * (0.55 - animationValue * 0.015),
    );
    path3.lineTo(size.width, 0);
    path3.close();
    canvas.drawPath(path3, p3);
  }

  @override
  bool shouldRepaint(AnimatedWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

// --- Detail Page ---
class SubscriptionDetailPage extends StatefulWidget {
  final SubscriptionPlan plan;
  const SubscriptionDetailPage({super.key, required this.plan});

  @override
  State<SubscriptionDetailPage> createState() => _SubscriptionDetailPageState();
}

class _SubscriptionDetailPageState extends State<SubscriptionDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.orange,
            size: isTablet ? 24 : 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Subscription',
          style: TextStyle(
            color: Colors.orange,
            fontSize: isTablet ? 22 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isTablet ? 30 : 20),
            child: SubscriptionCard(plan: widget.plan, isDetailPage: true),
          ),
        ),
      ),
    );
  }
}
