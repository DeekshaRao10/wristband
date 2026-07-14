import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../services/family_service.dart';
import 'package:pinput/pinput.dart';

class JoinFamilyScreen extends StatefulWidget {
  const JoinFamilyScreen({super.key});

  @override
  State<JoinFamilyScreen> createState() =>
      _JoinFamilyScreenState();
}

class _JoinFamilyScreenState
    extends State<JoinFamilyScreen> {
  final TextEditingController codeController =
      TextEditingController();

  Map<String, dynamic>? familyData;

  bool loading = false;

  Future<void> searchFamily() async {
    if (codeController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Enter a valid 6-digit code",
          ),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    final result =
        await FamilyService().getFamilyByCode(
      codeController.text.trim(),
    );

    setState(() {
      familyData = result;
      loading = false;
    });

    if (result == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Invalid Invite Code",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          children: [
            const SizedBox(height: 20),

            const Text(
              "Join your family",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Enter the 6-digit invite code provided by your family organizer",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.grey,
              ),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,

              decoration: InputDecoration(
                hintText: "Enter Code",
                counterText: "",
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),

              onChanged: (_) {
                if (codeController.text.length == 6) {
                  searchFamily();
                }
              },
            ),

            const SizedBox(height: 30),

            if (loading)
              const CircularProgressIndicator(),

            if (familyData != null)
              Container(
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius:
                      BorderRadius.circular(16),
                ),

                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          AppColors.primary,
                      child: const Icon(
                        Icons.groups,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "You're joining",
                            style: TextStyle(
                              color: AppColors.grey,
                            ),
                          ),

                          Text(
                            familyData![
                                'familyName'],
                            style:
                                const TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          const Text(
                            "Family",
                            style: TextStyle(
                              color:
                                  AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const Spacer(),

            if (familyData != null)
              PrimaryButton(
                text: "Confirm",
                onPressed: () {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Family Joined Successfully",
                      ),
                    ),
                  );

                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}