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
    print("BandService: createBand() started");

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

    // Create band. wearerUid defaults to the admin's own uid — covers
    // the "You" case (the person setting this up is the one wearing the
    // band). If a separate wearer account gets created below, this is
    // updated to that wearer's uid instead. Screens compare this against
    // FirebaseAuth.instance.currentUser?.uid to show "You" instead of a
    // name wherever the wearer is displayed.
    final bandRef = await firestore.collection('bands').add({
      'deviceId': deviceId,
      'ownerId': user.uid,
      'familyId': familyId,
      'bandName': bandName,
      'wearerName': wearerName,
      'wearerUid': user.uid,
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

        print("==================================");
print("Creating wearer Firebase account");
print("Email: $wearerEmail");
print("Password length: ${wearerPassword.length}");

final secondaryAuth =
    FirebaseAuth.instanceFor(app: secondaryApp);

print("Calling createUserWithEmailAndPassword()...");

final wearerCredential =
    await secondaryAuth.createUserWithEmailAndPassword(
  email: wearerEmail,
  password: wearerPassword,
);

print("Firebase Auth account created!");
print("Wearer UID = ${wearerCredential.user!.uid}");

final wearerUid = wearerCredential.user!.uid;

        // A separate wearer account was created — this band's wearer is
        // no longer the admin, so correct wearerUid to point at them.
        await bandRef.update({'wearerUid': wearerUid});

        // Create wearer user document
        await firestore.collection('users').doc(wearerUid).set({
          'name': wearerName,
          'email': wearerEmail,
          'familyId': familyId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Add wearer to band
        await firestore.collection('bandMembers').add({
          'bandId': bandRef.id,
          'userId': wearerUid,
          'role': 'WEARER',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Also add the wearer to the FAMILY's members subcollection — this
        // was missing before, which meant a wearer created here would never
        // show up in FamilyMembersScreen (which only reads
        // families/{familyId}/members). Without this, only Admin/Member
        // accounts created via family_service.dart's createFamily/joinFamily
        // ever appeared in the members list.
        if (familyId != null &&
            familyId.toString().isNotEmpty) {
          await firestore
              .collection('families')
              .doc(familyId)
              .collection('members')
              .doc(wearerUid)
              .set({
            'uid': wearerUid,
            'name': wearerName,
            'email': wearerEmail,
            'role': 'Wearer',
            'familyId': familyId,
            'joinedAt': FieldValue.serverTimestamp(),
          });
        }

        await secondaryAuth.signOut();
      } on FirebaseAuthException catch (e) {
  print("==================================");
  print("FirebaseAuthException");
  print("Code: ${e.code}");
  print("Message: ${e.message}");
  print("==================================");

  await bandRef.delete();
  rethrow;
} catch (e, st) {
  print("==================================");
  print("Unknown Exception");
  print(e);
  print(st);
  print("==================================");

  await bandRef.delete();
  rethrow;
}
        }
  }
}