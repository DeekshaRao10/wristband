import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import 'dart:io';
import '../../bands/screens/dashboard_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../../bands/services/band_service.dart';

class PairSetupScreen extends StatefulWidget {
  const PairSetupScreen({super.key});

  @override
  State<PairSetupScreen> createState() =>
      _PairSetupScreenState();
}

class _PairSetupScreenState
    extends State<PairSetupScreen> {

  String selectedWearer = "";

  bool showProfileForm = false;

  String? selectedBloodGroup;
  File? profileImage;

final ImagePicker picker = ImagePicker();

  final wifiController =
      TextEditingController();

  final wifiPasswordController =
      TextEditingController();

  final fullNameController =
      TextEditingController();

  final ageController =
      TextEditingController();

  final emailController =
      TextEditingController();

  final userPasswordController =
      TextEditingController();

  final addressController =
      TextEditingController();

  final medicalController =
      TextEditingController();

  final doctorPhoneController =
      TextEditingController();

  final bandNameController =
      TextEditingController();
      Future<void> pickProfileImage() async {
  final XFile? image =
      await picker.pickImage(
    source: ImageSource.gallery,
  );

  if (image != null) {
    setState(() {
      profileImage = File(image.path);
    });
  }
}

Future<void> finishSetup() async {
      if (wifiController.text.trim().isEmpty ||
        wifiPasswordController.text.trim().isEmpty ||
        fullNameController.text.trim().isEmpty ||
        ageController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty ||
        selectedBloodGroup == null ||
        medicalController.text.trim().isEmpty ||
        bandNameController.text.trim().isEmpty) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Required field is missing",
          ),
        ),
      );

      return;
    }
    await BandService().createBand(
  bandName:
      bandNameController.text.trim(),

  wearerName:
      fullNameController.text.trim(),

  age: int.parse(
    ageController.text.trim(),
  ),

  address:
      addressController.text.trim(),

  bloodGroup:
      selectedBloodGroup!,

  medicalConditions:
      medicalController.text.trim(),

  doctorPhone:
      doctorPhoneController.text.trim(),
);

if (!mounted) return;

Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) =>
        const DashboardScreen(),
  ),
);

    if (selectedWearer == "new") {
      if (emailController.text.trim().isEmpty ||
          userPasswordController.text
              .trim()
              .isEmpty) {

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Required field is missing",
            ),
          ),
        );

        return;
      }
    }

    Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) =>
        const DashboardScreen(),
  ),
);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        title: const Text("Setup"),
        backgroundColor:
            AppColors.background,
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),

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
            AppColors.primary.withOpacity(.15),
        child: const Icon(
          Icons.watch,
          size: 40,
          color: AppColors.primary,
        ),
      ),

      const SizedBox(height: 15),

      const Text(
        "Band online!",
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 8),

      const Text(
        "Your band is connected. Let's finish setting it up.",
        textAlign: TextAlign.center,
      ),
    ],
  ),
),

const SizedBox(height: 30),

// NETWORK SETTINGS

Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          "📶 Network Settings",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        TextField(
          controller: wifiController,
          decoration:
              const InputDecoration(
            labelText: "WiFi Network *",
            border:
                OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 12),

        TextField(
          controller:
              wifiPasswordController,
          obscureText: true,
          decoration:
              const InputDecoration(
            labelText: "Password *",
            border:
                OutlineInputBorder(),
          ),
        ),
      ],
    ),
  ),
),

const SizedBox(height: 20),

// WHO WEARS THIS BAND

Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        const Text(
          "Who wears this band?",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        Row(
  children: [

    GestureDetector(
      onTap: () {
        setState(() {
          selectedWearer = "user";
          showProfileForm = true;
        });
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color:
              selectedWearer == "user"
                  ? AppColors.primary
                  : Colors.white,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary,
          ),
        ),
        child: Text(
          "You",
          style: TextStyle(
            color:
                selectedWearer == "user"
                    ? Colors.white
                    : Colors.black,
          ),
        ),
      ),
    ),

    const SizedBox(width: 12),

    GestureDetector(
      onTap: () {
        setState(() {
          selectedWearer = "new";
          showProfileForm = true;
        });
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color:
              selectedWearer == "new"
                  ? AppColors.primary
                  : Colors.white,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary,
          ),
        ),
        child: Text(
          "+ New Profile",
          style: TextStyle(
            color:
                selectedWearer == "new"
                    ? Colors.white
                    : Colors.black,
          ),
        ),
      ),
    ),
  ],
),

      ],
    ),
  ),
),

