// 议题 API 客户端测试（MockClient 模拟服务端）。

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:studio/services/topic_api.dart';

void main() {
  const topicJson = {
    'id': 't-1',
    'name': 'data-contract',
    'title': '引入数据契约机制',
    'content': '统一数据理解',
    'category': '数据工程',
    'status': 'proposed',
    'proposerId': 'u-1',
    'seconderIds': <String>[],
    'votes': {'for': 0, 'against': 0, 'abstain': 0},
  };

  TopicApi apiWith(MockClient client) =>
      TopicApi(client: client, baseUrl: 'http://test:8080', token: 'tok');

  test('fetchTopics 请求 GET /topics 并解析', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), 'http://test:8080/topics');
      expect(request.headers['Authorization'], 'Bearer tok');
      return http.Response(jsonEncode({'topics': [topicJson]}), 200,
          headers: {'content-type': 'application/json'});
    });
    final topics = await apiWith(client).fetchTopics();
    expect(topics, hasLength(1));
    expect(topics.single.title, '引入数据契约机制');
    expect(topics.single.status, 'proposed');
  });

  test('createTopic 提交 POST /topics', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/topics');
      return http.Response(jsonEncode(topicJson), 201,
          headers: {'content-type': 'application/json'});
    });
    final t = await apiWith(client).createTopic(title: '引入数据契约机制');
    expect(t.id, 't-1');
  });

  test('second 调用 POST /topics/{id}/second 并返回更新状态', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/topics/t-1/second');
      final updated = Map<String, dynamic>.from(topicJson)
        ..['status'] = 'seconded'
        ..['seconderIds'] = ['u-2'];
      return http.Response(jsonEncode(updated), 200,
          headers: {'content-type': 'application/json'});
    });
    final t = await apiWith(client).second('t-1');
    expect(t.status, 'seconded');
    expect(t.seconderIds, ['u-2']);
  });

  test('vote 提交 choice', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/topics/t-1/vote');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['choice'], 'for');
      final updated = Map<String, dynamic>.from(topicJson)
        ..['status'] = 'voted'
        ..['votes'] = {'for': 1, 'against': 0, 'abstain': 0};
      return http.Response(jsonEncode(updated), 200,
          headers: {'content-type': 'application/json'});
    });
    final t = await apiWith(client).vote('t-1', 'for');
    expect(t.votes.for_, 1);
  });

  test('非 2xx 抛 TopicApiException', () async {
    final client = MockClient((_) async => http.Response('{"error":"forbidden"}', 403));
    expect(
      () => apiWith(client).fetchTopics(),
      throwsA(isA<TopicApiException>()),
    );
  });
}
