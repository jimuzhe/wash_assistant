import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/washer_config.dart';
import '../models/washer_device.dart';

class WasherApi {
  WasherApi({Dio? dio, WasherConfig? config})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: config?.baseUrl ?? 'https://api.ulife.group')),
        _config = config ?? WasherConfig.defaultConfig();

  final Dio _dio;
  WasherConfig _config;

  void applyConfig(WasherConfig config) {
    _config = config;
    _dio.options.baseUrl = config.baseUrl;
  }

  Future<WasherDevice> fetchDevice(String deviceCode) async {
    final payload = jsonEncode({
      'code': _config.buildQrCode(deviceCode),
    });

    final response = await _dio.post<Map<String, dynamic>>(
      _config.endpoint,
      data: payload,
      options: Options(headers: _config.headers, contentType: 'application/json'),
    );

    final body = response.data;
    if (body == null) {
      throw const WasherApiException('接口返回为空');
    }

    final success = (body['success'] as bool?) ?? false;
    if (!success) {
      final message = body['message'] as String? ?? '未知错误';
      throw WasherApiException('设备 $deviceCode 请求失败: $message');
    }

    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw WasherApiException('设备 $deviceCode 数据为空');
    }

    return WasherDevice.fromJson(data, code: deviceCode);
  }
}

class WasherApiException implements Exception {
  const WasherApiException(this.message);

  final String message;

  @override
  String toString() => 'WasherApiException: $message';
}
