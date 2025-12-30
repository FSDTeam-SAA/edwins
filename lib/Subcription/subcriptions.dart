import 'package:flutter/material.dart';

// --- Data Model (No Change) ---
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

// --- Main Page (No Change) ---
class SubscriptionMainPage extends StatelessWidget {
  const SubscriptionMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<SubscriptionPlan> plans = [
      SubscriptionPlan(title: "Basic", price: "0.00", tests: "200", isSubscribed: true),
      SubscriptionPlan(title: "Basic", price: "8.99", tests: "300", isSubscribed: false),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.orange, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Subscription', 
          style: TextStyle(color: Colors.orange, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: plans.length,
        separatorBuilder: (context, index) => const SizedBox(height: 25),
        itemBuilder: (context, index) {
          final plan = plans[index];
          return SubscriptionCard(
            plan: plan,
            onTap: () {
              if (plan.isSubscribed) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SubscriptionDetailPage(plan: plan)),
                );
              } else {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please subscribe first!"),
                    backgroundColor: Color(0xFFFF7A06),
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.all(20),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}

// --- Subscription Card Widget (No Change) ---
class SubscriptionCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: CustomPaint(
                painter: ExactVisualWavePainter(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text("\$ ${plan.price}", style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.orange)),
                    const Text(" /month", style: TextStyle(fontSize: 16, color: Colors.orange)),
                  ],
                ),
                const SizedBox(height: 12),
                Text("Enjoy your ${plan.tests} Test every year", 
                  style: const TextStyle(color: Color(0xFF7D848D), fontSize: 16.5, fontWeight: FontWeight.w400)),
                const SizedBox(height: 10),
                const Divider(color: Colors.orange, thickness: 1.2),
                const SizedBox(height: 25),
                if (isDetailPage)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFF609D)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Cancel", style: TextStyle(color: Color(0xFFFF609D), fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(colors: [Color(0xFFFF609D), Color(0xFFFF7A06)]),
                          ),
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text("Pause", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: plan.isSubscribed ? const Color(0xFFC7B8B8) : null,
                        gradient: plan.isSubscribed ? null : const LinearGradient(colors: [Color(0xFFFF609D), Color(0xFFFF7A06)]),
                      ),
                      child: Center(
                        child: Text(
                          plan.isSubscribed ? "Subscribed" : "Subscribe",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
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

class ExactVisualWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // ১. সবচেয়ে নিচের স্তর (Layer 1 - এটি ডানে সবচেয়ে বেশি নিচে নামবে)
    Paint p1 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.bottomRight,
        colors: [Color.fromARGB(255, 239, 109, 159), Color.fromARGB(255, 246, 158, 111)], 
      ).createShader(rect);
    
    Path path1 = Path();
    path1.lineTo(0, size.height * 0.45); 
    path1.cubicTo(
      size.width * -0.3, size.height * -0.01,  
      size.width * 0.8, size.height * 0.6,  
      size.width, size.height * 1.0,       
    );
    path1.lineTo(size.width, 0);
    path1.close();
    canvas.drawPath(path1, p1);

    Paint p2 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF718B), Color.fromARGB(255, 250, 132, 81)],
      ).createShader(rect);

    Path path2 = Path();
    path2.lineTo(0, size.height * 0.3); 
    path2.cubicTo(
      size.width * -0.20, size.height * 0.01, 
      size.width * 0.7, size.height * 0.4, 
      size.width, size.height * 0.8,
    );
    path2.lineTo(size.width, 0);
    path2.close();
    canvas.drawPath(path2, p2);

  
    Paint p3 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF8199), Color.fromARGB(255, 255, 142, 98)],
      ).createShader(rect);

    Path path3 = Path();
    path3.lineTo(0, size.height * 0.15); 
    path3.cubicTo(
      size.width * -0.20, size.height * 0.01, 
      size.width * 0.6, size.height * 0.1, 
      size.width, size.height * 0.55,
    );
    path3.lineTo(size.width, 0);
    path3.close();
    canvas.drawPath(path3, p3);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// --- Detail Page (No Change) ---
class SubscriptionDetailPage extends StatelessWidget {
  final SubscriptionPlan plan;
  const SubscriptionDetailPage({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.orange, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Subscription', 
          style: TextStyle(color: Colors.orange, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SubscriptionCard(plan: plan, isDetailPage: true),
      ),
    );
  }
}