import 'package:flutter/material.dart';
import 'package:language_app/features/menu/settings/settings.dart';
import 'package:language_app/features/menu/subscription/subcriptions.dart';
import 'package:language_app/features/menu/edit_profile/profile_view.dart';
import 'package:language_app/features/menu/logout/logout_screen.dart';

class MenuView extends StatelessWidget {
  const MenuView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFFFF8000),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Menu",
          style: TextStyle(
            color: Color(0xFFFF8000),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // 1. Main Settings Group
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0), // Light cream background
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.edit_outlined,
                    label: "Edit Profile",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileView(),
                        ),
                      );
                    },
                  ),
                  const Divider(
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                    color: Color(0xFFE0E0E0),
                  ),
                  _buildMenuItem(
                    icon: Icons.monetization_on_outlined,
                    label: "Subscription",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SubscriptionMainPage()),
                      );
                    },
                  ),
                  const Divider(
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                    color: Color(0xFFE0E0E0),
                  ),
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    label: "Settings",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Logout Action
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(15),
              ),
              child: _buildMenuItem(
                icon: Icons.logout,
                label: "Log out",
                onTap: () {
                  // Handle logout logic
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LogoutScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.black87, size: 22),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
