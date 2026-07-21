import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../pairing/screens/pair_scan_screen.dart';
import '../../family/screens/family_members_screen.dart';
import 'band_detail_screen.dart';
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          "Home Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              "My SafeBands",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

           Expanded(
  child: FutureBuilder<DocumentSnapshot>(
    future: FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get(),
    builder: (context, userSnapshot) {

      if (!userSnapshot.hasData) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      final userData =
          userSnapshot.data!.data()
              as Map<String, dynamic>;

     final familyId =
    userData['familyId'] ?? '';
    if (familyId.isEmpty) {
  return const Center(
    child: Text(
      'No family joined yet',
    ),
  );
}

      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bands')
            .where(
              'familyId',
              isEqualTo: familyId,
            )
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return ListView(
              children: [
                const Center(
                  child: Padding(
                    padding:
                        EdgeInsets.all(20),
                    child: Text(
                      "No bands added yet",
                    ),
                  ),
                ),
                _addBandCard(context),
              ],
            );
          }

          final bands =
              snapshot.data!.docs;

          return ListView.builder(
            itemCount:
                bands.length + 1,
            itemBuilder:
                (context, index) {

              if (index ==
                  bands.length) {
                return Padding(
                  padding:
                      const EdgeInsets.only(
                    top: 12,
                  ),
                  child:
                      _addBandCard(
                    context,
                  ),
                );
              }

              final band =
                  bands[index].data()
                      as Map<String,
                          dynamic>;

              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
               child: _bandCard(
  context: context,
  bandId: bands[index].id,
  name: band['wearerName'] ?? '',
  bpm: '${band['heartRate'] ?? 0}',
  steps: '${band['steps'] ?? 0}',
  bandName: band['bandName'] ?? '',
),
              );
            },
          );
        },
      );
    },
  ),
),
          ],
        ),
      ),
                
      bottomNavigationBar: BottomNavigationBar(
  currentIndex: 0,

  onTap: (index) async {

    if (index == 1) {

      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) return;

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      final familyId =
          userDoc['familyId'];

      final familyDoc =
          await FirebaseFirestore.instance
              .collection('families')
              .doc(familyId)
              .get();

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              FamilyMembersScreen(
            familyId: familyId,
            familyName:
                familyDoc['familyName'],
            inviteCode:
                familyDoc['inviteCode'],
          ),
        ),
      );
    }
  },

  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: "Home",
    ),

    BottomNavigationBarItem(
      icon: Icon(Icons.groups),
      label: "Family",
    ),

    BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: "Settings",
    ),
  ],
),
    );
  }
 Widget _bandCard({
  required BuildContext context,
  required String bandId,
  required String name,
  required String bpm,
  required String steps,
  required String bandName,
}) {
  return GestureDetector(
    onTap: () {

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BandDetailScreen(
            bandId: bandId,
          ),
        ),
      );

    },

    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            Row(
              children: [

                const CircleAvatar(
                  radius: 25,
                  child: Icon(Icons.person),
                ),

                const SizedBox(width: 12),

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

                      Text(
                        bandName,
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),

                    ],
                  ),
                ),

              ],
            ),

            const SizedBox(height: 15),

            Row(
              children: [

                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey,
                      ),
                    ),
                    child: Column(
                      children: [

                        const Icon(
                          Icons.favorite,
                          color: Colors.red,
                        ),

                        Text("$bpm BPM"),

                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey,
                      ),
                    ),
                    child: Column(
                      children: [

                        const Icon(
                          Icons.directions_walk,
                        ),

                        Text(steps),

                      ],
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
Widget _addBandCard(
  BuildContext context,
) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const PairScanScreen(),
        ),
      );
    },
    child: Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey,
        ),
      ),
      child: const Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          CircleAvatar(
            child: Icon(Icons.add),
          ),
          SizedBox(height: 10),
          Text("Add Band"),
        ],
      ),
    ),
  );
}
}