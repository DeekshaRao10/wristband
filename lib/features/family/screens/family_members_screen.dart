import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
 
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../../bands/screens/band_detail_screen.dart';
import '../../pairing/screens/pair_scan_screen.dart';
import '../../settings/screens/settings_screen.dart';
 
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
 
  void _showInviteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Invite a family member",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Share this code — they can join $familyName from the app's \"Join Family\" screen.",
                style: const TextStyle(color: AppColors.mutedText),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  inviteCode,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: "Copy Code",
                icon: Icons.copy,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: inviteCode));
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invite code copied")),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const Icon(Icons.groups, color: AppColors.primary),
        title: const Text(
          "Family Management",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: AppColors.black,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("No new notifications")),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Members",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
 
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('families')
                  .doc(familyId)
                  .collection('members')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
 
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text("No family members found"),
                  );
                }
 
                final members = snapshot.data!.docs;
 
                return Column(
                  children: members.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
 
                    return _MemberCard(
                      familyId: familyId,
                      memberId: doc.id,
                      name: data['name'] ?? 'Unknown',
                      phone: data['phone'] ?? '',
                      role: data['role'] ?? 'Member',
                      notificationsEnabled:
                          data['notificationsEnabled'] ?? true,
                    );
                  }).toList(),
                );
              },
            ),
 
            const SizedBox(height: 24),
 
            const Text(
              "Bands",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
 
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bands')
                  .where('familyId', isEqualTo: familyId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
 
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text("No bands added yet"),
                  );
                }
 
                final bands = snapshot.data!.docs;
 
                return Column(
                  children: bands.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
 
                    return _BandCard(
                      bandId: doc.id,
                      deviceId: data['deviceId'] ?? '',
                      bandName: data['bandName'] ?? 'SafeBand',
                      wearerName: data['wearerName'] ?? 'Unknown',
                    );
                  }).toList(),
                );
              },
            ),
 
            const SizedBox(height: 24),
 
            PrimaryButton(
              text: "Invite member",
              icon: Icons.person_add,
              onPressed: () => _showInviteSheet(context),
            ),
 
            const SizedBox(height: 12),
 
            PrimaryButton(
              text: "Add band",
              icon: Icons.add,
              outlined: true,
              foregroundColor: AppColors.primary,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PairScanScreen(),
                  ),
                );
              },
            ),
 
            const SizedBox(height: 12),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
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
 
class _MemberCard extends StatelessWidget {
  final String familyId;
  final String memberId;
  final String name;
  final String phone;
  final String role;
  final bool notificationsEnabled;
 
  const _MemberCard({
    required this.familyId,
    required this.memberId,
    required this.name,
    required this.phone,
    required this.role,
    required this.notificationsEnabled,
  });
 
  Future<void> _setNotificationsEnabled(bool value) {
    return FirebaseFirestore.instance
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(memberId)
        .update({'notificationsEnabled': value});
  }
 
  @override
  Widget build(BuildContext context) {
    final isWearer = role == 'Wearer';
    final isAdmin = role == 'Admin';
 
    // Matches the reference design: the Admin's badge reads "1ST CONTACT"
    // instead of "Admin" (there's no separate "primary contact" concept in
    // the data yet, so this is the closest real thing available). Other
    // roles show their role name directly on the badge.
    final badgeText = isAdmin ? "1ST CONTACT" : role.toUpperCase();
    final badgeColor = isAdmin
        ? AppColors.success
        : (isWearer ? Colors.orange : AppColors.primary);
 
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, color: AppColors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (isAdmin)
                      const Text(
                        "Admin",
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 12,
                        ),
                      ),
                    if (phone.isNotEmpty)
                      Text(
                        phone,
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
 
          // Notification preferences only make sense for caregivers, not
          // for the wearer's own card.
          if (!isWearer) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("App Notifications"),
                Switch(
                  value: notificationsEnabled,
                  activeColor: AppColors.primary,
                  onChanged: _setNotificationsEnabled,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "SMS Emergency Alerts (coming soon)",
                  style: TextStyle(color: AppColors.mutedText),
                ),
                Switch(
                  value: false,
                  onChanged: null, // Disabled — SMS sending isn't built yet.
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
 
class _BandCard extends StatelessWidget {
  final String bandId;
  final String deviceId;
  final String bandName;
  final String wearerName;
 
  const _BandCard({
    required this.bandId,
    required this.deviceId,
    required this.bandName,
    required this.wearerName,
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.background,
              child: Icon(Icons.watch, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bandName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Worn by $wearerName",
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _OnlineStatusChip(deviceId: deviceId),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.mutedText),
          ],
        ),
      ),
    );
  }
}
 
/// Reads the band's live "lastUpdated" timestamp directly from the
/// Realtime Database (where the ESP32 writes it every ~5s) and shows
/// Online/Offline based on how recent it is — this replaces a hardcoded
/// badge with a real, if approximate, presence indicator. There's no
/// battery-level display here because the firmware doesn't report one.
class _OnlineStatusChip extends StatelessWidget {
  final String deviceId;
 
  const _OnlineStatusChip({required this.deviceId});
 
  @override
  Widget build(BuildContext context) {
    if (deviceId.isEmpty) return const SizedBox.shrink();
 
    final ref = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://safeband-a3b89-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).ref('bands/$deviceId/lastUpdated');
 
    return StreamBuilder<DatabaseEvent>(
      stream: ref.onValue,
      builder: (context, snapshot) {
        bool online = false;
 
        final value = snapshot.data?.snapshot.value;
 
        if (value != null) {
          final lastUpdated = (value as num).toInt();
          final nowEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
 
          // The band uploads roughly every 5 seconds, so anything within
          // the last 15 seconds is treated as currently online.
          online = (nowEpoch - lastUpdated) < 15;
        }
 
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: online ? AppColors.success : AppColors.grey,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            online ? "ONLINE" : "OFFLINE",
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
 
