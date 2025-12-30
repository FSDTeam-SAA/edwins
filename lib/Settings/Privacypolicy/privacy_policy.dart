import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Navigation Header
              GestureDetector(
                onTap: () {
                  // Settings page-e niye jabe
                  Navigator.pop(context);
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // First Paragraph
              Text(
                "You agree that we may collect and use certain information to operate and improve the app’s learning services, including personal details such as your name, email, profile information, and any optional content you upload, as well as usage data like device information, app interactions, progress records, and activity logs.",
                style: _textStyle(),
              ),
              const SizedBox(height: 24),

              // Second Paragraph
              Text(
                "We use this information to create and manage your account, personalize your learning experience, track your progress, improve app features, provide customer support, maintain security, and ensure a smooth and safe learning environment. We do not sell your personal information, and we only share data with trusted service providers who support app operations, or with legal authorities if required by law. Your data is protected through reasonable security measures, although no system can guarantee complete security. You may request to access, update, or delete your data at any time, or close your account by contacting us at [Your Email]. The app is not intended for children below the minimum legal age, and we do not knowingly collect information from them without parental consent. We may update this Privacy Policy from time to time, and continuing to use the app means you accept any changes.",
                style: _textStyle(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Exact style as per screenshot
  TextStyle _textStyle() {
    return const TextStyle(
      color: Color.fromARGB(255, 50, 50, 50), // Slightly muted grey color
      fontSize: 15.5,
      height: 1.5,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
    );
  }
}
