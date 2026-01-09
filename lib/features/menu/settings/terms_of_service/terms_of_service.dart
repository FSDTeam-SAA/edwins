import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top AppBar Section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFFFF7F32), // Orange tone
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Terms of service",
                    style: TextStyle(
                      color: Color(0xFFFF7F32),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Text(
                  """
By accessing or using, you agree to be bound by these Terms and Conditions, confirming that the information you provide is accurate and that you are responsible for all activities conducted under your account.

All educational materials, features, and intellectual property within the App are owned by Tully or its licensors, and you may not reproduce, distribute, modify, or misuse any content or attempt to interfere with the App’s functionality. If you submit any content, you affirm that it does not violate any laws or rights and you grant the Company permission to use it solely to operate and improve the App. You consent to the collection and processing of personal data in accordance with our Privacy Policy. Paid features or subscriptions, where applicable, are non-refundable except as required by law and may renew automatically unless cancel.

The App is provided as is, and the Company is not liable for service interruptions, data loss, or damages arising from use. The Company may update these Terms or terminate access for violations at its discretion, and continued use constitutes acceptance of any changes.
                  """,
                  style: _textStyle(),
                ),
              ),
            ),
          ],
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
