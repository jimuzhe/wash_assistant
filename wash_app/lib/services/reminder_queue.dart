import 'dart:async';

import '../models/washer_device.dart';

typedef DeviceReminderCallback = void Function(
  WasherDevice device,
  int stageMinutes,
  bool isFinal,
);

typedef QueueUpdateCallback = void Function(List<WasherDevice> queue);

typedef NextReminderCallback = void Function(
  WasherDevice? device,
  Duration? delay,
  int? stageMinutes,
  bool isFinalStage,
);

class ReminderQueueController {
  ReminderQueueController({
    required this.onReminder,
    required this.onQueueUpdate,
    required this.onNextSchedule,
  });

  final DeviceReminderCallback onReminder;
  final QueueUpdateCallback onQueueUpdate;
  final NextReminderCallback onNextSchedule;

  Timer? _timer;
  final List<WasherDevice> _queue = [];
  final Set<String> _excludedCodes = {};
  final List<WasherDevice> _lastDevices = [];
  bool _isActive = false;
  DateTime? _nextTriggerAt;
  int _reminderLeadMinutes = 0;
  final Map<int, Set<int>> _firedStages = {};
  final Map<int, int> _stageBaseMinutes = {};

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
    _reschedule();
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
    _firedStages.removeWhere(
      (key, value) => !_queue.any((device) => device.id == key),
    );
    _stageBaseMinutes
      ..removeWhere(
        (key, value) => !_queue.any((device) => device.id == key),
      );
    for (final device in _queue) {
      _stageBaseMinutes[device.id] = device.surplusTime;
    }
    if (_queue.isEmpty) {
      _nextTriggerAt = null;
      onQueueUpdate(queue);
      onNextSchedule(null, null, null, false);
      return;
    }
    onQueueUpdate(queue);
    _scheduleNextTick();
  }

  void start(List<WasherDevice> devices) {
    _isActive = true;
    _firedStages.clear();
    _stageBaseMinutes.clear();
    updateQueue(devices);
  }

  void stop() {
    _isActive = false;
    _queue.clear();
    _timer?.cancel();
    _timer = null;
    _nextTriggerAt = null;
    _firedStages.clear();
    _stageBaseMinutes.clear();
    onQueueUpdate(queue);
    onNextSchedule(null, null, null, false);
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

  void _reschedule() {
    if (!_isActive) {
      return;
    }
    _timer?.cancel();
    _scheduleNextTick();
  }

  void _scheduleNextTick() {
    _timer?.cancel();
    if (_queue.isEmpty) {
      _nextTriggerAt = null;
      onNextSchedule(null, null, null, false);
      return;
    }
    final top = _queue.first;
    final baseMinutes = _stageBaseMinutes[top.id] ?? top.surplusTime;
    _stageBaseMinutes[top.id] = baseMinutes;
    final stages = _resolveStages(baseMinutes);
    final fired = _firedStages.putIfAbsent(top.id, () => <int>{});
    int? nextStage;
    for (final stage in stages) {
      if (!fired.contains(stage)) {
        nextStage = stage;
        break;
      }
    }
    if (nextStage == null) {
      _queue.remove(top);
      _firedStages.remove(top.id);
      _stageBaseMinutes.remove(top.id);
      onQueueUpdate(queue);
      _scheduleNextTick();
      return;
    }

    Duration delay;
    if (nextStage == 0) {
      delay = Duration(minutes: baseMinutes);
    } else {
      delay = Duration(minutes: baseMinutes - nextStage);
    }
    _nextTriggerAt = DateTime.now().add(delay);
    onNextSchedule(top, delay, nextStage, nextStage == 0);
    _timer = Timer(delay, () {
      fired.add(nextStage!);
      final isFinal = nextStage == 0;
      if (isFinal) {
        _stageBaseMinutes[top.id] = 0;
      } else {
        _stageBaseMinutes[top.id] = nextStage!;
      }
      onReminder(top, nextStage!, isFinal);
      _scheduleNextTick();
    });
  }

  List<int> _resolveStages(int originalMinutes) {
    final stages = <int>[];
    final desiredStages = <int>{5, 3, 1};
    if (_reminderLeadMinutes > 0) {
      desiredStages.add(_reminderLeadMinutes);
    }
    desiredStages.add(0);
    for (final stage in desiredStages) {
      if (stage == 0 || originalMinutes >= stage) {
        stages.add(stage);
      }
    }
    stages.sort((a, b) => b.compareTo(a));
    return stages;
  }
}
