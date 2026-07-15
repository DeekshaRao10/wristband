import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../../pairing/screens/pair_scan_screen.dart';

class FamilyMembersScreen extends StatelessWidget {
  final String familyId;
  final String familyName;
  final String inviteCode;

  const FamilyMembersScreen({
    super.key,
    required this.familyId,
    required this.familyName,
    required this.inviteCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Family Members",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius:
                    BorderRadius.circular(20),
              ),

              child: Column(
                children: [
                  const Icon(
                    Icons.groups,
                    color: AppColors.primary,
                    size: 50,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    familyName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    "Invite Code: $inviteCode",
                    style: const TextStyle(
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Members",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 15),

            Expanded(
              child:
                  StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore
                    .instance
                    .collection('families')
                    .doc(familyId)
                    .collection('members')
                    .snapshots(),

                builder:
                    (context, snapshot) {
                  if (snapshot
                          .connectionState ==
                      ConnectionState
                          .waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  if (!snapshot.hasData ||
                      snapshot
                          .data!
                          .docs
                          .isEmpty) {
                    return const Center(
                      child: Text(
                        "No family members found",
                      ),
                    );
                  }

                  final members =
                      snapshot.data!.docs;

                  return ListView.builder(
                    itemCount:
                        members.length,

                    itemBuilder:
                        (context, index) {
                      final member =
                          members[index]
                                  .data()
                              as Map<String,
                                  dynamic>;

                      return _MemberCard(
                        name:
                            member['name'] ??
                                'Unknown',

                        role:
                            member['role'] ??
                                'Member',
                      );
                    },
                  );
                },
              ),
            ),

            PrimaryButton(
              text: "Add Band",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const PairScanScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final String name;
  final String role;

  const _MemberCard({
    required this.name,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius:
            BorderRadius.circular(16),
      ),

      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor:
                AppColors.primary,
            child: Icon(
              Icons.person,
              color: AppColors.white,
            ),
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
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                Text(
                  role,
                  style: const TextStyle(
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}