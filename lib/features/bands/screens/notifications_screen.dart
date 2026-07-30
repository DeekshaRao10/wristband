import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';

/// Real notification history — every fall alert that's ever fired for
/// this family, newest first, with a live "Active"/"Resolved" status
/// chip per entry. Replaces the old bell icon's "No new notifications"
/// snackbar, which never actually reflected anything real.
///
/// Backed by families/{familyId}/alerts, written to by
/// dashboard_screen.dart: a doc gets created the moment a fall is
/// detected (resolved: false), and updated to resolved: true the
/// moment that band's fallDetected clears back to false — so this
/// list is a genuine record, not just whatever's happening right now.
class NotificationsScreen extends StatelessWidget {
  final String familyId;

  const NotificationsScreen({super.key, required this.familyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.black),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('families')
            .doc(familyId)
            .collection('alerts')
            // Ordering by 'timestamp' (a FieldValue.serverTimestamp()
            // sentinel) hid brand-new alerts from this exact list: until
            // the server resolves that field, Firestore's local cache
            // can't place the doc in sort order and drops it from the
            // live snapshot entirely, so a fresh alert simply never
            // rendered. 'clientTimestamp' is a real value from the
            // moment it's written, so newly created alerts sort and
            // appear immediately.
            .orderBy('clientTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "Couldn't load notifications: ${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.mutedText),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "No notifications yet — fall alerts will show up here.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.mutedText),
                ),
              ),
            );
          }

          final alerts = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final data = alerts[index].data() as Map<String, dynamic>;
              return _AlertTile(data: data);
            },
          );
        },
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final Map<String, dynamic> data;

  const _AlertTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final wearerName = data['wearerName']?.toString() ?? 'Unknown';
    final resolved = data['resolved'] == true;

    // 'timestamp' is server-resolved and reads back null for an instant
    // right when the alert is created — 'clientTimestamp' is set the
    // moment the alert fires, so it's always available immediately and
    // is used first, with 'timestamp' as a backup for any older alerts
    // logged before this field existed.
    final effectiveTimestamp =
        (data['clientTimestamp'] as Timestamp?) ?? (data['timestamp'] as Timestamp?);

    final timeText = effectiveTimestamp != null
        ? DateFormat('MMM d, h:mm a').format(effectiveTimestamp.toDate())
        : 'Just now';

    final statusColor = resolved ? AppColors.success : AppColors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.warning_amber_rounded, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$wearerName — Fall Detected",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              resolved ? "Resolved" : "Active",
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}