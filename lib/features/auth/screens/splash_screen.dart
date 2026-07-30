import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/screens/login_screen.dart';
import '../../bands/screens/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>//Creates the state object that contains the screen logic.
      _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();


    Timer(
      const Duration(seconds: 3),
      () async {
        if (!mounted) return;

        // Already signed in (and never logged out) -> skip straight to
        // Home Dashboard. FirebaseAuth.instance.currentUser stays set
        // across app restarts until signOut() is explicitly called
        // (that's what Settings' "Log Out" button does), so this is a
        // reliable "is this a returning, still-logged-in user" check.
        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
          return;
        }

        // Not signed in right now — but have they HAD an account on this
        // device before (they logged out), or is this a genuinely new
        // user who's never signed up? Firebase forgets currentUser the
        // moment signOut() runs, so that distinction has to be tracked
        // separately: login_screen.dart and signup_screen.dart both set
        // this "has_account" flag the moment a login/signup actually
        // succeeds, and it's never cleared on logout.
        final prefs = await SharedPreferences.getInstance();
        final hasAccount = prefs.getBool('has_account') ?? false;

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                hasAccount ? LoginScreen() : const OnboardingScreen(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    backgroundColor: AppColors.background,

      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [

            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF0F7A7B),
                borderRadius:
                    BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withOpacity(.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.health_and_safety,
                color: Colors.white,
                size: 45,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "SafeBand",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Safety on their wrist",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}