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

  String _wearerName = "Unknown";
  String _bandName = "SafeBand";
  String _address = "Address not set";
  String _bloodGroup = "--";
  String _medicalConditions = "--";
  String _doctorPhone = "";

 
  String _wearerUid = "";

  int _caregiverCount = 0;
  bool _cancelling = false;


  final List<String> _caregiverPhones = [];


  int? _heartRate;
  int? _spo2;

  final String _detectedAt = DateFormat('h:mm a').format(DateTime.now());
  bool _hasNavigatedAway = false;

  StreamSubscription<DatabaseEvent>? _statusSub;

  @override
  void initState() {
    super.initState();

   
    _heartRate = (widget.alertData['heartRate'] as num?)?.toInt();
    _spo2 = (widget.alertData['spo2'] as num?)?.toInt();

    _loadBandAndFamilyInfo();
    _listenForRecovery();
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    super.dispose();
  }
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

      if (mounted) {
        setState(() {
          _heartRate = (data['heartRate'] as num?)?.toInt() ?? _heartRate;
          _spo2 = (data['spo2'] as num?)?.toInt() ?? _spo2;
        });
      }

      if (!fallDetected) {
        _goHome();
      }
    });
  }

  Future<void> _sendEmergencySms() async {
    if (_caregiverPhones.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No caregiver phone numbers on file"),
          ),
        );
      }
      return;
    }

    final message = "EMERGENCY: $_wearerName has fallen and needs help. "
        "Location: $_address. Detected at $_detectedAt.";

    final uri = Uri(
      scheme: 'sms',
      path: _caregiverPhones.join(','),
      queryParameters: {'body': message},
    );

    try {
      final launched = await launchUrl(uri);

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't open messages app")),
        );
      }
    } catch (e) {
      debugPrint("EmergencyScreen: failed to launch SMS: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't open messages app")),
        );
      }
    }
  }
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

  Future<void> _cancelAlert() async {
    setState(() => _cancelling = true);

    try {
      final bandRef = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: _rtdbUrl,
      ).ref('bands/${widget.bandId}');

   
      await bandRef.update({
        'cancelRequested': true,
        'fallDetected': false,
        'status': 'NORMAL',
      });
    } catch (e) {
      debugPrint("EmergencyScreen: failed to write cancel/normal state: $e");
    }

  
    _goHome();
  }

  
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

          final phone = memberData['phone']?.toString() ?? '';
          if (phone.isNotEmpty) {
            _caregiverPhones.add(phone);
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
  
    return AnnotatedRegion<SystemUiOverlayStyle>(
      
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
                    child: CircularProgressIndicator(color: AppColors.textOnColor),
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
                            Icon(Icons.watch, size: 20, color: AppColors.textOnColor),
                            SizedBox(width: 8),
                            Text(
                              "Fall Alert",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textOnColor,
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
                        color: AppColors.textOnColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "FALL DETECTED",
                      style: TextStyle(
                        color: AppColors.textOnColor,
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
                          color: AppColors.textOnColor,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    
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
                        children: [
                          const Icon(Icons.favorite,
                              color: AppColors.textOnColor, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            _heartRate != null ? "$_heartRate BPM" : "-- BPM",
                            style: const TextStyle(
                              color: AppColors.textOnColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 18),
                          const Icon(Icons.water_drop,
                              color: AppColors.textOnColor, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            _spo2 != null ? "$_spo2% SpO2" : "--% SpO2",
                            style: const TextStyle(
                              color: AppColors.textOnColor,
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
                            color: AppColors.textOnColor, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            
                            _caregiverCount > 0
                                ? "Notifications sent to $_caregiverCount caregiver${_caregiverCount == 1 ? '' : 's'}"
                                : "Notifying caregivers...",
                            style: const TextStyle(
                              color: AppColors.textOnColor,
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
                              
                              const Text(
                                "Emergency",
                                style: TextStyle(
                                  color: AppColors.alertCard,
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
                      foregroundColor: AppColors.textOnColor,
                      onPressed: _cancelling ? null : _cancelAlert,
                    ),

                    const SizedBox(height: 14),

                    PrimaryButton(
                      text: "ALERT NOW",
                      icon: Icons.campaign,
                      backgroundColor: AppColors.alertButton,
                     
                      onPressed: _sendEmergencySms,
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
          color: AppColors.textOnColor.withOpacity(opacity),
        ),
      ),
    );
  }
}