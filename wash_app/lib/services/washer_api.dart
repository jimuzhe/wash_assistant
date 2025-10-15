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

    Response<String> response;
    try {
      response = await _dio.post<String>(
        _config.endpoint,
        data: payload,
        options: Options(
          headers: _config.headers,
          contentType: 'application/json',
          responseType: ResponseType.plain,
        ),
      );
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final body = error.response?.data;
      final detail = body is String && body.isNotEmpty
          ? body
          : error.message ?? '网络请求失败';
      throw WasherApiException(
        '设备 $deviceCode 请求失败${statusCode != null ? ' (HTTP $statusCode)' : ''}: $detail',
      );
    }

    final rawBody = response.data?.trim();
    if (rawBody == null || rawBody.isEmpty) {
      throw WasherApiException('设备 $deviceCode 接口返回为空');
    }

    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('响应不是 JSON 对象');
      }
      body = decoded;
    } on FormatException catch (error) {
      throw WasherApiException('设备 $deviceCode 返回格式错误: ${error.message}');
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
