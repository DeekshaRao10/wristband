import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';

class PairSetupScreen extends StatelessWidget {
  const PairSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("Setup"),
        backgroundColor: AppColors.background,
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          children: [
            const SizedBox(height: 20),

            const CircleAvatar(
              radius: 40,
              child: Icon(
                Icons.watch,
                size: 40,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Band online!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Your band is connected successfully.",
              textAlign: TextAlign.center,
            ),

            const Spacer(),

            PrimaryButton(
              text: "Continue Setup",
              onPressed: () {
                // Next:
                // WiFi
                // Member Profile
                // Medical Card
              },
            ),
          ],
        ),
      ),
    );
  }
}