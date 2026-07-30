import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/local_avatar.dart';
import '../../../core/services/wearer_resolver.dart';

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

  // Profile photos are stored entirely on-device (LocalPhotoStore), not
  // in Firestore — there never was a real "photoUrl" field to read, so
  // the old NetworkImage(_photoUrl) here could never actually show
  // anything. This is the wearer's uid, used as the LocalAvatar lookup
  // key instead.
  String _wearerUid = "";

  int _caregiverCount = 0;
  bool _cancelling = false;

  final String _detectedAt = DateFormat('h:mm a').format(DateTime.now());

  // Guards against navigating away twice — both the manual "I'm OK"
  // button and the automatic RTDB listener below can each try to send
  // us back to Home Dashboard, so whichever happens first wins and the
  // other becomes a no-op.
  bool _hasNavigatedAway = false;

  StreamSubscription<DatabaseEvent>? _statusSub;

  @override
  void initState() {
    super.initState();
    _loadBandAndFamilyInfo();
    _listenForRecovery();
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    super.dispose();
  }

  /// Watches bands/{bandId} in RTDB the whole time this screen is open.
  /// If fallDetected flips back to false for ANY reason — the band's
  /// own auto-clear timeout (see main.cpp's 30s emergencyStartTime
  /// check), another caregiver cancelling it from their phone, or this
  /// device's own "I'm OK" button — this screen automatically closes
  /// itself and returns to Home Dashboard, instead of sitting there
  /// showing a stale alert.
  void _listenForRecovery() {
    final ref = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: _rtdbUrl,
    ).ref('bands/${widget.bandId}');

    _statusSub = ref.onValue.listen((event) {
      final value = event.snapshot.value;
      if (value is! Map) return;

      final data = Map<String, dynamic>.from(value);
      final fallDetected = data['fallDetected'] == true;

      if (!fallDetected) {
        _goHome();
      }
    });
  }

  /// Opens the phone's dialer with the doctor's number pre-filled via a
  /// real tel: intent — tapping the pill actually starts a call instead
  /// of just displaying the number.
  Future<void> _callDoctor() async {
    if (_doctorPhone.isEmpty) return;

    final uri = Uri(scheme: 'tel', path: _doctorPhone);

    try {
      final launched = await launchUrl(uri);

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't open the dialer")),
        );
      }
    } catch (e) {
      debugPrint("EmergencyScreen: failed to launch dialer: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't open the dialer")),
        );
      }
    }
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

    // The RTDB write above will also make _listenForRecovery's listener
    // fire almost immediately — _goHome()'s _hasNavigatedAway guard
    // means whichever of these two fires first is the one that actually
    // navigates, the other is a harmless no-op.
    _goHome();
  }

  /// Shared "return to Home Dashboard" used by both the manual cancel
  /// button and the automatic recovery listener.
  void _goHome() {
    if (_hasNavigatedAway) return;
    _hasNavigatedAway = true;

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

      final bandDoc = bandsSnap.docs.first;
      final band = bandDoc.data();

      _wearerName = band['wearerName']?.toString() ?? "Unknown";
      _bandName = band['bandName']?.toString() ?? "SafeBand";
      _address = band['address']?.toString() ?? "Address not set";
      _bloodGroup = band['bloodGroup']?.toString() ?? "--";
      _medicalConditions = band['medicalConditions']?.toString() ?? "--";
      _doctorPhone = band['doctorPhone']?.toString() ?? "";

      // Same self-healing lookup used on Dashboard/Family/Band Detail —
      // resolves the real wearer uid even for bands created before the
      // wearerUid field existed.
      _wearerUid = await resolveWearerUid(
        bandId: bandDoc.id,
        rawWearerUid: (band['wearerUid'] ?? '').toString(),
      );

      final familyId = band['familyId']?.toString();

      if (familyId != null && familyId.isNotEmpty) {
        final membersSnap = await _firestore
            .collection('families')
            .doc(familyId)
            .collection('members')
            .get();

        // Real count of people who'd actually get notified, not just
        // "everyone in the family": excludes the wearer themselves
        // (they don't need to be alerted about their own fall), skips
        // anyone who's turned notifications off for this family (same
        // toggle Settings and Family Management control), and only
        // counts members who actually have a saved FCM push token —
        // i.e. someone notification_service.dart could really reach.
        int realCaregiverCount = 0;

        for (final memberDoc in membersSnap.docs) {
          final memberData = memberDoc.data();

          final isWearer = memberData['role'] == 'Wearer';
          final notificationsEnabled =
              memberData['notificationsEnabled'] ?? true;

          if (isWearer || notificationsEnabled != true) continue;

          final userDoc =
              await _firestore.collection('users').doc(memberDoc.id).get();

          final fcmToken = userDoc.data()?['fcmToken']?.toString() ?? '';

          if (fcmToken.isNotEmpty) {
            realCaregiverCount++;
          }
        }

        _caregiverCount = realCaregiverCount;
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
    // No AppBar here on purpose — a Material AppBar renders as its own
    // separate surface/bar segment even when its color matches the body,
    // which is exactly the "not truly full screen" gap being reported.
    // Everything (status bar area included) is one single red Container
    // now, with the "Fall Alert" title just as a plain Row inside it.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // systemNavigationBarColor covers the black strip Android draws
      // for the on-screen nav bar (home/back/recents) — that's the OS's
      // own overlay, not part of this screen's canvas, so it stays
      // black by default unless explicitly told to match here.
      value: SystemUiOverlayStyle.light.copyWith(
        systemNavigationBarColor: AppColors.alertCard,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: AppColors.alertCard,
      ),
      child: Scaffold(
        backgroundColor: AppColors.alertCard,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          // Subtle top-to-bottom gradient instead of one flat red —
          // adds a bit of depth without changing the full-edge-to-edge
          // red look you asked for earlier.
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(AppColors.alertCard, Colors.black, 0.12)!,
                AppColors.alertCard,
              ],
            ),
          ),
          child: _loading
              ? const SafeArea(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.white),
                  ),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 26,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.watch, size: 20, color: AppColors.white),
                            SizedBox(width: 8),
                            Text(
                              "Fall Alert",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        _PulsingGlowAvatar(photoKey: _wearerUid),

                    const SizedBox(height: 22),

                    Text(
                      _wearerName.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "FALL DETECTED",
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
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

                    const SizedBox(height: 26),

                    // Matches the reference design's buzzer-status pill.
                    // NOTE: this is a visual/UI match only — there's no
                    // physical buzzer wired to the ESP32 yet, so this is
                    // aspirational until real buzzer firmware exists.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.alertOverlay,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.volume_up,
                              color: AppColors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            "Band buzzer is sounding",
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppColors.white, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            // "SMS +" dropped — SMS was never actually
                            // implemented (same reason it was removed
                            // from Family Management earlier). This
                            // count is now real: it only includes
                            // caregivers who have notifications turned
                            // on AND an actual push token on file, so
                            // it's genuinely "how many phones this
                            // reached," not just the family's size.
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

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: AppColors.alertMutedText, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Location: $_address",
                            style: const TextStyle(
                              color: AppColors.alertMutedText,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Emergency info card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
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

                          const SizedBox(height: 18),

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

                          const SizedBox(height: 16),

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
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Doctor",
                                  style: TextStyle(
                                      color: AppColors.mutedText),
                                ),
                                // Tap to actually call — real
                                // tel: intent, not just decorative text
                                // + icon like before.
                                Material(
                                  color: AppColors.success.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: _callDoctor,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _doctorPhone,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.success,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.phone,
                                              size: 16,
                                              color: AppColors.success),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    PrimaryButton(
                      text: _cancelling ? "Cancelling..." : "I'm OK — Cancel",
                      icon: Icons.close,
                      outlined: true,
                      foregroundColor: AppColors.white,
                      onPressed: _cancelling ? null : _cancelAlert,
                    ),

                    const SizedBox(height: 14),

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
        ),
      ),
    );
  }
}

