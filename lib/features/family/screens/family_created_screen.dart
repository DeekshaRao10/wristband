import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import 'family_choice_screen.dart';

class FamilyCreatedScreen extends StatelessWidget {
  final String familyName;
  final String inviteCode;

  const FamilyCreatedScreen({
    super.key,
    required this.familyName,
    required this.inviteCode,
  });

  Future<void> _shareCode() async {
    await SharePlus.instance.share(
      ShareParams(
        text:
            'Join my SafeBand family!\n\nFamily: $familyName\nInvite Code: $inviteCode',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            children: [
              const SizedBox(height: 40),

              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.white,
                  size: 40,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Family Created!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Share this code so family members can join the $familyName.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.grey,
                ),
              ),

              const SizedBox(height: 30),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),

                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                ),

                child: Column(
                  children: [
                    const Text(
                      "INVITE CODE",
                      style: TextStyle(
                        color: AppColors.grey,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      inviteCode,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _shareCode,
                icon: const Icon(Icons.share),
                label: const Text("Share Code"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize:
                      const Size(double.infinity, 50),
                ),
              ),

              const SizedBox(height: 20),

              PrimaryButton(
                text: "Add a Band",
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Band setup will be added next.",
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 15),

              OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text(
                        "Invite Members",
                      ),
                      content: Text(
                        "Share this invite code:\n\n$inviteCode",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _shareCode();
                          },
                          child: const Text(
                            "Share",
                          ),
                        ),
                      ],
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize:
                      const Size(double.infinity, 50),
                ),
                child: const Text(
                  "Invite Members",
                ),
              ),

              const Spacer(),

              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const FamilyChoiceScreen(),
                    ),
                    (route) => false,
                  );
                },
                child: const Text(
                  "Go to Home",
                  style: TextStyle(
                    color: AppColors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}