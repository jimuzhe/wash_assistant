class WasherDevice {
  final int id;
  final String code;
  final String deviceCode;
  final String imei;
  final String name;
  final int state;
  final int workState;
  final String workStateName;
  final String errorState;
  final int floor;
  final String roomNum;
  final String location;
  final int surplusTime;
  final int orderCount;
  final String building;
  final String province;
  final String city;
  final String office;
  final String branchOffice;
  final String orderReminder;
  final DateTime? lastDeal;

  const WasherDevice({
    required this.id,
    required this.code,
    required this.deviceCode,
    required this.imei,
    required this.name,
    required this.state,
    required this.workState,
    required this.workStateName,
    required this.errorState,
    required this.floor,
    required this.roomNum,
    required this.location,
    required this.surplusTime,
    required this.orderCount,
    required this.building,
    required this.province,
    required this.city,
    required this.office,
    required this.branchOffice,
    required this.orderReminder,
    required this.lastDeal,
  });

  factory WasherDevice.fromJson(Map<String, dynamic> json, {required String code}) {
    return WasherDevice(
      id: json['id'] as int,
      code: code,
      deviceCode: json['deviceCode'] as String? ?? '',
      imei: json['imei'] as String? ?? '',
      name: json['deviceName'] as String? ?? '',
      state: json['state'] as int? ?? -1,
      workState: json['workState'] as int? ?? -1,
      workStateName: json['workStateName'] as String? ?? '',
      errorState: json['errorState'] as String? ?? '',
      floor: json['floor'] as int? ?? 0,
      roomNum: json['roomNum'] as String? ?? '',
      location: json['location'] as String? ?? '',
      surplusTime: json['surplusTime'] as int? ?? 0,
      orderCount: json['orderCount'] as int? ?? 0,
      building: json['building'] as String? ?? '',
      province: json['province'] as String? ?? '',
      city: json['city'] as String? ?? '',
      office: json['office'] as String? ?? '',
      branchOffice: json['branchOffice'] as String? ?? '',
      orderReminder: json['orderReminder'] as String? ?? '',
      lastDeal: (json['lastDeal'] as int?) == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(json['lastDeal'] as int),
    );
  }

  bool get isAvailable {
    if (workStateName.contains('空闲')) {
      return true;
    }
    if (workState == 10) {
      return true;
    }
    if (workState == 11 || workState == 12) {
      return false;
    }
    if (state == 1) {
      return false;
    }
    return !isInMaintenance;
  }

  bool get isInMaintenance {
    if (workStateName.contains('维修')) {
      return true;
    }
    if (state == 2) {
      return true;
    }
    return false;
  }

  bool get isBusy {
    if (workStateName.contains('工作')) {
      return true;
    }
    if (workState == 11) {
      return true;
    }
    return false;
  }

  String get statusLabel {
    if (workStateName.isNotEmpty) {
      return workStateName;
    }
    if (isInMaintenance) {
      return '维修中';
    }
    if (isBusy) {
      return '使用中';
    }
    if (isAvailable) {
      return '可用';
    }
    return '未知状态';
  }

  String get availabilityDetail {
    if (isInMaintenance) {
      return '设备维护中';
    }
    if (isBusy) {
      if (surplusTime > 0) {
        return '预计剩余 $surplusTime 分钟';
      }
      return '当前正在使用';
    }
    return '当前可下单';
  }
}
