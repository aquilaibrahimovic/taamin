import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io' show Platform; // ✅ Needed for platform checks

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
    'keuangan_updates',
    'Keuangan Updates',
    description: 'Notifikasi transaksi keuangan',
    importance: Importance.high,
  );

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
      linux: LinuxInitializationSettings(defaultActionName: 'Open'),
      windows: WindowsInitializationSettings(
        appName: 'Taamin',
        appUserModelId: 'com.robithenha.taamin',
        guid: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
      ),
    );

    await _local.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (resp) {
        // handle tap
      },
    );

    // Create Android channel
    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin =
      _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_androidChannel);
    }

    // ✅ FIX: Guard FCM calls. Windows does not support Firebase Messaging.
    // We only run these on Android, iOS, macOS, or Web.
    final bool isSupportedByFcm = kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

    if (isSupportedByFcm) {
      // FCM permission
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Foreground push -> show local/system notification
      FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
        final title = msg.notification?.title ?? 'Taamin';
        final body = msg.notification?.body ?? 'Ada pembaruan transaksi.';
        showLocal(title: title, body: body, payload: msg.data['payload']?.toString());
      });

      FirebaseMessaging.onMessageOpenedApp.listen((msg) {
        // handle tap when opened from background
      });

      try {
        await FirebaseMessaging.instance.subscribeToTopic('keuangan');
      } catch (e) {
        debugPrint('FCM Topic Subscription Error: $e');
      }
    } else {
      debugPrint('FCM is not supported on this platform. Skipping FCM initialization.');
    }
  }

  Future<void> showLocal({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Web: rely on Web Push via firebase_messaging + service worker
    if (kIsWeb) return;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
      // ✅ Added Windows details so local popups work on desktop
      windows: const WindowsNotificationDetails(),
    );

    await _local.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // This remains for platforms that support FCM background handling
}