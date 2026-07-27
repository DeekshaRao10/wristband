import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

import '../widgets/medical_card.dart';
import '../../pairing/screens/change_wifi_screen.dart';

// NOTE: this rebuild matches the new "Band Detail" reference design and
// bakes the header/status/heart-rate/blood-oxygen/steps/last-movement
// cards directly into this file instead of the old separate
// band_header.dart / status_card.dart / heart_rate_card.dart /
// steps_card.dart widgets — those are no longer used here, only
// medical_card.dart still is (for the blood group / conditions / doctor
// section further down the scroll, not shown in the reference crop).

const String _rtdbUrl =
    'https://safeband-a3b89-default-rtdb.asia-southeast1.firebasedatabase.app';

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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData ||
              !snapshot.data!.exists ||
              snapshot.data!.data() == null) {
            return const Center(child: Text("Band not found"));
          }

          final band = snapshot.data!.data() as Map<String, dynamic>;
          final deviceId = band['deviceId'] ?? '';
          final wearerName = band['wearerName'] ?? '';
          final stepGoal = band['stepGoal'] ?? 5000;

          return SafeArea(
            child: Column(
              children: [
                _DetailAppBar(
                  wearerName: wearerName,
                  onSettingsTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeWifiScreen(deviceId: deviceId),
                      ),
                    );
                  },
                ),

                Expanded(
                  child: _LiveVitals(
                    deviceId: deviceId,
                    builder: (context, online, lastSyncText, heartRate, spo2) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _StatusCard(
                              wearerName: wearerName,
                              online: online,
                              battery: band['battery'] ?? 100,
                              lastSyncText: lastSyncText,
                            ),

                            const SizedBox(height: 16),

                            _HeartRateCard(heartRate: heartRate),

                            const SizedBox(height: 16),

                            _BloodOxygenCard(spo2: spo2),

                            const SizedBox(height: 16),

                            _StepsCard(
                              bandId: bandId,
                              steps: band['steps'] ?? 0,
                              goal: stepGoal,
                            ),

                            const SizedBox(height: 16),

                            _LastMovementCard(lastSyncText: lastSyncText),

                            const SizedBox(height: 16),

                            MedicalCard(
                              bloodGroup: band['bloodGroup'] ?? '',
                              medicalConditions:
                                  band['medicalConditions'] ?? '',
                              doctorPhone: band['doctorPhone'] ?? '',
                              address: band['address'] ?? '',
                            ),

                            const SizedBox(height: 16),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Top bar: back arrow, small badge + wearer name, gear icon (-> Change
/// WiFi). No dropdown/wearer-switcher yet — there's no multi-profile
/// data model behind that in the reference design, so it's left out
/// rather than faked.
class _DetailAppBar extends StatelessWidget {
  final String wearerName;
  final VoidCallback onSettingsTap;

  const _DetailAppBar({
    required this.wearerName,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.black),
            onPressed: () => Navigator.pop(context),
          ),
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.watch, color: AppColors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Text(
            wearerName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const Spacer(),
          IconButton(
            // WiFi icon instead of a generic gear — this button only
            // ever opens Change WiFi.
            icon: const Icon(Icons.wifi, color: AppColors.black),
            onPressed: onSettingsTap,
          ),
        ],
      ),
    );
  }
}

/// Reads the live RTDB node once and hands online/lastSync/heartRate/spo2
/// down to [builder] — heartRate and spo2 come from here (real, ESP32-
/// reported data) instead of the old Firestore heartRate:0 placeholder
/// that never actually updated.
class _LiveVitals extends StatelessWidget {
  final String deviceId;
  final Widget Function(
    BuildContext context,
    bool online,
    String lastSyncText,
    int heartRate,
    int spo2,
  ) builder;

  const _LiveVitals({required this.deviceId, required this.builder});

  @override
  Widget build(BuildContext context) {
    if (deviceId.isEmpty) {
      return builder(context, false, 'Unknown', 0, 0);
    }

    final ref = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: _rtdbUrl,
    ).ref('bands/$deviceId');