if (showProfileForm) ...[

  const SizedBox(height: 20),

  Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [

          CircleAvatar(
  radius: 40,
  backgroundColor: Colors.grey.shade200,
  backgroundImage:
      profileImage != null
          ? FileImage(profileImage!)
          : null,
  child: profileImage == null
      ? const Icon(
          Icons.person,
          size: 40,
        )
      : null,
),
          const SizedBox(width: 20),

Expanded(
  child: OutlinedButton.icon(
    onPressed: pickProfileImage,
    icon: const Icon(
      Icons.upload,
    ),
    label: const Text(
      "Upload Profile",
    ),
  ),
),
        ],
      ),
    ),
  ),

  const SizedBox(height: 20),

  TextField(
    controller: fullNameController,
    decoration: const InputDecoration(
      labelText: "Full Name *",
      border: OutlineInputBorder(),
    ),
  ),

  const SizedBox(height: 12),

  TextField(
    controller: ageController,
    keyboardType: TextInputType.number,
    decoration: const InputDecoration(
      labelText: "Age *",
      border: OutlineInputBorder(),
    ),
  ),

  const SizedBox(height: 12),

  if (selectedWearer == "new") ...[

    TextField(
      controller: emailController,
      decoration: const InputDecoration(
        labelText: "Email *",
        border: OutlineInputBorder(),
      ),
    ),

    const SizedBox(height: 12),

    TextField(
      controller: userPasswordController,
      obscureText: true,
      decoration: const InputDecoration(
        labelText: "Password *",
        border: OutlineInputBorder(),
      ),
    ),

    const SizedBox(height: 12),
  ],

  TextField(
    controller: addressController,
    maxLines: 2,
    decoration: const InputDecoration(
      labelText: "Home Address *",
      border: OutlineInputBorder(),
    ),
  ),
],


           const SizedBox(height: 20),

// MEDICAL CARD

Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        const Text(
          "🩺 Medical Card",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        DropdownButtonFormField<String>(
          value: selectedBloodGroup,
          decoration:
              const InputDecoration(
            labelText: "* Blood Group",
            border:
                OutlineInputBorder(),
          ),
          items: const [

            DropdownMenuItem(
              value: "A+",
              child: Text("A+"),
            ),

            DropdownMenuItem(
              value: "A-",
              child: Text("A-"),
            ),

            DropdownMenuItem(
              value: "B+",
              child: Text("B+"),
            ),

            DropdownMenuItem(
              value: "B-",
              child: Text("B-"),
            ),

            DropdownMenuItem(
              value: "AB+",
              child: Text("AB+"),
            ),

            DropdownMenuItem(
              value: "AB-",
              child: Text("AB-"),
            ),

            DropdownMenuItem(
              value: "O+",
              child: Text("O+"),
            ),

            DropdownMenuItem(
              value: "O-",
              child: Text("O-"),
            ),
          ],
          onChanged: (value) {
            setState(() {
              selectedBloodGroup =
                  value;
            });
          },
        ),

        const SizedBox(height: 12),

        TextField(
          controller:
              medicalController,
          maxLines: 3,
          decoration:
              const InputDecoration(
            labelText:
                "Medical Conditions *",
            border:
                OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 12),

        TextField(
          controller:
              doctorPhoneController,
          keyboardType:
              TextInputType.phone,
          decoration:
              const InputDecoration(
            labelText:
                "Doctor Phone (Optional)",
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
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        const Text(
          "⌚ Band Details",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        TextField(
          controller: bandNameController,
          decoration:
              const InputDecoration(
            labelText: "Band Name *",
            hintText: "Mom's Watch",
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
  onPressed: finishSetup,
),

const SizedBox(height: 30),

          ],
        ),
      ),
    );
  }
}