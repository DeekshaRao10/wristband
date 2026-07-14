import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';

class FamilyMembersScreen extends StatelessWidget {
  const FamilyMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Column(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.groups,
                  color: AppColors.white,
                  size: 45,
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Family Members",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Members currently in your SafeBand family group",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 30),

              _memberCard(
                name: "You",
                role: "Admin",
              ),

              const SizedBox(height: 12),

              _memberCard(
                name: "Father",
                role: "Member",
              ),

              const SizedBox(height: 12),

              _memberCard(
                name: "Mother",
                role: "Member",
              ),

              const SizedBox(height: 30),

              PrimaryButton(
                text: "Continue",
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Dashboard screen coming next",
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _memberCard({
    required String name,
    required String role,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),

      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor:
                AppColors.primary.withOpacity(0.1),
            child: const Icon(
              Icons.person,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  role,
                  style: const TextStyle(
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color:
                  AppColors.primary.withOpacity(0.1),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: Text(
              role,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}