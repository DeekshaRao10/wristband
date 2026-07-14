import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';

import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import '../../family/screens/family_choice_screen.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Column(
            children: [
              const SizedBox(height: 60),

              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.health_and_safety,
                  color: AppColors.white,
                  size: 40,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Welcome Back",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Login to continue",
                style: TextStyle(
                  color: AppColors.grey,
                ),
              ),

              const SizedBox(height: 30),

              AppTextField(
                controller: emailController,
                hintText: "Email",
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              AppTextField(
                controller: passwordController,
                hintText: "Password",
                prefixIcon: Icons.lock,
                obscureText: true,
              ),

              const SizedBox(height: 10),

              Align(
  alignment: Alignment.centerRight,
  child: TextButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ForgotPasswordScreen(),
        ),
      );
    },
    child: const Text(
      "Forgot Password?",
      style: TextStyle(
        color: AppColors.primary,
      ),
    ),
  ),
),

              const SizedBox(height: 20),

              PrimaryButton(
                text: "Login",
                onPressed: () async {
                  try {
                    await AuthService().login(
                      email: emailController.text.trim(),
                      password: passwordController.text.trim(),
                    );

                   if (context.mounted) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const FamilyChoiceScreen(),
    ),
  );
}
                    
                  } on FirebaseAuthException {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Invalid email or password",
                        ),
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account?",
                    style: TextStyle(
                      color: AppColors.black,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SignupScreen(),
                      ),
                    ),
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}