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
  static const _ownedBaseMultiplier = 1000;
  static const _ownedOngoingOffset = 98;

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

  Future<void> showOwnedProgressNotification({
    required int deviceId,
    required String code,
    required String name,
    required DateTime finishAt,
  }) async {
    if (kIsWeb) {
      return;
    }
    if (!_initialized) {
      await initialize();
    }
    final baseId = _ownedBaseId(deviceId) + _ownedOngoingOffset;
    final remaining = finishAt.difference(DateTime.now());
    final isDue = remaining.isNegative;
    final body = isDue
        ? '$name($code) 已完成洗涤'
        : '预计 ${_formatDuration(remaining)} 后完成';
    await _plugin.show(
      baseId,
      '$name 正在洗涤',
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _availabilityChannelId,
          _availabilityChannelName,
          channelDescription: '实时显示已标记洗衣机剩余时间',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          ongoing: true,
          onlyAlertOnce: true,
          showWhen: false,
        ),
        iOS: const DarwinNotificationDetails(
          presentSound: false,
          presentAlert: true,
        ),
      ),
    );
  }

  Future<void> scheduleOwnedDeviceReminders({
    required int deviceId,
    required String code,
    required String name,
    required DateTime finishAt,
  }) async {
    if (kIsWeb) {
      return;
    }
    if (!_initialized) {
      await initialize();
    }
    await cancelOwnedDeviceReminders(deviceId);

    final now = DateTime.now();
    if (finishAt.isBefore(now)) {
      await showOwnedProgressNotification(
        deviceId: deviceId,
        code: code,
        name: name,
        finishAt: finishAt,
      );
      return;
    }

    await showOwnedProgressNotification(
      deviceId: deviceId,
      code: code,
      name: name,
      finishAt: finishAt,
    );

    final baseId = _ownedBaseId(deviceId);
    final tzFinish = tz.TZDateTime.from(finishAt, tz.local);

    const stages = [5, 3, 1];
    for (final stage in stages) {
      final trigger = finishAt.subtract(Duration(minutes: stage));
      if (trigger.isAfter(now)) {
        final tzTrigger = tz.TZDateTime.from(trigger, tz.local);
        await _plugin.zonedSchedule(
          baseId + stage,
          '洗衣机即将空闲',
          '$name($code) 约 $stage 分钟后空闲',
          tzTrigger,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _availabilityChannelId,
              _availabilityChannelName,
              channelDescription: '提醒用户洗衣机即将空闲',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentBadge: true,
              presentSound: true,
              presentAlert: true,
            ),
          ),
          androidAllowWhileIdle: true,
          androidScheduleMode: AndroidScheduleMode.alarmClock,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }

    await _plugin.zonedSchedule(
      baseId,
      '请取衣服',
      '$name($code) 已完成洗涤，请及时取衣物',
      tzFinish,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _availabilityChannelId,
          _availabilityChannelName,
          channelDescription: '提醒用户及时取走衣物',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentBadge: true,
          presentSound: true,
          presentAlert: true,
        ),
      ),
      androidAllowWhileIdle: true,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelOwnedDeviceReminders(int deviceId) async {
    if (kIsWeb) {
      return;
    }
    if (!_initialized) {
      await initialize();
    }
    final baseId = _ownedBaseId(deviceId);
    final ids = <int>{
      baseId,
      baseId + 1,
      baseId + 3,
      baseId + 5,
      baseId + _ownedOngoingOffset,
    };
    for (final id in ids) {
      await _plugin.cancel(id);
    }
  }

  int _ownedBaseId(int deviceId) => deviceId * _ownedBaseMultiplier;

  String _formatDuration(Duration duration) {
    if (duration.isNegative) {
      return '已完成';
    }
    if (duration.inMinutes >= 60) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      return '$hours 小时 ${minutes.toString().padLeft(2, '0')} 分钟';
    }
    if (duration.inMinutes >= 1) {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds.remainder(60);
      return '$minutes 分钟 ${seconds.toString().padLeft(2, '0')} 秒';
    }
    return '${duration.inSeconds} 秒';
  }
}
