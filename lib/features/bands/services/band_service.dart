import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BandService {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth auth =
      FirebaseAuth.instance;

  Future<void> createWearer({
    required String name,
    required int age,
    required String email,
    required String address,
  }) async {
    final user = auth.currentUser!;

    await firestore
        .collection('users')
        .doc(user.uid)
        .collection('wearers')
        .add({
      'name': name,
      'age': age,
      'email': email,
      'address': address,
      'photoUrl': '',
      'createdAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> createBand({
    required String bandName,
    required String wearerName,
    required int age,
    required String address,
    required String bloodGroup,
    required String medicalConditions,
    required String doctorPhone,
  }) async {
    final user = auth.currentUser!;

    // Get current user's familyId
    final userDoc = await firestore
        .collection('users')
        .doc(user.uid)
        .get();

    final familyId =
        userDoc.data()?['familyId'];

    await firestore.collection('bands').add({
      'ownerId': user.uid,

      // IMPORTANT
      'familyId': familyId,

      'bandName': bandName,
      'wearerName': wearerName,
      'age': age,
      'address': address,
      'bloodGroup': bloodGroup,
      'medicalConditions':
          medicalConditions,
      'doctorPhone': doctorPhone,

      // Dummy values for now
      'heartRate': 0,
      'steps': 0,

      'createdAt':
          FieldValue.serverTimestamp(),
    });
  }
}