import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';

class PairSetupScreen extends StatelessWidget {
  PairSetupScreen({super.key});

  final TextEditingController wifiController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController fullNameController =
      TextEditingController();

  final TextEditingController ageController =
      TextEditingController();

  final TextEditingController addressController =
      TextEditingController();

  final TextEditingController medicalController =
      TextEditingController();

  final TextEditingController doctorPhoneController =
      TextEditingController();

  final TextEditingController bandNameController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("Setup"),
        backgroundColor: AppColors.background,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor:
                        AppColors.primary
                            .withOpacity(.15),
                    child: const Icon(
                      Icons.watch,
                      size: 40,
                      color:
                          AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    "Band online!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Your band is connected. Let's finish setting it up.",
                    textAlign:
                        TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // NETWORK SETTINGS

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    const Text(
                      "📶 Network Settings",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    TextField(
                      controller:
                          wifiController,
                      decoration:
                          const InputDecoration(
                        labelText:
                            "WiFi Network",
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    TextField(
                      controller:
                          passwordController,
                      obscureText: true,
                      decoration:
                          const InputDecoration(
                        labelText:
                            "Password",
                        border:
                            OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // MEMBER PROFILE

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    const Text(
                      "👤 Who wears this band?",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    TextField(
                      controller:
                          fullNameController,
                      decoration:
                          const InputDecoration(
                        labelText:
                            "Full Name",
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    TextField(
                      controller:
                          ageController,
                      keyboardType:
                          TextInputType
                              .number,
                      decoration:
                          const InputDecoration(
                        labelText:
                            "Age",
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    TextField(
                      controller:
                          addressController,
                      maxLines: 2,
                      decoration:
                          const InputDecoration(
                        labelText:
                            "Home Address",
                        border:
                            OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // MEDICAL CARD

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    const Text(
                      "🩺 Medical Card",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    DropdownButtonFormField<
                        String>(
                      decoration:
                          const InputDecoration(
                        border:
                            OutlineInputBorder(),
                        labelText:
                            "Blood Group",
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "A+",
                          child:
                              Text("A+"),
                        ),
                        DropdownMenuItem(
                          value: "B+",
                          child:
                              Text("B+"),
                        ),
                        DropdownMenuItem(
                          value: "O+",
                          child:
                              Text("O+"),
                        ),
                        DropdownMenuItem(
                          value: "AB+",
                          child:
                              Text("AB+"),
                        ),
                        DropdownMenuItem(
                          value: "A-",
                          child:
                              Text("A-"),
                        ),
                        DropdownMenuItem(
                          value: "B-",
                          child:
                              Text("B-"),
                        ),
                        DropdownMenuItem(
                          value: "AB-",
                          child:
                              Text("AB-"),
                        ),
                        DropdownMenuItem(
                          value: "O-",
                          child:
                              Text("O-"),
                        ),
                      ],
                      onChanged: (_) {},
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    TextField(
                      controller:
                          medicalController,
                      maxLines: 3,
                      decoration:
                          const InputDecoration(
                        labelText:
                            "Medical Conditions",
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    TextField(
                      controller:
                          doctorPhoneController,
                      keyboardType:
                          TextInputType
                              .phone,
                      decoration:
                          const InputDecoration(
                        labelText:
                            "Doctor Phone",
                        border:
                            OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // BAND DETAILS

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    const Text(
                      "⌚ Band Details",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    TextField(
                      controller:
                          bandNameController,
                      decoration:
                          const InputDecoration(
                        labelText:
                            "Band Name",
                        hintText:
                            "Mom's Watch",
                        border:
                            OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            PrimaryButton(
              text: "Finish Setup",
              onPressed: () {
                ScaffoldMessenger.of(
                        context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Setup Completed",
                    ),
                  ),
                );

                // TODO:
                // Save to Firestore
                // Navigate Dashboard
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}