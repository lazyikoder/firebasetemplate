import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yogtrackteacher/app/services/app_services.dart';
import 'colors_uitl.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // FlutterAppBadger.removeBadge();//TODO: badger login
  await Firebase.initializeApp();
  debugPrint("Background Message Handler Working...");

  try {
    await Future.delayed(const Duration(seconds: 2));
    AppServices.saveNotification(message);
  } catch (e) {
    debugPrint(e.toString());
  }
}

class FirebaseMessagingUtil {
  Future<void> setupInteractedMessage() async {
    try {
      await Permission.notification.isDenied.then((value) {
        if (value) {
          Permission.notification.request();
        }
      });
      FirebaseMessaging.onMessageOpenedApp
          .listen((RemoteMessage message) async {
        // FlutterAppBadger.removeBadge();//TODO: badge can be added is needed.
        await Future.delayed(const Duration(seconds: 2));
        AppServices.saveNotification(message);
      });
      enableIOSNotifications();
      await registerNotificationListeners();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> registerNotificationListeners() async {
    final AndroidNotificationChannel channel = androidNotificationChannel();
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('noti');
    const DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings(
            requestSoundPermission: true,
            requestBadgePermission: true,
            requestAlertPermission: true);
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings, iOS: iOSSettings);
    flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );
    try {
      FirebaseMessaging.onBackgroundMessage((message) async =>
          await _firebaseMessagingBackgroundHandler(message));
    } catch (e) {
      debugPrint(e.toString());
    }
    FirebaseMessaging.onMessage.listen((RemoteMessage? message) {
      if (message == null) return;
      // FlutterAppBadger.updateBadgeCount(1);/TODO: badge can be added is needed.

      final RemoteNotification? notification = message.notification;
      final AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(channel.id, channel.name,
                channelDescription: channel.description,
                icon: "noti",
                color: ColorUtil.primary),
          ),
          payload: message.data.toString(),
        );
      }
      AppServices.saveNotification(message);
    });
  }

  void _onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      Map<String, dynamic> data = json.decode(payload);
      data.toString();
    }
  }

  Future<void> enableIOSNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true, // Required to display a heads up notification
      badge: true,
      sound: true,
    );
  }

  AndroidNotificationChannel androidNotificationChannel() =>
      const AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        description:
            'This channel is used for important notifications.', // description
        importance: Importance.max,
      );

  Future<void> subFcm(String topic) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> unsubFcm(String topic) async {
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
  }
}