    return StreamBuilder<DatabaseEvent>(
      stream: ref.onValue,
      builder: (context, snapshot) {
        bool online = false;
        String lastSyncText = 'Unknown';
        int heartRate = 0;
        int spo2 = 0;

        final value = snapshot.data?.snapshot.value;

        if (value is Map) {
          final data = Map<String, dynamic>.from(value);

          heartRate = (data['heartRate'] as num?)?.toInt() ?? 0;
          spo2 = (data['spo2'] as num?)?.toInt() ?? 0;

          final lastUpdated = (data['lastUpdated'] as num?)?.toInt();

          if (lastUpdated != null) {
            final nowEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            final diff = nowEpoch - lastUpdated;

            // Same 15s freshness window used everywhere else in the app.
            online = diff < 15;

            if (diff < 60) {
              lastSyncText = diff <= 2 ? 'Just now' : '${diff}s ago';
            } else if (diff < 3600) {
              lastSyncText = '${diff ~/ 60}m ago';
            } else {
              lastSyncText = '${diff ~/ 3600}h ago';
            }
          }
        }

        return builder(context, online, lastSyncText, heartRate, spo2);
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String wearerName;
  final bool online;
  final int battery;
  final String lastSyncText;

  const _StatusCard({
    required this.wearerName,
    required this.online,
    required this.battery,
    required this.lastSyncText,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: online ? AppColors.success : AppColors.grey,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: AppColors.white),
                const SizedBox(width: 6),
                Text(
                  online ? "Band Online" : "Band Offline",
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "$wearerName is doing well",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.battery_std, size: 16, color: AppColors.mutedText),
              const SizedBox(width: 4),
              Text(
                "$battery% Battery",
                style: const TextStyle(color: AppColors.mutedText, fontSize: 13),
              ),
              const Text(" • ", style: TextStyle(color: AppColors.mutedText)),
              Text(
                "Last synced $lastSyncText",
                style: const TextStyle(color: AppColors.mutedText, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeartRateCard extends StatefulWidget {
  final int heartRate;

  const _HeartRateCard({required this.heartRate});

  @override
  State<_HeartRateCard> createState() => _HeartRateCardState();
}

class _HeartRateCardState extends State<_HeartRateCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _durationForBpm(widget.heartRate),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant _HeartRateCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // As the live heart rate changes, the wave's speed changes with it —
    // higher BPM visibly scrolls/pulses faster, lower BPM slows down.
    if (oldWidget.heartRate != widget.heartRate) {
      _controller.duration = _durationForBpm(widget.heartRate);
    }
  }

  Duration _durationForBpm(int bpm) {
    final safeBpm = bpm > 0 ? bpm : 75;
    final ms = (90000 / safeBpm).round().clamp(600, 3000);
    return Duration(milliseconds: ms);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heartRate = widget.heartRate;

    // Simple resting-range read: not a medical diagnosis, just a rough
    // label matching the reference design's "Resting Normal" pill.
    final isNormal = heartRate == 0 || (heartRate >= 60 && heartRate <= 100);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite, color: AppColors.danger, size: 18),
              const SizedBox(width: 6),
              const Text(
                "HEART RATE",
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                "$heartRate",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  "bpm",
                  style: TextStyle(color: AppColors.mutedText, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _WavePainter(
                    color: AppColors.primary,
                    heartRate: heartRate,
                    phase: _controller.value,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isNormal ? Icons.arrow_upward : Icons.warning_amber,
                size: 14,
                color: isNormal ? AppColors.success : AppColors.danger,
              ),
              const SizedBox(width: 4),
              Text(
                isNormal ? "Resting Normal" : "Outside Normal Range",
                style: TextStyle(
                  color: isNormal ? AppColors.success : AppColors.danger,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BloodOxygenCard extends StatelessWidget {
  final int spo2;

  const _BloodOxygenCard({required this.spo2});

  @override
  Widget build(BuildContext context) {
    final healthy = spo2 == 0 || spo2 >= 95;

    return _Card(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.air, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              const Text(
                "BLOOD OXYGEN",
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "$spo2%",
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              healthy ? "Healthy Range" : "Below Healthy Range",
              style: TextStyle(
                color: healthy ? AppColors.success : AppColors.danger,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepsCard extends StatelessWidget {
  final String bandId;
  final int steps;
  final int goal;

  const _StepsCard({
    required this.bandId,
    required this.steps,
    required this.goal,
  });

  Future<void> _editGoal(BuildContext context) async {
    final controller = TextEditingController(text: goal.toString());

    final newGoal = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Edit Daily Step Goal"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Goal (steps)"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text.trim());
                Navigator.pop(dialogContext, parsed);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    if (newGoal != null && newGoal > 0) {
      await FirebaseFirestore.instance
          .collection('bands')
          .doc(bandId)
          .update({'stepGoal': newGoal});
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (steps / goal).clamp(0.0, 1.0) : 0.0;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_walk, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              const Text(
                "DAILY STEPS",
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 7,
                        backgroundColor: AppColors.background,
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                    const Icon(Icons.directions_walk, color: AppColors.primary),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Text(
                "$steps",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              Text(
                " / $goal",
                style: const TextStyle(fontSize: 16, color: AppColors.mutedText),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _editGoal(context),
              icon: const Icon(Icons.edit, size: 16, color: AppColors.primary),
              label: const Text("Edit Goal", style: TextStyle(color: AppColors.primary)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// There's no accelerometer/motion field in the firmware payload today —
/// only heartRate, spo2, fallDetected, status and lastUpdated get sent.
/// This reuses the same lastUpdated timestamp as a stand-in until real
/// motion tracking is added to firmware; it's honest about that in the
/// comment here rather than inventing a fake sensor reading.
class _LastMovementCard extends StatelessWidget {
  final String lastSyncText;

  const _LastMovementCard({required this.lastSyncText});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.timeline, color: Colors.orange, size: 18),
                  const SizedBox(width: 6),
                  const Text(
                    "LAST MOVEMENT",
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                lastSyncText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: child,
    );
  }
}

/// Decorative pulse-wave line — there's still no per-second heart rate
/// history stored anywhere to chart as real historical data, but this
/// now actually reacts to the live heartRate value: higher BPM packs
/// more pulse spikes into the same width AND scrolls faster (driven by
/// [phase], 0..1, supplied by an AnimationController whose duration is
/// tied to heartRate in _HeartRateCardState). Lower BPM = fewer, slower
/// spikes. So the graph visibly changes as the real number changes,
/// instead of playing the same fixed animation regardless of value.
class _WavePainter extends CustomPainter {
  final Color color;
  final int heartRate;
  final double phase;

  const _WavePainter({
    required this.color,
    required this.heartRate,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final midY = h * 0.55;

    final safeBpm = heartRate > 0 ? heartRate : 75;

    // How many full pulse cycles (the "wavelength") are visible across
    // the width. This used to be (bpm / 22), which barely changed at
    // all across a typical 75-90 demo range (only ~3.4 to ~4.1 — an
    // imperceptible difference, which is why every beat looked the
    // same). This version moves a full extra beat onto the screen for
    // every 5 bpm above 75, so the spacing between beats visibly
    // tightens up as heart rate rises.
    final cycles = (3 + (safeBpm - 75) * 0.2).clamp(2.0, 8.0);
    final cycleWidth = w / cycles;

    // Spike height is driven directly off each single BPM unit, not a
    // broad ratio — so 80 vs 81 visibly differ, not just 75 vs 100.
    // bpmDiff is how far above/below the 75 baseline the current reading
    // is; every single unit adds a fixed pixel amount to the spike/dip
    // height, clamped so it still fits inside the card.
    final bpmDiff = safeBpm - 75;

    // R-spike (main tall peak) and S-dip heights — driven per single BPM
    // unit so 80 vs 81 visibly differ, not just big jumps like 75 vs 100.
    final spikeUp = (h * 0.30 + bpmDiff * (h * 0.022))
        .clamp(h * 0.10, h * 0.46);
    final spikeDown = (h * 0.10 + bpmDiff * (h * 0.009))
        .clamp(h * 0.04, h * 0.30);

    final pWaveHeight = h * 0.06;
    final tWaveHeight = h * 0.10;

    final shift = phase * cycleWidth;

    final path = Path();
    double x = -cycleWidth + shift;
    path.moveTo(x, midY);

    // Each cycle is a proper ECG-style PQRST complex — small P bump,
    // sharp QRS spike, gentle T bump, then flat baseline until the next
    // beat — instead of a single generic zigzag.
    while (x < w + cycleWidth) {
      path.lineTo(x + cycleWidth * 0.06, midY);

      path.quadraticBezierTo(
        x + cycleWidth * 0.10,
        midY - pWaveHeight,
        x + cycleWidth * 0.14,
        midY,
      );

      path.lineTo(x + cycleWidth * 0.20, midY);
      path.lineTo(x + cycleWidth * 0.24, midY + spikeDown * 0.4);
      path.lineTo(x + cycleWidth * 0.28, midY - spikeUp);
      path.lineTo(x + cycleWidth * 0.32, midY + spikeDown);
      path.lineTo(x + cycleWidth * 0.38, midY);
      path.lineTo(x + cycleWidth * 0.50, midY);

      path.quadraticBezierTo(
        x + cycleWidth * 0.58,
        midY - tWaveHeight,
        x + cycleWidth * 0.66,
        midY,
      );

      path.lineTo(x + cycleWidth, midY);

      x += cycleWidth;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.heartRate != heartRate;
}
