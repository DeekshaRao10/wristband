import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../pairing/screens/pair_scan_screen.dart';
import '../../family/screens/family_members_screen.dart';
import 'band_detail_screen.dart';
import '../../../services/alert_listener.dart';
import '../../emergency/screens/emergency_screen.dart';
import '../../settings/screens/settings_screen.dart';

const String _rtdbUrl =
    'https://safeband-a3b89-default-rtdb.asia-southeast1.firebasedatabase.app';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AlertListener _alertListener = AlertListener();
  bool _isListening = false;

  void _startAlertListener(String bandId) {
    if (_isListening) return;

    _isListening = true;

    _alertListener.startListening(
      bandId: bandId,
      onEmergency: (alertData) {
        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmergencyScreen(
              bandId: bandId,
              alertData: alertData,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _alertListener.stopListening();
    super.dispose();
  }

  /// Loads the signed-in user's familyId, then the family's name — used
  /// for the "Smith Family" header instead of a generic title.
  Future<Map<String, String>> _loadFamilyInfo(String uid) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    final familyId = userDoc.data()?['familyId'] ?? '';

    if (familyId.isEmpty) {
      return {'familyId': '', 'familyName': ''};
    }

    final familyDoc = await FirebaseFirestore.instance
        .collection('families')
        .doc(familyId)
        .get();

    return {
      'familyId': familyId,
      'familyName': familyDoc.data()?['familyName'] ?? 'Family',
    };
  }

  Future<void> _goToFamilyScreen(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    final familyId = userDoc['familyId'];

    final familyDoc = await FirebaseFirestore.instance
        .collection('families')
        .doc(familyId)
        .get();

    if (!context.mounted) return;

    if (!familyDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Family not found")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FamilyMembersScreen(
          familyId: familyId,
          familyName: familyDoc.get('familyName'),
          inviteCode: familyDoc.get('inviteCode'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<Map<String, String>>(
          future: _loadFamilyInfo(user!.uid),
          builder: (context, familySnapshot) {
            if (!familySnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final familyId = familySnapshot.data!['familyId'] ?? '';
            final familyName = familySnapshot.data!['familyName'] ?? 'Family';

            return Column(
              children: [
                _DashboardHeader(familyName: familyName),

                Expanded(
                  child: familyId.isEmpty
                      ? const Center(child: Text('No family joined yet'))
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('bands')
                                .where('familyId', isEqualTo: familyId)
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
                                    const Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Center(
                                        child: Text("No bands added yet"),
                                      ),
                                    ),
                                    _AddBandCard(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const PairScanScreen(),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }

                              final bands = snapshot.data!.docs;

                              if (bands.isNotEmpty && !_isListening) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (!mounted) return;

                                  final bandData = bands.first.data()
                                      as Map<String, dynamic>;

                                  final deviceId = bandData['deviceId'];

                                  _startAlertListener(deviceId);
                                });
                              }

                              return ListView.builder(
                                itemCount: bands.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == bands.length) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(top: 4, bottom: 16),
                                      child: _AddBandCard(
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const PairScanScreen(),
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  final bandDoc = bands[index];
                                  final band =
                                      bandDoc.data() as Map<String, dynamic>;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _BandOverviewCard(
                                      bandId: bandDoc.id,
                                      deviceId: band['deviceId'] ?? '',
                                      name: band['wearerName'] ?? '',
                                      steps: band['steps'] ?? 0,
                                      stepGoal: band['stepGoal'] ?? 5000,
                                      battery: band['battery'] ?? 100,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.mutedText,
        onTap: (index) async {
          if (index == 1) {
            await _goToFamilyScreen(context);
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: "Family"),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String familyName;

  const _DashboardHeader({required this.familyName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.family_restroom, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            familyName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("No new notifications")),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// One family member's card: photo, name, live status, live heart rate,
/// step gauge, and a sync/last-movement/battery footer.
class _BandOverviewCard extends StatelessWidget {
  final String bandId;
  final String deviceId;
  final String name;
  final int steps;
  final int stepGoal;
  final int battery;

  const _BandOverviewCard({
    required this.bandId,
    required this.deviceId,
    required this.name,
    required this.steps,
    required this.stepGoal,
    required this.battery,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BandDetailScreen(bandId: bandId),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _LiveBandStats(
          deviceId: deviceId,
          builder: (context, heartRate, fallDetected, lastSyncText) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.background,
                      child: Icon(Icons.person, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: fallDetected
                                    ? AppColors.danger
                                    : AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                fallDetected ? "Fall Detected" : "All is well",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: fallDetected
                                      ? AppColors.danger
                                      : AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.mutedText),
                  ],
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.favorite_border,
                                color: AppColors.danger, size: 18),
                            const SizedBox(height: 4),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: heartRate > 0 ? "$heartRate" : "--",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.black,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: " BPM",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              width: 50,
                              height: 26,
                              child: CustomPaint(
                                painter: _GaugePainter(
                                  progress: stepGoal > 0
                                      ? (steps / stepGoal).clamp(0.0, 1.0)
                                      : 0.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatSteps(steps),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.sync,
                                  size: 12, color: AppColors.mutedText),
                              const SizedBox(width: 4),
                              Text(
                                "Synced $lastSyncText",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.mutedText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          // No accelerometer/motion field in the firmware
                          // payload yet — reusing the same upload
                          // timestamp here until real motion tracking
                          // exists, same as on the Band Detail screen.
                          Row(
                            children: [
                              const Icon(Icons.timeline,
                                  size: 12, color: AppColors.mutedText),
                              const SizedBox(width: 4),
                              Text(
                                "Last movement $lastSyncText",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "$battery%",
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.battery_std,
                            size: 14,
                            color: battery > 20
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _formatSteps(int steps) {
  if (steps >= 1000) {
    return "${(steps / 1000).toStringAsFixed(1)}k";
  }
  return "$steps";
}

/// Streams bands/{deviceId} from RTDB and exposes heartRate, fallDetected
/// and a human-readable "X ago" string derived from lastUpdated — the
/// same live source the Band Detail screen uses, so the numbers agree.
class _LiveBandStats extends StatelessWidget {
  final String deviceId;
  final Widget Function(
    BuildContext context,
    int heartRate,
    bool fallDetected,
    String lastSyncText,
  ) builder;

  const _LiveBandStats({required this.deviceId, required this.builder});

  @override
  Widget build(BuildContext context) {
    if (deviceId.isEmpty) {
      return builder(context, 0, false, 'Unknown');
    }

    final ref = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: _rtdbUrl,
    ).ref('bands/$deviceId');

    return StreamBuilder<DatabaseEvent>(
      stream: ref.onValue,
      builder: (context, snapshot) {
        int heartRate = 0;
        bool fallDetected = false;
        String lastSyncText = 'Unknown';

        final value = snapshot.data?.snapshot.value;

        if (value is Map) {
          final data = Map<String, dynamic>.from(value);

          heartRate = (data['heartRate'] as num?)?.toInt() ?? 0;
          fallDetected = data['fallDetected'] == true;

          final lastUpdated = (data['lastUpdated'] as num?)?.toInt();

          if (lastUpdated != null) {
            final nowEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            final diff = nowEpoch - lastUpdated;

            if (diff < 60) {
              lastSyncText = diff <= 2 ? 'just now' : '${diff}s ago';
            } else if (diff < 3600) {
              lastSyncText = '${diff ~/ 60}m ago';
            } else {
              lastSyncText = '${diff ~/ 3600}h ago';
            }
          }
        }

        return builder(context, heartRate, fallDetected, lastSyncText);
      },
    );
  }
}

class _AddBandCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddBandCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary, width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(.12),
              child: const Icon(Icons.add, color: AppColors.primary),
            ),
            const SizedBox(height: 10),
            const Text(
              "Add band",
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Decorative semicircle "speedometer" gauge for the steps box — filled
/// proportionally to steps/stepGoal.
class _GaugePainter extends CustomPainter {
  final double progress;

  const _GaugePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);

    final bgPaint = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, math.pi, math.pi, false, bgPaint);
    canvas.drawArc(rect, math.pi, math.pi * progress, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
