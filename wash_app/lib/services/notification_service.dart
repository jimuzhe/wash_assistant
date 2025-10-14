import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const _availabilityChannelId = 'washer_availability_channel';
  static const _availabilityChannelName = '可用洗衣机提醒';
  static const _countdownNotificationId = 9999;

  Future<void> initialize() async {
    if (kIsWeb) {
      _initialized = true;
      return;
    }
    if (_initialized) {
      return;
    }
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    await _plugin.initialize(settings);

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
    _initialized = true;
  }

  Future<void> scheduleAvailabilityNotification({
    required int id,
    required String title,
    required String body,
    required Duration delay,
  }) async {
    if (kIsWeb) {
      return;
    }
    if (!_initialized) {
      await initialize();
    }
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.now(tz.local).add(delay),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _availabilityChannelId,
          _availabilityChannelName,
          channelDescription: '提醒用户洗衣机可用',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentBadge: true,
          presentSound: true,
          presentAlert: true,
        ),
      ),
      androidAllowWhileIdle: true,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  Future<void> cancelReminder(int id) async {
    if (kIsWeb) {
      return;
    }
    if (!_initialized) {
      await initialize();
    }
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    if (kIsWeb) {
      return;
    }
    if (!_initialized) {
      await initialize();
    }
    await _plugin.cancelAll();
  }

  Future<void> showCountdownNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) {
      return;
    }
    if (!_initialized) {
      await initialize();
    }
    await _plugin.show(
      _countdownNotificationId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _availabilityChannelId,
          _availabilityChannelName,
          channelDescription: '提醒用户洗衣机可用',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          onlyAlertOnce: true,
          showWhen: false,
        ),
        iOS: DarwinNotificationDetails(
          presentSound: false,
          presentAlert: true,
        ),
      ),
    );
  }

  Future<void> hideCountdownNotification() async {
    if (kIsWeb) {
      return;
    }
    if (!_initialized) {
      await initialize();
    }
    await _plugin.cancel(_countdownNotificationId);
  }

  Future<void> showLeadTimeReminder({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) {
      return;
    }
    if (!_initialized) {
      await initialize();
    }
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _availabilityChannelId,
          _availabilityChannelName,
          channelDescription: '提醒用户洗衣机即将空闲',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentBadge: true,
          presentSound: true,
          presentAlert: true,
        ),
      ),
    );
  }
}
