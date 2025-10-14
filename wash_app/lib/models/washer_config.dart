class WasherConfig {
  const WasherConfig({
    required this.baseUrl,
    required this.endpoint,
    required this.qrTemplate,
    required this.headers,
    required this.reminderLeadMinutes,
  });

  factory WasherConfig.defaultConfig() {
    return const WasherConfig(
      baseUrl: 'https://api.ulife.group',
      endpoint: '/washer/device/scanCode',
      qrTemplate: 'http://base.xmulife.com?t=w&name={code}',
      headers: {
        'Accept': '*/*',
        'Version': '8.3.2',
        'Authorization':
            'Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzM4NCJ9.eyJleHAiOjE3NjU2MTI5NTIsInVzZXJJZCI6IjEzMjExMTYiLCJpYXQiOjE3NTAwNjA5NTIsInBsYXRmb3JtIjoiYXBwIn0.DQWa0ZA_pGRLx35uVC2ki0HRe-W-PU4AEc0GMBujgebSa7oK2ahbfkdGarXH1nuY',
        'Tokenplatform': 'yx',
        'Accept-Encoding': 'gzip, deflate, br',
        'Accept-Language': 'zh-Hans-CN;q=1, en-CN;q=0.9',
        'Content-Type': 'application/json',
        'User-Agent':
            'WasherV4-AppStore/8.3.2 (iPhone; iOS 16.3.1; Scale/3.00)',
        'Connection': 'keep-alive',
        'sourceType': 'ios',
        'Cookie':
            'SERVERCORSID=2208ec3041576885a9430be6fc702875|1760459467|1760457965; SERVERID=2208ec3041576885a9430be6fc702875|1760459467|1760457965',
      },
      reminderLeadMinutes: 0,
    );
  }

  factory WasherConfig.fromJson(Map<String, dynamic> json) {
    final headers = <String, String>{};
    final headersJson = json['headers'];
    if (headersJson is Map) {
      headersJson.forEach((key, value) {
        if (key is String && value is String) {
          headers[key] = value;
        } else if (key is String && value != null) {
          headers[key] = value.toString();
        }
      });
    }
    return WasherConfig(
      baseUrl: json['baseUrl'] as String? ?? WasherConfig.defaultConfig().baseUrl,
      endpoint: json['endpoint'] as String?
          ?? WasherConfig.defaultConfig().endpoint,
      qrTemplate: json['qrTemplate'] as String?
          ?? WasherConfig.defaultConfig().qrTemplate,
      headers: headers.isEmpty
          ? WasherConfig.defaultConfig().headers
          : headers,
      reminderLeadMinutes:
          (json['reminderLeadMinutes'] as num?)?.toInt() ?? WasherConfig.defaultConfig().reminderLeadMinutes,
    );
  }

  final String baseUrl;
  final String endpoint;
  final String qrTemplate;
  final Map<String, String> headers;
  final int reminderLeadMinutes;

  WasherConfig copyWith({
    String? baseUrl,
    String? endpoint,
    String? qrTemplate,
    Map<String, String>? headers,
    int? reminderLeadMinutes,
  }) {
    return WasherConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      endpoint: endpoint ?? this.endpoint,
      qrTemplate: qrTemplate ?? this.qrTemplate,
      headers: headers ?? Map<String, String>.from(this.headers),
      reminderLeadMinutes: reminderLeadMinutes ?? this.reminderLeadMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseUrl': baseUrl,
      'endpoint': endpoint,
      'qrTemplate': qrTemplate,
      'headers': headers,
      'reminderLeadMinutes': reminderLeadMinutes,
    };
  }

  String buildQrCode(String code) {
    if (qrTemplate.contains('{code}')) {
      return qrTemplate.replaceAll('{code}', code);
    }
    return '$qrTemplate$code';
  }
}
