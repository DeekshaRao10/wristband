import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FamilyService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // Generate 6-digit invite code
  String generateInviteCode() {
    final random = Random();

    return (100000 + random.nextInt(900000))
        .toString();
  }

  // Create Family
  Future<Map<String, String>> createFamily(
    String familyName,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    final inviteCode = generateInviteCode();

    final doc =
        _firestore.collection('families').doc();

    await doc.set({
      'familyId': doc.id,
      'familyName': familyName,
      'inviteCode': inviteCode,
      'createdBy': user.uid,
      'createdAt': Timestamp.now(),
    });

    return {
      'familyId': doc.id,
      'inviteCode': inviteCode,
    };
  }

  // Find Family By Invite Code
  Future<Map<String, dynamic>?> getFamilyByCode(
    String inviteCode,
  ) async {
    final result = await _firestore
        .collection('families')
        .where(
          'inviteCode',
          isEqualTo: inviteCode,
        )
        .get();

    if (result.docs.isEmpty) {
      return null;
    }

    return result.docs.first.data();
  }

  // Join Family
  Future<void> joinFamily(
    String familyId,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    await _firestore
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(user.uid)
        .set({
      'uid': user.uid,
      'joinedAt': Timestamp.now(),
    });
  }
}