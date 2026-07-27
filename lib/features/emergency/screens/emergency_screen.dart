import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';

const String _rtdbUrl =
    'https://safeband-a3b89-default-rtdb.asia-southeast1.firebasedatabase.app';

/// Full-screen emergency alert, shown when AlertListener detects
/// fallDetected == true while the app is open.
///
/// [bandId] is the ESP32's deviceId (matches both the Realtime Database
/// path and the "deviceId" field on the Firestore "bands" doc).
/// [alertData] is the live Realtime Database snapshot (heartRate, spo2,
/// fallDetected, status) at the moment the alert fired.
class EmergencyScreen extends StatefulWidget {
  final String bandId;
  final Map<String, dynamic> alertData;

  const EmergencyScreen({
    super.key,
    required this.bandId,
    required this.alertData,
  });

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = true;

  // Static profile info — lives in Firestore's "bands" collection, not in
  // the Realtime Database, so it has to be fetched separately from the
  // live vitals.
  String _wearerName = "Unknown";
  String _bandName = "SafeBand";
  String _address = "Address not set";
  String _bloodGroup = "--";
  String _medicalConditions = "--";
  String _doctorPhone = "";
  String? _photoUrl;

  int _caregiverCount = 0;
  bool _cancelling = false;

  final String _detectedAt = DateFormat('h:mm a').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadBandAndFamilyInfo();
  }

  /// Writes a cancel signal to bands/{bandId}/cancelRequested in RTDB.
  /// The ESP32 polls this path every ~5s while an emergency is active
  /// (see checkAndClearCancelRequest() in firebase_manager.cpp) and, on
  /// seeing it true, clears its OWN fallDetected/status and resets the
  /// flag back to false. Once the band clears it in RTDB, Dashboard,
  /// Family Management and Band Detail all update automatically since
  /// they already read fallDetected/status live from this same node.
  Future<void> _cancelAlert() async {
    setState(() => _cancelling = true);

    try {
      final bandRef = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: _rtdbUrl,
      ).ref('bands/${widget.bandId}');

      // Two writes:
      // 1. cancelRequested: true — the band itself polls this and, once
      //    it notices, clears its OWN fallDetected/status and resets its
      //    vitals to a resting baseline (see checkAndClearCancelRequest()
      //    in firebase_manager.cpp). This is the real, durable fix — the
      //    band won't re-assert EMERGENCY on its next upload.
      // 2. fallDetected/status optimistically set to false/NORMAL right
      //    now, on the same node every screen already reads live from —
      //    so Dashboard/Family/Band Detail all flip to normal instantly
      //    instead of waiting up to ~5s for the band's own next poll
      //    cycle to catch up. The band's own write moments later just
      //    confirms the same state, so there's no lasting conflict.
      await bandRef.update({
        'cancelRequested': true,
        'fallDetected': false,
        'status': 'NORMAL',
      });
    } catch (e) {
      debugPrint("EmergencyScreen: failed to write cancel/normal state: $e");
    }

    if (!mounted) return;

    // Back to Home Dashboard (the root screen), not just one screen back.
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  Future<void> _loadBandAndFamilyInfo() async {
    try {
      final bandsSnap = await _firestore
          .collection('bands')
          .where('deviceId', isEqualTo: widget.bandId)
          .limit(1)
          .get();

      if (bandsSnap.docs.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final band = bandsSnap.docs.first.data();

      _wearerName = band['wearerName']?.toString() ?? "Unknown";
      _bandName = band['bandName']?.toString() ?? "SafeBand";
      _address = band['address']?.toString() ?? "Address not set";
      _bloodGroup = band['bloodGroup']?.toString() ?? "--";
      _medicalConditions = band['medicalConditions']?.toString() ?? "--";
      _doctorPhone = band['doctorPhone']?.toString() ?? "";
      _photoUrl = band['photoUrl']?.toString();
      if (_photoUrl != null && _photoUrl!.isEmpty) _photoUrl = null;

      final familyId = band['familyId']?.toString();

      if (familyId != null && familyId.isNotEmpty) {
        final membersSnap = await _firestore
            .collection('families')
            .doc(familyId)
            .collection('members')
            .get();

        _caregiverCount = membersSnap.docs.length;
      }
    } catch (e) {
      debugPrint("EmergencyScreen: failed to load band/family info: $e");
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final heartRate = widget.alertData['heartRate']?.toString() ?? "--";

    return Scaffold(
      // Full-screen red instead of a red card floating on a light
      // background — this is an emergency alert, it should take over
      // the whole screen, not look like a normal card-based page.
      backgroundColor: AppColors.alertCard,
      appBar: AppBar(
        backgroundColor: AppColors.alertCard,
        elevation: 0,
        foregroundColor: AppColors.white,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.watch, size: 20, color: AppColors.white),
            SizedBox(width: 8),
            Text(
              "Fall Alert",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.white),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: AppColors.white,
                      backgroundImage: _photoUrl != null
                          ? NetworkImage(_photoUrl!)
                          : null,
                      child: _photoUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 42,
                              color: AppColors.alertCard,
                            )
                          : null,
                    ),

                    const SizedBox(height: 14),

                    Text(
                      _wearerName.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      "FALL DETECTED",
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.alertOverlay,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _detectedAt,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Reflects what's actually implemented today — no
                    // buzzer control or SMS sending exists yet, so this
                    // only claims what the app really does right now.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.alertOverlay,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: AppColors.white, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _caregiverCount > 0
                                  ? "Notifications sent to $_caregiverCount caregiver${_caregiverCount == 1 ? '' : 's'}"
                                  : "Notifying caregivers...",
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: AppColors.alertMutedText, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _address,
                            style: const TextStyle(
                              color: AppColors.alertMutedText,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Emergency info card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "EMERGENCY INFO",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.5,
                              color: AppColors.mutedText,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Blood Group",
                                style:
                                    TextStyle(color: AppColors.mutedText),
                              ),
                              Text(
                                _bloodGroup,
                                style: const TextStyle(
                                  color: AppColors.alertCard,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Conditions",
                                style:
                                    TextStyle(color: AppColors.mutedText),
                              ),
                              Text(
                                _medicalConditions,
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          if (_doctorPhone.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Doctor",
                                  style: TextStyle(
                                      color: AppColors.mutedText),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      _doctorPhone,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.phone,
                                        size: 16,
                                        color: AppColors.success),
                                  ],
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 8),

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Heart Rate",
                                style:
                                    TextStyle(color: AppColors.mutedText),
                              ),
                              Text(
                                "$heartRate BPM",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    PrimaryButton(
                      text: _cancelling ? "Cancelling..." : "I'm OK — Cancel",
                      icon: Icons.close,
                      outlined: true,
                      foregroundColor: AppColors.white,
                      onPressed: _cancelling ? null : _cancelAlert,
                    ),

                    const SizedBox(height: 10),

                    PrimaryButton(
                      text: "ALERT NOW",
                      icon: Icons.campaign,
                      backgroundColor: AppColors.alertButton,
                      onPressed: () {
                        // Hook up your existing emergency-escalation
                        // logic here (e.g. re-notify caregivers, call
                        // emergency services, etc.) if you have it.
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