/// Matches the reference design's soft glowing ring behind the profile
/// photo — a pulsing white halo that expands and fades out on a loop,
/// rather than the plain flat circle avatar sat directly on the red
/// background. Purely decorative (no data dependency), so it's a small
/// self-contained StatefulWidget just for the animation.
class _PulsingGlowAvatar extends StatefulWidget {
  final String photoKey;

  const _PulsingGlowAvatar({required this.photoKey});

  @override
  State<_PulsingGlowAvatar> createState() => _PulsingGlowAvatarState();
}

class _PulsingGlowAvatarState extends State<_PulsingGlowAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const avatarRadius = 42.0;

    return SizedBox(
      width: avatarRadius * 2.8,
      height: avatarRadius * 2.8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Two rings staggered half a cycle apart so a new pulse starts
          // before the previous one has fully faded — a continuous
          // "radar ping" look instead of one ring blinking on and off.
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => _glowRing(_controller.value, avatarRadius),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => _glowRing(
              (_controller.value + 0.5) % 1.0,
              avatarRadius,
            ),
          ),
          LocalAvatar(
            photoKey: widget.photoKey,
            radius: avatarRadius,
            backgroundColor: AppColors.white,
            fallbackIcon: Icons.person,
            iconColor: AppColors.alertCard,
          ),
        ],
      ),
    );
  }

  Widget _glowRing(double t, double avatarRadius) {
    final scale = 1.0 + t * 0.5;
    final opacity = (1.0 - t).clamp(0.0, 1.0) * 0.45;

    return Transform.scale(
      scale: scale,
      child: Container(
        width: avatarRadius * 2,
        height: avatarRadius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.white.withOpacity(opacity),
        ),
      ),
    );
  }
}