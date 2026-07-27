import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Android requires every local notification to belong to a "channel".
  // This one is specifically for fall alerts, set to max importance/urgency
  // so it shows as a heads-up popup rather than silently sitting in the
  // notification tray.
  static const AndroidNotificationChannel _fallAlertChannel =
      AndroidNotificationChannel(
    'fall_alerts', // channel id
    'Fall Alerts', // channel name shown in phone settings
    description: 'Alerts sent when a SafeBand detects a fall',
    importance: Importance.max,
  );

  Future<void> initNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission();

    print("Permission: ${settings.authorizationStatus}");

    String? token = await messaging.getToken();

    print("FCM Token:");
    print(token);

    // Previously this token was only ever printed, never saved anywhere —
    // the listener script that sends the fall-detected push needs to read it
    // from users/{uid}.fcmToken, so save it here too (not just at login in
    // auth_service.dart). This also covers users who stay logged in across
    // app restarts, since Firebase Auth persists the session.
    await _saveTokenToFirestore(token);

    // FCM tokens can rotate (e.g. after app reinstall, or periodically).
    // Keep Firestore in sync whenever that happens, so the saved token never
    // goes stale.
    messaging.onTokenRefresh.listen(_saveTokenToFirestore);

    await _initLocalNotifications();

    // IMPORTANT: Android/iOS only auto-show a system popup for a push
    // notification when the app is in the background or fully closed. If
    // the app is open in the foreground at the moment the push arrives, the
    // OS deliberately stays silent and just hands the message to our code
    // instead — so without this listener, a fall alert that arrives while
    // someone has the app open would show nothing at all. This catches that
    // case and draws the popup ourselves.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground FCM message received: ${message.messageId}");
      _showLocalNotification(message);
    });
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidInit);

    await _localNotifications.initialize(initSettings);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_fallAlertChannel);
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;

    if (notification == null) return;

    _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _fallAlertChannel.id,
          _fallAlertChannel.name,
          channelDescription: _fallAlertChannel.description,
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> _saveTokenToFirestore(String? token) async {
    if (token == null) return;

    final user = _auth.currentUser;

    if (user == null) {
      // Nobody is logged in yet (e.g. this ran before the user signed in).
      // auth_service.dart's login() saves the token once they do log in;
      // this just covers every app start after that for already-logged-in
      // users.
      return;
    }

    await _firestore.collection('users').doc(user.uid).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );

    print("FCM token saved to Firestore for user ${user.uid}");
  }
}

