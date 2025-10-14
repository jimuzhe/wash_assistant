import 'dart:async';

import '../models/washer_device.dart';

typedef DeviceAvailableCallback = void Function(
  WasherDevice device,
  int remainingMinutes,
);

typedef QueueUpdateCallback = void Function(List<WasherDevice> queue);

typedef NextReminderCallback = void Function(
  WasherDevice? device,
  Duration? delay,
);

class ReminderQueueController {
  ReminderQueueController({
    required this.onDeviceAvailable,
    required this.onQueueUpdate,
    required this.onNextSchedule,
  });

  final DeviceAvailableCallback onDeviceAvailable;
  final QueueUpdateCallback onQueueUpdate;
  final NextReminderCallback onNextSchedule;

  Timer? _timer;
  final List<WasherDevice> _queue = [];
  final Set<String> _excludedCodes = {};
  final List<WasherDevice> _lastDevices = [];
  bool _isActive = false;
  DateTime? _nextTriggerAt;
  int _reminderLeadMinutes = 0;

  bool get isActive => _isActive;

  List<WasherDevice> get queue => List.unmodifiable(_queue);

  Set<String> get excludedCodes => Set.unmodifiable(_excludedCodes);

  DateTime? get nextTriggerAt => _nextTriggerAt;

  void setInitialExcludedCodes(Set<String> codes) {
    _excludedCodes
      ..clear()
      ..addAll(codes);
  }

  void updateReminderLeadMinutes(int minutes) {
    _reminderLeadMinutes = minutes.clamp(0, 120);
    if (_queue.isNotEmpty) {
      _scheduleNextTick();
    }
  }

  void updateQueue(List<WasherDevice> devices) {
    _lastDevices
      ..clear()
      ..addAll(devices);
    if (!_isActive) {
      return;
    }
    _queue
      ..clear()
      ..addAll(devices.where(_isEligibleDevice).toList()
        ..sort((a, b) => a.surplusTime.compareTo(b.surplusTime)));
    if (_queue.isEmpty) {
      _nextTriggerAt = null;
      onQueueUpdate(queue);
      onNextSchedule(null, null);
      return;
    }
    onQueueUpdate(queue);
    _scheduleNextTick();
  }

  void start(List<WasherDevice> devices) {
    _isActive = true;
    updateQueue(devices);
  }

  void stop() {
    _isActive = false;
    _queue.clear();
    _timer?.cancel();
    _timer = null;
    _nextTriggerAt = null;
    onQueueUpdate(queue);
    onNextSchedule(null, null);
  }

  bool toggleExclude(String code) {
    final bool isNowExcluded;
    if (_excludedCodes.contains(code)) {
      _excludedCodes.remove(code);
      isNowExcluded = false;
    } else {
      _excludedCodes.add(code);
      isNowExcluded = true;
    }
    if (_lastDevices.isNotEmpty) {
      updateQueue(List<WasherDevice>.from(_lastDevices));
    }
    return isNowExcluded;
  }

  bool isExcluded(String code) => _excludedCodes.contains(code);

  void dispose() {
    _timer?.cancel();
  }

  bool _isEligibleDevice(WasherDevice device) {
    if (device.isInMaintenance) {
      return false;
    }
    if (device.isAvailable) {
      return false;
    }
    if (isExcluded(device.code)) {
      return false;
    }
    return true;
  }

  void _scheduleNextTick() {
    _timer?.cancel();
    if (_queue.isEmpty) {
      _nextTriggerAt = null;
      onNextSchedule(null, null);
      return;
    }
    final top = _queue.first;
    final originalMinutes = top.surplusTime;
    var minutes = originalMinutes - _reminderLeadMinutes;
    if (minutes < 0) {
      minutes = 0;
    }
    Duration delay;
    if (minutes == 0) {
      delay = Duration.zero;
    } else {
      delay = Duration(minutes: minutes);
    }
    _nextTriggerAt = DateTime.now().add(delay);
    onNextSchedule(top, delay);
    _timer = Timer(delay, () {
      final remaining = originalMinutes > _reminderLeadMinutes
          ? _reminderLeadMinutes
          : originalMinutes;
      onDeviceAvailable(top, remaining.clamp(0, 120));
      _queue.remove(top);
      onQueueUpdate(queue);
      _scheduleNextTick();
    });
  }
}
