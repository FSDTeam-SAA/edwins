import 'package:flutter/material.dart';
import 'dart:async';

import 'package:language_app/Screens/onbording_screen.dart';

class LunguluApp extends StatelessWidget {
  const LunguluApp({super.key});

  @override
  Widget build(BuildContext context) {
    // We remove MaterialApp and just return the SplashScreen.
    // This allows it to use the routes and theme from app.dart
    return const SplashScreen();
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        // This will now look at the Route Table in app.dart correctly
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const OnboardingScreen(), 
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50.0),
          child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
        ),
      ),
    );
  }
}