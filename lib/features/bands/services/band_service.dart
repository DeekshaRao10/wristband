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
}