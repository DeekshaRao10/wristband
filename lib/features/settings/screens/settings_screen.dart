import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          "Settings",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ACCOUNT
          const Text(
            "Account",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          _settingsTile(
            icon: Icons.person,
            title: "My Profile",
            subtitle: user?.email ?? "",
            onTap: () {
              // We will connect ProfileScreen next
            },
          ),

          _settingsTile(
            icon: Icons.lock,
            title: "Change Password",
            subtitle: "Update your account password",
            onTap: () {
              // We will add this next
            },
          ),

          const SizedBox(height: 24),

          // SAFEBAND
          const Text(
            "SafeBand",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          _settingsTile(
            icon: Icons.watch,
            title: "Device Settings",
            subtitle: "Manage your SafeBand",
            onTap: () {
              // Connect DeviceSettingsScreen
            },
          ),

          _settingsTile(
            icon: Icons.medical_information,
            title: "Medical Information",
            subtitle: "Wearer health and emergency information",
            onTap: () {
              // Add later
            },
          ),

          _settingsTile(
            icon: Icons.wifi,
            title: "WiFi Settings",
            subtitle: "Change SafeBand WiFi connection",
            onTap: () {
              // Reuse BLE WiFi provisioning later
            },
          ),

          const SizedBox(height: 24),

          // ALERTS
          const Text(
            "Alerts",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          _settingsTile(
            icon: Icons.notifications,
            title: "Alert Settings",
            subtitle: "Manage health and emergency alerts",
            onTap: () {
              // Connect AlertSettingsScreen
            },
          ),

          const SizedBox(height: 24),

          // ACCOUNT ACTIONS
          _settingsTile(
            icon: Icons.logout,
            title: "Logout",
            subtitle: "Sign out of SafeBand",
            onTap: () async {
              await FirebaseAuth.instance.signOut();

              // We'll connect this safely
              // to LoginScreen after testing.
            },
          ),
        ],
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              AppColors.primary.withValues(
            alpha: 0.1,
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: onTap,
      ),
    );
  }
}