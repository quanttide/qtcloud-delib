// 决议 API 客户端单元测试
//
// 用 http/testing 的 MockClient 模拟服务端，验证请求路径、
// 响应解析与错误处理。

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:studio/models/resolution.dart';
import 'package:studio/services/resolution_api.dart';

void main() {
  const Resolution sample = Resolution(
    id: 'f29eb8a9-dc51-4527-ac6b-019ce0d03d79',
    name: 'weekly-vote',
    title: '周会实行记名表决制',
    content: '自本周起，公司周会重大事项实行记名表决。',
    category: '治理',
  );

  ResolutionApi apiWith(MockClient client) =>
      ResolutionApi(client: client, baseUrl: 'http://test:8080');

  test('fetchResolutions 请求 GET /resolutions 并解析清单', () async {
    final MockClient client = MockClient((http.Request request) async {
      expect(request.method, 'GET');
      expect(request.url.toString(), 'http://test:8080/resolutions');
      return http.Response(
        jsonEncode({
          'resolutions': [sample.toJson()],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final List<Resolution> resolutions = await apiWith(
      client,
    ).fetchResolutions();

    expect(resolutions, hasLength(1));
    expect(resolutions.single.id, sample.id);
    expect(resolutions.single.name, 'weekly-vote');
    expect(resolutions.single.title, '周会实行记名表决制');
    expect(resolutions.single.category, '治理');
  });

  test('createResolution 提交 POST /resolutions 并解析创建的决议', () async {
    final MockClient client = MockClient((http.Request request) async {
      expect(request.method, 'POST');
      expect(request.url.toString(), 'http://test:8080/resolutions');
      expect(request.headers['content-type'], 'application/json');
      final Map<String, dynamic> body =
          jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['name'], 'weekly-vote');
      expect(body['title'], '周会实行记名表决制');
      expect(body['content'], '');
      expect(body['category'], '');
      return http.Response(
        jsonEncode(sample.toJson()),
        201,
        headers: {'content-type': 'application/json'},
      );
    });

    final Resolution created = await apiWith(
      client,
    ).createResolution(name: 'weekly-vote', title: '周会实行记名表决制');

    expect(created.id, sample.id);
    expect(created.title, '周会实行记名表决制');
  });

  test('非 2xx 响应抛出 ResolutionApiException 并携带服务端错误信息', () async {
    final MockClient client = MockClient((http.Request request) async {
      return http.Response(
        jsonEncode({'error': 'name and title are required'}),
        400,
        headers: {'content-type': 'application/json'},
      );
    });

    expect(
      () => apiWith(client).createResolution(name: '', title: ''),
      throwsA(
        isA<ResolutionApiException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having((e) => e.message, 'message', 'name and title are required'),
      ),
    );
  });

  test('非 JSON 错误响应回退为状态码描述', () async {
    final MockClient client = MockClient((http.Request request) async {
      return http.Response('server exploded', 500);
    });

    expect(
      () => apiWith(client).fetchResolutions(),
      throwsA(
        isA<ResolutionApiException>()
            .having((e) => e.statusCode, 'statusCode', 500)
            .having((e) => e.message, 'message', 'HTTP 500'),
      ),
    );
  });
}
