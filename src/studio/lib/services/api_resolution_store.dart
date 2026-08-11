// 决议数据源：对接 qtcloud-delib provider（经系统级 API 网关）。
// 与 AssetResolutionStore 同实现 ResolutionStore 接口，登录后切换使用。

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/resolution.dart';
import 'resolution_store.dart';

class ApiResolutionStore implements ResolutionStore {
  ApiResolutionStore({http.Client? client, required this.baseUrl, required this.token})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final String token;

  @override
  Future<List<Resolution>> fetchResolutions() async {
    final http.Response response = await _client.get(
      Uri.parse('$baseUrl/resolutions'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw ResolutionStoreException('加载决议失败（HTTP ${response.statusCode}）');
    }
    final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final List<dynamic> items = body['resolutions'] as List<dynamic>? ?? [];
    return items
        .map((dynamic item) => Resolution.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Resolution> createResolution({
    required String name,
    required String title,
    String content = '',
    String category = '',
  }) async {
    final http.Response response = await _client.post(
      Uri.parse('$baseUrl/resolutions'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'title': title,
        'content': content,
        'category': category,
      }),
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode != 201) {
      throw ResolutionStoreException('创建决议失败（HTTP ${response.statusCode}）');
    }
    return Resolution.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
  }
}
