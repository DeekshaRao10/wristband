import 'package:flutter/material.dart';

/// Shared navigator key so code outside the widget tree — specifically
/// NotificationService, when a fall-alert push notification is tapped —
/// can push a screen (EmergencyScreen) without needing a BuildContext of
/// its own. That's necessary here because a notification tap can happen
/// before any screen has even been built yet (cold start: app was fully
/// closed, user taps the notification, and main() is still running
/// initNotifications() before runApp() has produced a single frame).
///
/// Wire this into MaterialApp's `navigatorKey` param in main.dart.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();