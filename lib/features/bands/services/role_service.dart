import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>?> getCurrentMembership() async {
    final user = auth.currentUser;

    if (user == null) return null;

    final snapshot = await firestore
        .collection('bandMembers')
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data();
    }

    // No direct band assignment — this user isn't the admin who created
    // a band and isn't a separate wearer account, so there's no
    // bandMembers doc for them. But they may still have already joined
    // a family as a caregiver via an invite code: that's tracked on
    // their own users/{uid} doc's familyId field (set by
    // family_service.dart's createFamily/joinFamily), not in
    // bandMembers at all. Without this check, a returning caregiver who
    // already joined a family would incorrectly look like a brand-new
    // user and get sent back through FamilyChoiceScreen every time they
    // log in, instead of straight to Dashboard.
    final userDoc =
        await firestore.collection('users').doc(user.uid).get();

    final familyId = userDoc.data()?['familyId']?.toString() ?? '';

    if (familyId.isEmpty) return null;

    return {
      'role': 'Member',
      'bandId': '',
      'familyId': familyId,
    };
  }
}