import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saves/loads profile photos entirely on THIS device — no Firebase
/// Storage, no Firestore, no billing risk. The picked image is copied
/// into the app's local documents folder and its path is remembered in
/// SharedPreferences, keyed by whatever id you pass in (a band's
/// deviceId for a wearer's photo, or a user's uid for their own account
/// photo).
///
/// IMPORTANT LIMITATION: because nothing is uploaded anywhere, a photo
/// only ever shows up on the SAME phone that picked it. A caregiver on
/// a different phone will NOT see a wearer's photo picked during
/// pairing on the wearer's/admin's phone — there's no way around that
/// without syncing the image data through some backend. If you need the
/// photo to show on other family members' phones too, this isn't
/// enough on its own.
class LocalPhotoStore {
  static Future<String> savePhoto(String key, File source) async {
    final dir = await getApplicationDocumentsDirectory();

    final ext = source.path.contains('.')
        ? source.path.split('.').last
        : 'jpg';

    final dest = File('${dir.path}/profile_$key.$ext');

    await source.copy(dest.path);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('photo_$key', dest.path);

    return dest.path;
  }

  static Future<String?> getPhotoPath(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('photo_$key');

    if (path == null) return null;
    if (!await File(path).exists()) return null;

    return path;
  }

  static Future<void> clearPhoto(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('photo_$key');

    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }

    await prefs.remove('photo_$key');
  }
}