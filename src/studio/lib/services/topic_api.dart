// 议题 API 客户端：五流程操作（动议→附议→辩论→表决→决议）。

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/topic.dart';

class TopicApiException implements Exception {
  const TopicApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TopicApi {
  TopicApi({http.Client? client, required this.baseUrl, required this.token})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final String token;

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  Future<List<Topic>> fetchTopics() async {
    final resp = await _client
        .get(Uri.parse('$baseUrl/topics'), headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      throw TopicApiException('加载议题失败（HTTP ${resp.statusCode}）');
    }
    final body = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    return (body['topics'] as List<dynamic>? ?? [])
        .map((e) => Topic.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Topic> createTopic({
    required String title,
    String content = '',
    String category = '',
  }) async {
    final resp = await _client
        .post(
          Uri.parse('$baseUrl/topics'),
          headers: _headers,
          body: jsonEncode({
            'title': title,
            'content': content,
            'category': category,
          }),
        )
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 201) {
      throw TopicApiException(_error(resp));
    }
    return Topic.fromJson(jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>);
  }

  Future<Topic> second(String id) => _transition('$baseUrl/topics/$id/second');

  Future<Topic> debate(String id) => _transition('$baseUrl/topics/$id/debate');

  Future<Topic> vote(String id, String choice) =>
      _transition('$baseUrl/topics/$id/vote', body: {'choice': choice});

  Future<Topic> close(String id) => _transition('$baseUrl/topics/$id/close');

  Future<Topic> _transition(String url, {Map<String, dynamic>? body}) async {
    final resp = await _client
        .post(Uri.parse(url), headers: _headers, body: body == null ? null : jsonEncode(body))
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      throw TopicApiException(_error(resp));
    }
    return Topic.fromJson(jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>);
  }

  String _error(http.Response resp) {
    try {
      final body = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      return body['error'] as String? ?? 'HTTP ${resp.statusCode}';
    } on FormatException {
      return 'HTTP ${resp.statusCode}';
    }
  }
}
