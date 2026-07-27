import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class AlertListener {
  StreamSubscription<DatabaseEvent>? _subscription;

  bool _ignoreFirstSnapshot = true;

  // Tracks the last known fallDetected value so onEmergency() only fires
  // on a false -> true TRANSITION, not on every single update while a
  // fall is already active. The ESP32 re-uploads fallDetected: true every
  // ~5s for the whole emergency window, so without this the Emergency
  // Screen would get pushed again and again every 5s during one active
  // fall, and would also pop right back open in the few seconds after
  // "I'm OK" is pressed — before the band's own cancel-check has had a
  // chance to actually clear fallDetected in RTDB.
  bool _lastFallState = false;

  void startListening({
    required String bandId,
    required Function(Map<String, dynamic>) onEmergency,
  }) {
    _subscription?.cancel();

    _ignoreFirstSnapshot = true;
    _lastFallState = false;

    print("==================================");
    print("Starting Realtime Database Listener");
    print("Listening on band: $bandId");
    print("==================================");

    final database = FirebaseDatabase.instanceFor(
  app: Firebase.app(),
  databaseURL:
      'https://safeband-a3b89-default-rtdb.asia-southeast1.firebasedatabase.app',
);

_subscription = database
    .ref("bands/$bandId")
    .onValue
    .listen((event) {
      final snapshot = event.snapshot;

      if (!snapshot.exists) {
        print("Band data not found.");
        return;
      }

      final data =
          Map<String, dynamic>.from(snapshot.value as Map);

      print("Realtime data: $data");

      if (_ignoreFirstSnapshot) {
        _ignoreFirstSnapshot = false;

        // Still record whatever fall state we started at, so if a fall
        // is already active when the listener attaches, the very next
        // update (still true) isn't mistaken for a brand new one.
        _lastFallState = data['fallDetected'] ?? false;

        print("Initial snapshot ignored.");
        return;
      }

      final bool fallDetected =
          data['fallDetected'] ?? false;

      if (fallDetected && !_lastFallState) {
        print(">>> OPENING EMERGENCY SCREEN <<<");

        onEmergency(data);
      }

      _lastFallState = fallDetected;
    });
  }

  void stopListening() {
    _subscription?.cancel();
  }
}
