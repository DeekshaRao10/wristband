import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/services/navigation_service.dart';
import '../features/emergency/screens/emergency_screen.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  
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

    
    await _saveTokenToFirestore(token);

 
    messaging.onTokenRefresh.listen(_saveTokenToFirestore);

    await _initLocalNotifications();

   
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground FCM message received: ${message.messageId}");
      _showLocalNotification(message);
    });

    
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notification tapped (app was backgrounded): ${message.messageId}");
      _handleMessageTap(message);
    });

    
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      print("App launched from a terminated state via notification tap");
      _handleMessageTap(initialMessage);
    }
  }


  void _handleMessageTap(RemoteMessage message) {
    if (message.data['type'] != 'FALL_DETECTED') return;

    final bandId = message.data['deviceId'];
    if (bandId == null || bandId.isEmpty) return;

    _openEmergencyScreen(bandId);
  }

 
  void _openEmergencyScreen(String bandId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => EmergencyScreen(bandId: bandId, alertData: const {}),
        ),
      );
    });
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidInit);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        final bandId = details.payload;
        if (bandId != null && bandId.isNotEmpty) {
          _openEmergencyScreen(bandId);
        }
      },
    );

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
      
      payload: message.data['deviceId'],
    );
  }

  Future<void> _saveTokenToFirestore(String? token) async {
    if (token == null) return;

    final user = _auth.currentUser;

    if (user == null) {
   
      return;
    }

    await _firestore.collection('users').doc(user.uid).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );

    print("FCM token saved to Firestore for user ${user.uid}");
  }
}