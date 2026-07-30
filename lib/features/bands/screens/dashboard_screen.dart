import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/wearer_resolver.dart';
import '../../../core/widgets/local_avatar.dart';
import '../../pairing/screens/pair_scan_screen.dart';
import '../../family/screens/family_members_screen.dart';
import 'band_detail_screen.dart';
import '../../../services/alert_listener.dart';
import '../../emergency/screens/emergency_screen.dart';
import '../../settings/screens/settings_screen.dart';
import 'notifications_screen.dart';

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

  // Keeps the notification bell's badge in sync with the REAL current
  // fallDetected state — separate from AlertListener's onEmergency
  // below, which only fires once per rising edge (so it doesn't reopen
  // the Emergency screen repeatedly). This one just tracks true/false
  // continuously, so the bell reflects reality even if the Emergency
  // screen was already dismissed/never opened.
  bool _hasActiveAlert = false;
  StreamSubscription<DatabaseEvent>? _bellSub;

  // The Firestore doc for whichever alert is currently open (if any),
  // so the RTDB listener below knows which record to mark resolved
  // once fallDetected clears back to false.
  DocumentReference<Map<String, dynamic>>? _currentAlertDocRef;

  void _startAlertListener(String bandId) {
    if (_isListening) return;

    _isListening = true;

    _alertListener.startListening(
      bandId: bandId,
      onEmergency: (alertData) async {
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

        // Logs this alert to families/{familyId}/alerts so it shows up
        // on the real Notifications page — a genuine history, not just
        // a badge that vanishes the moment the alert resolves.
        try {
          final bandsSnap = await FirebaseFirestore.instance
              .collection('bands')
              .where('deviceId', isEqualTo: bandId)
              .limit(1)
              .get();

          if (bandsSnap.docs.isEmpty) {
            debugPrint(
                "Dashboard: alert not logged — no band doc found for deviceId=$bandId");
            return;
          }

          final band = bandsSnap.docs.first.data();
          final alertFamilyId = band['familyId']?.toString() ?? '';
          final wearerName = band['wearerName']?.toString() ?? 'Unknown';

          if (alertFamilyId.isEmpty) {
            debugPrint(
                "Dashboard: alert not logged — band ${bandsSnap.docs.first.id} has no familyId set");
            return;
          }

          debugPrint(
              "Dashboard: writing alert doc to families/$alertFamilyId/alerts");

          _currentAlertDocRef = await FirebaseFirestore.instance
              .collection('families')
              .doc(alertFamilyId)
              .collection('alerts')
              .add({
            'bandId': bandsSnap.docs.first.id,
            'deviceId': bandId,
            'wearerName': wearerName,
            // 'timestamp' is a server-resolved sentinel — it reads back
            // as null for a brief moment right after the write, which is
            // what made the Notifications screen show "Just now" instead
            // of a real time. 'clientTimestamp' is a plain value set the
            // instant the alert fires, so the exact time is there from
            // the very first frame it appears in the list.
            'timestamp': FieldValue.serverTimestamp(),
            'clientTimestamp': Timestamp.now(),
            'resolved': false,
          });
        } catch (e) {
          debugPrint("Dashboard: failed to log alert: $e");
        }
      },
    );

    final ref = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: _rtdbUrl,
    ).ref('bands/$bandId/fallDetected');

    _bellSub = ref.onValue.listen((event) {
      if (!mounted) return;

      final isFallActive = event.snapshot.value == true;

      setState(() {
        _hasActiveAlert = isFallActive;
      });

      if (!isFallActive && _currentAlertDocRef != null) {
        _currentAlertDocRef!.update({
          'resolved': true,
          'resolvedAt': FieldValue.serverTimestamp(),
        });
        _currentAlertDocRef = null;
      }
    });
  }

  @override
  void dispose() {
    _alertListener.stopListening();
    _bellSub?.cancel();
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
                _DashboardHeader(
                  familyName: familyName,
                  familyId: familyId,
                ),

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
                                    return _StaggeredFadeIn(
                                      index: index,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            top: 4, bottom: 16),
                                        child: _AddBandCard(
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const PairScanScreen(),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  final bandDoc = bands[index];
                                  final band =
                                      bandDoc.data() as Map<String, dynamic>;

                                  final rawWearerUid =
                                      (band['wearerUid'] ?? '').toString();

                                  return _StaggeredFadeIn(
                                    index: index,
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 14),
                                      // Bands created before the wearerUid
                                      // field existed (or where a separate
                                      // wearer account was created but never
                                      // linked back) need a one-time async
                                      // lookup to find who the real wearer
                                      // is — see wearer_resolver.dart. No
                                      // ownerId fallback here on purpose:
                                      // that caused "You" to show on every
                                      // band the admin owns, not just the
                                      // one they actually wear.
                                      child: FutureBuilder<String>(
                                        future: resolveWearerUid(
                                          bandId: bandDoc.id,
                                          rawWearerUid: rawWearerUid,
                                        ),
                                        initialData: rawWearerUid,
                                        builder: (context, wearerUidSnapshot) {
                                          return _BandOverviewCard(
                                            bandId: bandDoc.id,
                                            deviceId: band['deviceId'] ?? '',
                                            name: band['wearerName'] ?? '',
                                            wearerUid:
                                                wearerUidSnapshot.data ?? '',
                                            steps: band['steps'] ?? 0,
                                            stepGoal: band['stepGoal'] ?? 5000,
                                            battery: band['battery'] ?? 100,
                                          );
                                        },
                                      ),
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
      // Floating rounded pill instead of a flat edge-to-edge bar — lifts
      // off the background with its own shadow and margin, matching the
      // rounded-card language used everywhere else on this screen.
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BottomNavigationBar(
              currentIndex: 0,
              backgroundColor: AppColors.white,
              elevation: 0,
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
                BottomNavigationBarItem(
                    icon: Icon(Icons.groups), label: "Family"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.settings), label: "Settings"),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Time-of-day greeting ("Good morning" / "Good afternoon" / "Good
/// evening") — small personal touch that makes the dashboard feel
/// alive rather than a static label every time it's opened.
String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return "Good morning";
  if (hour < 17) return "Good afternoon";
  return "Good evening";
}

/// Curved gradient banner instead of a flat row on the plain
/// background — gives the dashboard a distinct identity at a glance
/// instead of looking like any other list screen.
class _DashboardHeader extends StatelessWidget {
  final String familyName;
  final String familyId;

  const _DashboardHeader({
    required this.familyName,
    required this.familyId,
  });

  @override
  Widget build(BuildContext context) {
    // Plain background (matches the rest of the page) instead of the
    // colored gradient banner — just the greeting/family name/bell,
    // no colored surface behind it.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.family_restroom,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        familyName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Real count badge — number of currently-unresolved fall
          // alerts for this family, straight from
          // families/{familyId}/alerts, not just an on/off dot. Updates
          // live: goes up the instant a new alert is logged, down the
          // instant one is marked resolved.
          StreamBuilder<QuerySnapshot>(
            stream: familyId.isEmpty
                ? null
                : FirebaseFirestore.instance
                    .collection('families')
                    .doc(familyId)
                    .collection('alerts')
                    .where('resolved', isEqualTo: false)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                // Surfaces a permissions/rules problem instead of just
                // quietly showing zero — if this fires, it's almost
                // certainly Firestore security rules blocking reads on
                // families/{familyId}/alerts (a brand-new collection),
                // not a data problem.
                debugPrint("Dashboard: bell badge stream error: ${snapshot.error}");
                return IconButton(
                  icon: const Icon(Icons.error_outline, color: Colors.orange),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Notifications error: ${snapshot.error}"),
                      ),
                    );
                  },
                );
              }

              final unresolvedCount = snapshot.data?.docs.length ?? 0;
              final hasActiveAlert = unresolvedCount > 0;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: Icon(
                      hasActiveAlert
                          ? Icons.notifications_active
                          : Icons.notifications_none,
                      color:
                          hasActiveAlert ? AppColors.danger : AppColors.black,
                    ),
                    onPressed: () {
                      if (familyId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("No new notifications")),
                        );
                        return;
                      }

                      // Opens the real Notifications page instead of a
                      // one-off snackbar — every fall alert ever logged
                      // for this family, so tapping the bell after a
                      // "Fall Detected" popup actually shows it there
                      // too.
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              NotificationsScreen(familyId: familyId),
                        ),
                      );
                    },
                  ),
                  if (hasActiveAlert)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(9),
                          border:
                              Border.all(color: AppColors.background, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          unresolvedCount > 9 ? '9+' : '$unresolvedCount',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
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
  final String wearerUid;
  final int steps;
  final int stepGoal;
  final int battery;

  const _BandOverviewCard({
    required this.bandId,
    required this.deviceId,
    required this.name,
    required this.wearerUid,
    required this.steps,
    required this.stepGoal,
    required this.battery,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = wearerUid.isNotEmpty &&
        wearerUid == FirebaseAuth.instance.currentUser?.uid;
    final displayName = isMe ? "You" : name;

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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
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
                    // Colored ring around the photo doubles as a
                    // status indicator at a glance (green = all well,
                    // red = fall detected) — same info as the dot/text
                    // below, just visible from across the room.
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: fallDetected
                              ? AppColors.danger
                              : AppColors.success,
                          width: 2.5,
                        ),
                      ),
                      // Shows the wearer's locally-saved photo if one
                      // exists (only on the same phone that saved it —
                      // photos aren't synced anywhere). Falls back to
                      // the plain icon otherwise, same as Family
                      // Management.
                      child: LocalAvatar(
                        photoKey: wearerUid,
                        radius: 22,
                        backgroundColor: AppColors.background,
                        fallbackIcon: Icons.person,
                        iconColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
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

/// Fades and slides a card in on first build, staggered by list index —
/// each band card (and the trailing "Add band" card) animates in a
/// beat after the one before it instead of the whole list just
/// appearing at once. Purely a one-time entrance effect; it doesn't
/// replay on every rebuild since the delay only fires once in
/// initState.
class _StaggeredFadeIn extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggeredFadeIn({required this.index, required this.child});

  @override
  State<_StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<_StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_fade);

    Future.delayed(Duration(milliseconds: 70 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
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

    // Gradient stroke (amber -> orange) instead of a flat single color —
    // small touch, but it's what makes this gauge look like a deliberate
    // design choice rather than a default progress bar.
    final fgPaint = Paint()
      ..shader = const SweepGradient(
        colors: [Colors.amber, Colors.deepOrange],
        startAngle: 0,
        endAngle: math.pi,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, math.pi, math.pi, false, bgPaint);
    canvas.drawArc(rect, math.pi, math.pi * progress, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}