import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/app_theme.dart';

class BandDetailScreen extends StatelessWidget {
  final String bandId;

  const BandDetailScreen({
    super.key,
    required this.bandId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bands')
            .doc(bandId)
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData ||
              !snapshot.data!.exists ||
              snapshot.data!.data() == null) {
            return const Center(
              child: Text("Band not found"),
            );
          }

          final band =
              snapshot.data!.data()
                  as Map<String, dynamic>;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Row(
                    children: [

                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back),
                      ),

                      Expanded(
                        child: Text(
                          band['wearerName'] ?? '',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const Icon(Icons.settings),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [

                          const Chip(
                            avatar: Icon(
                              Icons.circle,
                              color: Colors.green,
                              size: 10,
                            ),
                            label: Text("Band Online"),
                          ),

                          const SizedBox(height: 15),

                          Text(
                            "${band['wearerName']} is doing well",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            "Battery: ${band['battery'] ?? 100}%"
                          ),

                          Text(
                            "Last Sync: ${band['lastSync'] ?? 'Just now'}",
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}