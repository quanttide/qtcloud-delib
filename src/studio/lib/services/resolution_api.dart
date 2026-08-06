// 决议服务端 API 客户端
//
// 对接 provider（Go 服务端）的决议接口：
//   GET  /resolutions  → {"resolutions": [Resolution, ...]}
//   POST /resolutions  → 创建决议，返回创建的 Resolution（201）
//
// baseUrl 默认按平台推导：Android 模拟器经 10.0.2.2 访问宿主机，
// 其余平台默认 localhost；可用 --dart-define=DELIB_API_BASE_URL=... 覆盖。

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/resolution.dart';

/// API 调用异常：携带 HTTP 状态码与服务端错误信息。
class ResolutionApiException implements Exception {
  const ResolutionApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ResolutionApiException($statusCode): $message';
}

/// 决议 API 客户端。
class ResolutionApi {
  ResolutionApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl = baseUrl ?? defaultBaseUrl();

  final http.Client _client;

  /// 服务端地址（如 http://localhost:8080）。
  final String baseUrl;

  /// 默认服务端地址：
  /// - `--dart-define=DELIB_API_BASE_URL=...` 显式指定（真实设备部署等场景）
  /// - Android 模拟器经 10.0.2.2 访问宿主机
  /// - 其余平台（桌面 / iOS 模拟器 / Web）默认 localhost
  static String defaultBaseUrl() {
    const String fromEnv = String.fromEnvironment('DELIB_API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  /// 决议清单：GET /resolutions
  Future<List<Resolution>> fetchResolutions() async {
    final http.Response response = await _client
        .get(Uri.parse('$baseUrl/resolutions'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw ResolutionApiException(
        response.statusCode,
        _errorMessage(response),
      );
    }
    final Map<String, dynamic> body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final List<dynamic> items = body['resolutions'] as List<dynamic>? ?? [];
    return items
        .map(
          (dynamic item) => Resolution.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  /// 创建决议：POST /resolutions（id 由服务端生成，name/title 必填）
  Future<Resolution> createResolution({
    required String name,
    required String title,
    String content = '',
    String category = '',
  }) async {
    final http.Response response = await _client
        .post(
          Uri.parse('$baseUrl/resolutions'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'title': title,
            'content': content,
            'category': category,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 201) {
      throw ResolutionApiException(
        response.statusCode,
        _errorMessage(response),
      );
    }
    return Resolution.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }

  /// 提取服务端错误信息（{"error": "..."}，缺省时回退为状态码描述）。
  String _errorMessage(http.Response response) {
    try {
      final Map<String, dynamic> body =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return body['error'] as String? ?? 'HTTP ${response.statusCode}';
    } on FormatException {
      return 'HTTP ${response.statusCode}';
    }
  }
}
