import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'models/washer_config.dart';
import 'models/washer_device.dart';
import 'services/device_manager.dart';
import 'services/notification_service.dart';
import 'services/prefs_service.dart';
import 'services/reminder_queue.dart';
import 'services/washer_config_service.dart';
import 'services/washer_repository.dart';
import 'ui/theme.dart';
import 'ui/washer_settings_page.dart';

class HomeTabs extends StatefulWidget {
  const HomeTabs({super.key});

  @override
  State<HomeTabs> createState() => _HomeTabsState();
}

class _StatsOverview extends StatelessWidget {
  const _StatsOverview({
    required this.total,
    required this.available,
    required this.busy,
    required this.maintenance,
  });

  final int total;
  final int available;
  final int busy;
  final int maintenance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(24),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            _StatTile(
              title: '总设备',
              value: total,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            _StatTile(
              title: '可用',
              value: available,
              color: theme.colorScheme.tertiary,
            ),
            const SizedBox(width: 12),
            _StatTile(
              title: '忙碌',
              value: busy,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(width: 12),
            _StatTile(
              title: '维护',
              value: maintenance,
              color: theme.colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: color.withOpacity(0.08),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTabsState extends State<HomeTabs> {
  int _currentIndex = 0;
  WasherConfig? _config;
  bool _isLoadingConfig = true;
  final WasherConfigService _configService = WasherConfigService();
  final GlobalKey<_WasherDashboardPageState> _dashboardKey =
      GlobalKey<_WasherDashboardPageState>();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await _configService.loadConfig();
    if (!mounted) {
      return;
    }
    setState(() {
      _config = config;
      _isLoadingConfig = false;
    });
  }

  void _handleConfigChanged(WasherConfig config) {
    setState(() {
      _config = config;
    });
    _dashboardKey.currentState?.applyConfig(config);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      WasherDashboardPage(key: _dashboardKey),
      if (_isLoadingConfig)
        const Center(child: CircularProgressIndicator())
      else
        WasherSettingsPage(
          initialConfig: _config!,
          configService: _configService,
          onConfigChanged: _handleConfigChanged,
          closeOnSave: false,
        ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

void main() {
  runApp(const MyApp());
}

class _CompactDeviceTile extends StatelessWidget {
  const _CompactDeviceTile({
    required this.device,
    required this.isExcluded,
    required this.onToggleExclude,
    required this.onDelete,
  });

  final WasherDevice device;
  final bool isExcluded;
  final Future<void> Function(String code) onToggleExclude;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _DeviceCard._statusColor(device, colorScheme);
    final statusStyle = theme.textTheme.titleSmall?.copyWith(
      color: statusColor,
      fontWeight: FontWeight.w600,
    );

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onLongPress: onDelete,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _DeviceCard._statusIcon(device),
                      color: statusColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name.isNotEmpty ? device.name : device.code,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          device.location.isNotEmpty
                              ? device.location
                              : '位置信息待更新',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    tooltip: '更多操作',
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        builder: (sheetContext) {
                          return SafeArea(
                            child: Wrap(
                              children: [
                                ListTile(
                                  leading: Icon(
                                    isExcluded
                                        ? Icons.remove_circle_outline
                                        : Icons.add_circle_outline,
                                  ),
                                  title: Text(isExcluded ? '恢复提醒' : '排除提醒'),
                                  onTap: () {
                                    Navigator.of(sheetContext).pop();
                                    onToggleExclude(device.code);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.delete_outline),
                                  title: const Text('移除设备'),
                                  onTap: () {
                                    Navigator.of(sheetContext).pop();
                                    onDelete();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                device.statusLabel,
                style: statusStyle,
              ),
              const SizedBox(height: 4),
              Text(
                device.availabilityDetail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.badge_outlined,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      device.deviceCode,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      isExcluded
                          ? Icons.remove_circle_outline
                          : Icons.add_circle_outline,
                      size: 18,
                    ),
                    tooltip: isExcluded ? '恢复提醒' : '排除提醒',
                    onPressed: () {
                      onToggleExclude(device.code);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '校园洗衣机助手',
      debugShowCheckedModeBanner: false,
      theme: buildWasherTheme(),
      home: const HomeTabs(),
    );
  }
}

class WasherDashboardPage extends StatefulWidget {
  const WasherDashboardPage({super.key});

  @override
  State<WasherDashboardPage> createState() => _WasherDashboardPageState();
}

class _WasherDashboardPageState extends State<WasherDashboardPage> {
  final WasherRepository _repository = WasherRepository();
  final PrefsService _prefsService = PrefsService();
  final NotificationService _notificationService = NotificationService();
  final DeviceManager _deviceManager = DeviceManager();
  final WasherConfigService _configService = WasherConfigService();
  late ReminderQueueController _queueController;
  late Future<List<WasherDevice>> _devicesFuture;
  List<String> _deviceCodes = [];
  WasherConfig _config = WasherConfig.defaultConfig();
  StreamSubscription<DateTime>? _countdownSub;
  Duration? _nextDelay;
  WasherDevice? _nextDevice;
  bool _useCompactCards = false;

  @override
  void initState() {
    super.initState();
    _queueController = ReminderQueueController(
      onDeviceAvailable: _handleDeviceAvailable,
      onQueueUpdate: _handleQueueUpdate,
      onNextSchedule: _handleNextSchedule,
    );
    _devicesFuture = Future.value(const []);
    _initializeState();
  }

  Future<void> _refreshDevices() async {
    final future = _repository.fetchDevices(_deviceCodes);
    setState(() {
      _devicesFuture = future;
    });
    await future;
  }

  Future<void> _initializeState() async {
    await _notificationService.initialize();
    final config = await _configService.loadConfig();
    _repository.updateConfig(config);
    final excluded = await _prefsService.loadExcludedCodes();
    _queueController.setInitialExcludedCodes(excluded);
    _queueController.updateReminderLeadMinutes(config.reminderLeadMinutes);
    final useCompact = await _prefsService.loadCompactLayout();
    final codes = await _deviceManager.loadDeviceCodes();
    if (!mounted) {
      return;
    }
    setState(() {
      _config = config;
      _deviceCodes = codes;
      _useCompactCards = useCompact;
      _devicesFuture = _repository.fetchDevices(_deviceCodes);
    });
  }

  void applyConfig(WasherConfig config) {
    _repository.updateConfig(config);
    setState(() {
      _config = config;
      _devicesFuture = _repository.fetchDevices(_deviceCodes);
    });
    _queueController.updateReminderLeadMinutes(config.reminderLeadMinutes);
  }

  Future<void> _startReminder(List<WasherDevice> devices) async {
    await _notificationService.cancelAll();
    _queueController.updateReminderLeadMinutes(_config.reminderLeadMinutes);
    _queueController.start(devices);
    if (_queueController.queue.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('暂无符合条件的设备进入提醒队列'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _stopReminder() async {
    await _notificationService.hideCountdownNotification();
    await _notificationService.cancelAll();
    _queueController.stop();
    _countdownSub?.cancel();
    setState(() {
      _nextDevice = null;
      _nextDelay = null;
    });
  }

  @override
  void dispose() {
    _queueController.dispose();
    _countdownSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('校园洗衣机状态'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: '扫码添加',
            onPressed: () => _showScanSheet(),
          ),
          IconButton(
            icon: const Icon(Icons.manage_search),
            tooltip: '管理设备',
            onPressed: () => _openManageDevices(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: () => _refreshDevices(),
          ),
          IconButton(
            icon: Icon(_useCompactCards ? Icons.view_agenda_outlined : Icons.grid_view),
            tooltip: _useCompactCards ? '切换大卡片视图' : '切换小卡片网格',
            onPressed: () {
              setState(() {
                _useCompactCards = !_useCompactCards;
              });
              unawaited(_prefsService.saveCompactLayout(_useCompactCards));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '设置',
            onPressed: () => _openSettings(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDevices,
        child: FutureBuilder<List<WasherDevice>>(
          future: _devicesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 320,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                          size: 40,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '设备列表获取失败',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: _refreshDevices,
                            icon: const Icon(Icons.refresh),
                            label: const Text('重新加载'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final devices = snapshot.data ?? <WasherDevice>[];
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) {
                return;
              }
              _queueController.updateQueue(devices);
            });
            final hasAvailable = devices.any((device) => device.isAvailable);
            final totalDevices = devices.length;
            final availableCount = devices.where((device) => device.isAvailable).length;
            final busyCount = devices.where((device) => device.isBusy).length;
            final maintenanceCount = devices.where((device) => device.isInMaintenance).length;

            final eligibleDevices = List<WasherDevice>.from(devices.where((device) {
              if (device.isInMaintenance) {
                return false;
              }
              if (device.isAvailable) {
                return false;
              }
              if (_queueController.isExcluded(device.code)) {
                return false;
              }
              return true;
            }))
              ..sort((a, b) => a.surplusTime.compareTo(b.surplusTime));
            if (devices.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_laundry_service_outlined,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '暂无设备信息',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '下拉刷新以查看最新设备状态',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => _showScanSheet(),
                          child: const Text('扫码添加洗衣机'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => _openManageDevices(),
                          child: const Text('管理设备列表'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final width = MediaQuery.of(context).size.width;
            final crossAxisCount = width >= 1000
                ? 3
                : width >= 650
                    ? 2
                    : 1;

            final content = Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _StatsOverview(
                    total: totalDevices,
                    available: availableCount,
                    busy: busyCount,
                    maintenance: maintenanceCount,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: MasonryGridView.count(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    crossAxisCount: _useCompactCards ? 2 : crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return _DeviceCard(
                        device: device,
                        isExcluded: _queueController.isExcluded(device.code),
                        onToggleExclude: (code) async {
                          final excluded = _queueController.toggleExclude(code);

                          await _prefsService.saveExcludedCodes(
                            _queueController.excludedCodes,
                          );
                          if (!mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                excluded
                                    ? '已标记 ${device.code} 为排除'
                                    : '已恢复 ${device.code}',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          setState(() {});
                        },
                        onDelete: () {
                          _confirmAndRemoveDevice(device.code);
                        },
                        useCompactLayout: _useCompactCards,
                      );
                    },
                  ),
                ),
              ],
            );

            final children = <Widget>[
              Positioned.fill(child: content),
            ];

            if (!hasAvailable && eligibleDevices.isNotEmpty && !_queueController.isActive) {
              children.add(
                Align(
                  alignment: Alignment.topCenter,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '暂无可用设备',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                eligibleDevices.length == 1
                                    ? '预计 ${eligibleDevices.first.surplusTime} 分钟后有设备可用'
                                    : '共有 ${eligibleDevices.length} 台设备排队，最短剩余 ${eligibleDevices.first.surplusTime} 分钟',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () => _startReminder(eligibleDevices),
                                icon: const Icon(Icons.notifications_active_outlined),
                                label: const Text('有可用请提醒我'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            if (_queueController.isActive && _nextDevice != null && _nextDelay != null) {
              children.add(
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(24),
                        color: theme.colorScheme.surface,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                color: theme.colorScheme.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${_nextDevice!.name.isNotEmpty ? _nextDevice!.name : _nextDevice!.code} 预计可用',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _formatCountdown(_nextDelay!),
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              FilledButton.tonalIcon(
                                onPressed: _stopReminder,
                                icon: const Icon(Icons.close),
                                label: const Text('取消'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return Stack(children: children);
          },
        ),
      ),
    );
  }

  void _handleQueueUpdate(List<WasherDevice> queue) {
    if (queue.isEmpty) {
      _countdownSub?.cancel();
      _nextDevice = null;
      _nextDelay = null;
      unawaited(_notificationService.hideCountdownNotification());
      unawaited(_notificationService.cancelAll());
      setState(() {});
    }
    setState(() {});
  }

  void _handleNextSchedule(WasherDevice? device, Duration? delay) {
    setState(() {
      _nextDevice = device;
      _nextDelay = delay;
    });
    _countdownSub?.cancel();
    if (device != null && delay != null) {
      unawaited(
        _notificationService.showCountdownNotification(
          title: '洗衣机提醒队列',
          body:
              '${device.name.isNotEmpty ? device.name : device.code} 预计 ${_formatCountdown(delay)} 后可用',
        ),
      );
      _countdownSub = Stream<DateTime>.periodic(
        const Duration(seconds: 1),
        (_) => DateTime.now(),
      ).listen((_) {
        if (!mounted || _nextDelay == null) {
          return;
        }
        final target = _queueController.nextTriggerAt;
        if (target == null) {
          return;
        }
        final remaining = target.difference(DateTime.now());
        if (remaining.isNegative) {
          _countdownSub?.cancel();
        } else {
          setState(() {
            _nextDelay = remaining;
          });
          unawaited(
            _notificationService.showCountdownNotification(
              title: '洗衣机提醒队列',
              body:
                  '${device.name.isNotEmpty ? device.name : device.code} 预计 ${_formatCountdown(remaining)} 后可用',
            ),
          );
        }
      });
    }
  }

  Future<void> _handleDeviceAvailable(
    WasherDevice device,
    int remainingMinutes,
  ) async {
    await _notificationService.hideCountdownNotification();
    final nameOrCode = device.name.isNotEmpty ? device.name : device.code;
    if (remainingMinutes > 0) {
      await _notificationService.showLeadTimeReminder(
        id: device.id,
        title: '洗衣机即将空闲',
        body: '$nameOrCode 约 ${remainingMinutes} 分钟后空闲',
      );
    } else {
      await _notification_service.scheduleAvailabilityNotification(
        id: device.id,
        title: '洗衣机可用提醒',
        body: '$nameOrCode 现在可用',
        delay: const Duration(seconds: 1),
      );
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          remainingMinutes > 0
              ? '$nameOrCode 约 ${remainingMinutes} 分钟后空闲'
              : '$nameOrCode 已空闲',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatCountdown(Duration duration) {
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

  Future<void> _addDeviceFromInput(String input) async {
    final parsed = _deviceManager.extractCodeFromUrl(input.trim()) ??
        input.trim().toUpperCase();
    if (parsed.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('无法识别该二维码内容'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    if (_deviceCodes.contains(parsed)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('设备 $parsed 已存在'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    final updated = List<String>.from(_deviceCodes)..add(parsed);
    await _deviceManager.saveDeviceCodes(updated);
    if (!mounted) {
      return;
    }
    setState(() {
      _deviceCodes = updated;
      _devicesFuture = _repository.fetchDevices(_deviceCodes);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已添加设备 $parsed'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmAndRemoveDevice(String code) async {
    final canRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('确认移除设备'),
          content: Text('确定移除设备 $code 吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('确认移除'),
            ),
          ],
        );
      },
    );
    if (canRemove != true) {
      return;
    }
    final updated = List<String>.from(_deviceCodes)..remove(code);
    await _deviceManager.saveDeviceCodes(updated);
    if (!mounted) {
      return;
    }
    setState(() {
      _deviceCodes = updated;
      _devicesFuture = _repository.fetchDevices(_deviceCodes);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已移除设备 $code'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openSettings() async {
    final updated = await Navigator.of(context).push<WasherConfig>(
      MaterialPageRoute(
        builder: (_) => WasherSettingsPage(
          initialConfig: _config,
          configService: _configService,
        ),
      ),
    );
    if (updated == null) {
      return;
    }
    _repository.updateConfig(updated);
    if (!mounted) {
      return;
    }
    setState(() {
      _config = updated;
    });
    await _refreshDevices();
  }

  Future<void> _showScanSheet() async {
    final controller = MobileScannerController(returnImage: false);
    String? result;
    bool handled = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.65,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '扫码添加洗衣机',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: MobileScanner(
                      controller: controller,
                      onDetect: (capture) {
                        if (handled) {
                          return;
                        }
                        for (final barcode in capture.barcodes) {
                          final rawValue = barcode.rawValue;
                          if (rawValue != null && rawValue.isNotEmpty) {
                            handled = true;
                            result = rawValue;
                            controller.stop();
                            Navigator.of(sheetContext).pop();
                            break;
                          }
                        }
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.icon(
                    onPressed: () async {
                      controller.stop();
                      Navigator.of(sheetContext).pop();
                      await _openManualAddDialog();
                    },
                    icon: const Icon(Icons.edit_note),
                    label: const Text('手动输入设备编号'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    controller.dispose();
    if (result != null) {
      await _addDeviceFromInput(result!);
    }
  }

  Future<void> _openManualAddDialog() async {
    final controller = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('手动添加设备'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '二维码内容或设备编号',
              hintText: '例如 http://base.xmulife.com/?t=w&name=XXXX',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
    if (added == true) {
      await _addDeviceFromInput(controller.text);
    }
  }

  Future<void> _openManageDevices() async {
    final localCodes = List<String>.from(_deviceCodes);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              '管理洗衣机',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(sheetContext).pop(),
                          ),
                        ],
                      ),
                    ),
                    if (localCodes.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: const [
                            Icon(
                              Icons.info_outline,
                              size: 40,
                            ),
                            SizedBox(height: 12),
                            Text('当前无设备，请扫码或手动添加'),
                          ],
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: localCodes.length,
                          itemBuilder: (context, index) {
                            final code = localCodes[index];
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text('${index + 1}'),
                              ),
                              title: Text(code),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  await _confirmAndRemoveDevice(code);
                                  if (!mounted) {
                                    return;
                                  }
                                  setSheetState(() {
                                    localCodes.removeAt(index);
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: FilledButton.icon(
                        onPressed: () async {
                          Navigator.of(sheetContext).pop();
                          await _openManualAddDialog();
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('手动添加'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.device,
    required this.isExcluded,
    required this.onToggleExclude,
    required this.onDelete,
    required this.useCompactLayout,
  });

  final WasherDevice device;
  final bool isExcluded;
  final Future<void> Function(String code) onToggleExclude;
  final VoidCallback onDelete;
  final bool useCompactLayout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _statusColor(device, colorScheme);
    final statusStyle = theme.textTheme.titleMedium?.copyWith(
      color: statusColor,
      fontWeight: FontWeight.w600,
    );

    if (useCompactLayout) {
      return _CompactDeviceTile(
        device: device,
        isExcluded: isExcluded,
        onToggleExclude: onToggleExclude,
        onDelete: onDelete,
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _statusIcon(device),
                    color: statusColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name.isNotEmpty ? device.name : device.code,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        device.location.isNotEmpty
                            ? device.location
                            : '位置信息待更新',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: '移除设备',
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.business_outlined,
                  label: device.building.isNotEmpty
                      ? device.building
                      : '校区信息待更新',
                ),
                _InfoChip(
                  icon: Icons.layers_outlined,
                  label: '楼层 ${device.floor} · ${device.roomNum}',
                ),
                _InfoChip(
                  icon: Icons.badge_outlined,
                  label: '编号 ${device.deviceCode}',
                ),
                if (device.orderCount > 0)
                  _InfoChip(
                    icon: Icons.shopping_cart_outlined,
                    label: '累计订单 ${device.orderCount}',
                  ),
                ActionChip(
                  avatar: Icon(
                    isExcluded ? Icons.remove_circle_outline : Icons.add_circle_outline,
                    size: 18,
                  ),
                  label: Text(isExcluded ? '恢复监听' : '排除提醒'),
                  onPressed: () {
                    onToggleExclude(device.code);
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.statusLabel,
                    style: statusStyle,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    device.availabilityDetail,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            if (device.orderReminder.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '下单提醒',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(
                device.orderReminder,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (device.lastDeal != null) ...[
              const SizedBox(height: 16),
              Text(
                '最近完成时间',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(
                _formatLastDeal(device.lastDeal!),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Color _statusColor(WasherDevice device, ColorScheme colorScheme) {
    if (device.isInMaintenance) {
      return colorScheme.error;
    }
    if (device.isBusy) {
      return colorScheme.primary;
    }
    return colorScheme.secondary;
  }

  static IconData _statusIcon(WasherDevice device) {
    if (device.isInMaintenance) {
      return Icons.build_circle_outlined;
    }
    if (device.isBusy) {
      return Icons.schedule_outlined;
    }
    return Icons.check_circle_outline;
  }

  static String _formatLastDeal(DateTime lastDeal) {
    final now = DateTime.now();
    final diff = now.difference(lastDeal);
    if (diff.inMinutes < 1) {
      return '刚刚';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} 分钟前';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} 小时前';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    }
    return '${lastDeal.year}-${lastDeal.month.toString().padLeft(2, '0')}-${lastDeal.day.toString().padLeft(2, '0')}';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: ShapeDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.65),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
