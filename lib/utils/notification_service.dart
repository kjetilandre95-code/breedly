import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:breedly/utils/logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  Future<void> initialize() async {
    if (kIsWeb) {
      return;
    }
    tzdata.initializeTimeZones();

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        AppLogger.debug('Notification tapped with payload: ${response.payload}');
        if (response.payload != null) {
          OpenFile.open(response.payload!);
        }
      },
    );

    AppLogger.debug('NotificationService initialized');

    // Create notification channels for Android 8+
    try {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'breedly_downloads',
              'Breedly Downloads',
              description: 'Notifications for downloads',
              importance: Importance.high,
              enableVibration: true,
              playSound: true,
            ),
          );
      AppLogger.debug('Notification channel "breedly_downloads" created');
    } catch (e) {
      AppLogger.debug('Error creating notification channel: $e');
    }

    try {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'breedly_channel',
              'Breedly Notifications',
              description: 'General notifications for Breedly app',
              importance: Importance.high,
              enableVibration: true,
              playSound: true,
            ),
          );
      AppLogger.debug('Notification channel "breedly_channel" created');
    } catch (e) {
      AppLogger.debug('Error creating notification channel: $e');
    }

    // Request notification permission for Android 13+
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final status = await Permission.notification.request();
        AppLogger.debug('Notification permission status: $status');
        if (status.isDenied) {
          AppLogger.debug('Notification permission denied');
        } else if (status.isGranted) {
          AppLogger.debug('Notification permission granted');
        } else if (status.isPermanentlyDenied) {
          AppLogger.debug(
              'Notification permission permanently denied, opening app settings');
          openAppSettings();
        }
      } catch (e) {
        AppLogger.debug('Error requesting notification permission: $e');
      }
    }
  }

  /// Schedule heat cycle reminder for a female dog
  Future<void> scheduleHeatCycleReminder({
    required int id,
    required String dogName,
    required DateTime estimatedHeatDate,
    int daysBeforeReminder = 7,
  }) async {
    if (kIsWeb) return;
    try {
      final reminderDate = estimatedHeatDate.subtract(Duration(days: daysBeforeReminder));
      
      // Only schedule if reminder date is in the future
      if (reminderDate.isAfter(DateTime.now())) {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          'Løpetid påminnelse',
          '$dogName kan komme i løpetid om ca. $daysBeforeReminder dager',
          tz.TZDateTime.from(reminderDate, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'breedly_channel',
              'Breedly Notifications',
              channelDescription: 'Notifications for Breedly app',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        AppLogger.debug('Scheduled heat cycle reminder for $dogName on $reminderDate');
      }
    } catch (e) {
      AppLogger.debug('Error scheduling heat cycle reminder: $e');
    }
  }

  /// Schedule mating window reminder (optimal breeding days 11-14 after heat starts)
  Future<void> scheduleMatingWindowReminder({
    required int id,
    required String dogName,
    required DateTime heatStartDate,
  }) async {
    if (kIsWeb) return;
    try {
      // Optimal mating window is days 11-14 from heat start
      final matingWindowStart = heatStartDate.add(const Duration(days: 11));
      
      // Only schedule if mating window is in the future
      if (matingWindowStart.isAfter(DateTime.now())) {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          'Parringsvindu starter',
          'Optimalt parringsvindu for $dogName starter nå (dag 11-14)',
          tz.TZDateTime.from(matingWindowStart, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'breedly_channel',
              'Breedly Notifications',
              channelDescription: 'Notifications for Breedly app',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        AppLogger.debug('Scheduled mating window reminder for $dogName on $matingWindowStart');
      }
    } catch (e) {
      AppLogger.debug('Error scheduling mating window reminder: $e');
    }
  }

  /// Schedule puppy delivery reminder for buyers
  Future<void> schedulePuppyDeliveryReminder({
    required int id,
    required String puppyName,
    required String buyerName,
    required DateTime deliveryDate,
    int daysBeforeReminder = 3,
  }) async {
    if (kIsWeb) return;
    try {
      final reminderDate = deliveryDate.subtract(Duration(days: daysBeforeReminder));
      
      if (reminderDate.isAfter(DateTime.now())) {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          'Valpelevering påminnelse',
          '$puppyName skal leveres til $buyerName om $daysBeforeReminder dager',
          tz.TZDateTime.from(reminderDate, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'breedly_channel',
              'Breedly Notifications',
              channelDescription: 'Notifications for Breedly app',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        AppLogger.debug('Scheduled puppy delivery reminder for $puppyName on $reminderDate');
      }
    } catch (e) {
      AppLogger.debug('Error scheduling puppy delivery reminder: $e');
    }
  }

  Future<void> scheduleWormerReminder({
    required int id,
    required String puppyName,
    required DateTime scheduleTime,
  }) async {
    if (kIsWeb) return;
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Ormekur påminnelse',
        'Det er tid til å avmask $puppyName',
        tz.TZDateTime.from(scheduleTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'breedly_channel',
            'Breedly Notifications',
            channelDescription: 'Notifications for Breedly app',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      AppLogger.debug('Error scheduling vaccination reminder: $e');
    }
  }

  Future<void> scheduleVaccineReminder({
    required int id,
    required String puppyName,
    required int vaccineNumber,
    required DateTime scheduleTime,
  }) async {
    if (kIsWeb) return;
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Vaksine påminnelse',
        '$vaccineNumber. vaksinering for $puppyName er klar',
        tz.TZDateTime.from(scheduleTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'breedly_channel',
            'Breedly Notifications',
            channelDescription: 'Notifications for Breedly app',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      AppLogger.debug('Error scheduling vaccine reminder: $e');
    }
  }

  Future<void> scheduleMicrochipReminder({
    required int id,
    required String puppyName,
    required DateTime scheduleTime,
  }) async {
    if (kIsWeb) return;
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'ID-merking påminnelse',
        'Husk å ID-merke $puppyName',
        tz.TZDateTime.from(scheduleTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'breedly_channel',
            'Breedly Notifications',
            channelDescription: 'Notifications for Breedly app',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      AppLogger.debug('Error scheduling microchip reminder: $e');
    }
  }

  Future<void> scheduleDeliveryReminder({
    required int id,
    required String damName,
    required DateTime dueDate,
  }) async {
    if (kIsWeb) return;
    try {
      final reminderDate = dueDate.subtract(const Duration(days: 1));

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Termin påminnelse',
        '$damName skal føde i morgen!',
        tz.TZDateTime.from(reminderDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'breedly_channel',
            'Breedly Notifications',
            channelDescription: 'Notifications for Breedly app',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      AppLogger.debug('Error scheduling delivery reminder: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    try {
      await flutterLocalNotificationsPlugin.cancel(id);
    } catch (e) {
      AppLogger.debug('Error canceling notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      AppLogger.debug('Error canceling all notifications: $e');
    }
  }

  Future<void> showDownloadNotification({
    required String title,
    required String fileName,
    required String filePath,
  }) async {
    if (kIsWeb) return;
    try {
      AppLogger.debug('Attempting to show notification: $title - $fileName');
      AppLogger.debug('File path: $filePath');

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'breedly_downloads',
        'Breedly Downloads',
        channelDescription: 'Notifications for downloads',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        timeoutAfter: 5000,
      );

      const NotificationDetails notificationDetails =
          NotificationDetails(android: androidDetails);

      await flutterLocalNotificationsPlugin.show(
        999,
        title,
        'Nedlastet: $fileName',
        notificationDetails,
        payload: filePath,
      );

      AppLogger.debug('Notification shown successfully');
    } catch (e) {
      AppLogger.debug('Error showing download notification: $e');
      AppLogger.debug(e.toString());
    }
  }
}
