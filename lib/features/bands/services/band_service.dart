import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../firebase_options.dart';

class BandService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

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
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createBand({
    required String deviceId,
    required String bandName,
    required String wearerName,
    required int age,
    required String address,
    required String bloodGroup,
    required String medicalConditions,
    required String doctorPhone,

    String? wearerEmail,
    String? wearerPassword,
  }) async {
    final user = auth.currentUser!;

    // Get owner's familyId
    final userDoc =
        await firestore.collection('users').doc(user.uid).get();

    final familyId = userDoc.data()?['familyId'];

    // Check if band already exists
    final existingBand = await firestore
        .collection('bands')
        .where('deviceId', isEqualTo: deviceId)
        .limit(1)
        .get();

    if (existingBand.docs.isNotEmpty) {
      throw Exception("This band is already registered.");
    }

    // Create band
    final bandRef = await firestore.collection('bands').add({
      'deviceId': deviceId,
      'ownerId': user.uid,
      'familyId': familyId,
      'bandName': bandName,
      'wearerName': wearerName,
      'age': age,
      'address': address,
      'bloodGroup': bloodGroup,
      'medicalConditions': medicalConditions,
      'doctorPhone': doctorPhone,
      'heartRate': 0,
      'steps': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Add OWNER
    await firestore.collection('bandMembers').add({
      'bandId': bandRef.id,
      'userId': user.uid,
      'role': 'OWNER',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Create WEARER account (optional)
    if (wearerEmail != null &&
        wearerPassword != null &&
        wearerEmail.isNotEmpty &&
        wearerPassword.isNotEmpty) {
      FirebaseApp secondaryApp;

      try {
        try {
          secondaryApp = Firebase.app('WearerApp');
        } catch (_) {
          secondaryApp = await Firebase.initializeApp(
            name: 'WearerApp',
            options: DefaultFirebaseOptions.currentPlatform,
          );
        }

        final secondaryAuth =
            FirebaseAuth.instanceFor(app: secondaryApp);

        final wearerCredential =
            await secondaryAuth.createUserWithEmailAndPassword(
          email: wearerEmail,
          password: wearerPassword,
        );

        final wearerUid = wearerCredential.user!.uid;

        // ============================
        // CREATE USERS DOCUMENT
        // ============================
        await firestore
            .collection('users')
            .doc(wearerUid)
            .set({
          'email': wearerEmail,
          'familyId': familyId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // ============================
        // ADD BAND MEMBER
        // ============================
        await firestore.collection('bandMembers').add({
          'bandId': bandRef.id,
          'userId': wearerUid,
          'role': 'WEARER',
          'createdAt': FieldValue.serverTimestamp(),
        });

        await secondaryAuth.signOut();
      } catch (e) {
        // Roll back the band if wearer creation fails
        await bandRef.delete();
        rethrow;
      }
    }
  }
}