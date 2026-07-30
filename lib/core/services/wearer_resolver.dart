import 'package:cloud_firestore/cloud_firestore.dart';
 
/// Resolves the uid of the person actually wearing a band — but ONLY
/// when there's a genuine, explicit link between this specific band and
/// a real signed-in wearer account. Deliberately does NOT fall back to
/// ownerId: that was tried before and caused "You" to show on every
/// single band the admin owns (since ownerId is identical across all of
/// them), instead of only the one band that person actually wears.
///
/// Resolution order:
///   1. If the band doc already has wearerUid set, use it directly —
///      the fast path, and what every new band will hit (band_service.
///      dart writes this at creation time).
///   2. Otherwise, look up bandMembers for a WEARER-role entry tied to
///      THIS specific bandId. band_service.dart always writes this doc
///      whenever a separate wearer Firebase account was created, even
///      for older bands, so this reliably finds the real wearer uid
///      without guessing.
///   3. Otherwise, return '' (no known wearer account) — the UI will
///      just show the stored wearerName for everyone, which is correct:
///      nobody should see "You" on a band unless the actual wearer
///      signed in.
///
/// Whatever gets resolved via (2) is written back onto the band doc as
/// wearerUid, so this lookup only ever runs once per band — every later
/// load after that hits the fast path in step 1.
Future<String> resolveWearerUid({
  required String bandId,
  required String rawWearerUid,
}) async {
  if (rawWearerUid.isNotEmpty) return rawWearerUid;
 
  String resolved = '';
 
  try {
    final memberQuery = await FirebaseFirestore.instance
        .collection('bandMembers')
        .where('bandId', isEqualTo: bandId)
        .where('role', isEqualTo: 'WEARER')
        .limit(1)
        .get();
 
    if (memberQuery.docs.isNotEmpty) {
      resolved = memberQuery.docs.first.data()['userId'] ?? '';
    }
  } catch (_) {
    // If the lookup fails for any reason, just leave resolved empty —
    // that's the safe default (shows the name, not "You").
  }
 
  if (bandId.isNotEmpty && resolved.isNotEmpty) {
    // Best-effort backfill so this lookup isn't needed again next time.
    FirebaseFirestore.instance
        .collection('bands')
        .doc(bandId)
        .update({'wearerUid': resolved}).catchError((_) {});
  }
 
  return resolved;
}
 
