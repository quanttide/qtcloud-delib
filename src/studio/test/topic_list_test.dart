// 议题列表过滤测试：关键词 / 状态 / 类别。
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:studio/screens/topic_list.dart';
import 'package:studio/services/topic_api.dart';

Map<String, dynamic> _topic({
  required String id,
  required String name,
  required String title,
  required String category,
  required String status,
  String? source,
  String? ledgerNo,
}) =>
    {
      'id': id,
      'name': name,
      'title': title,
      'content': '内容 $title',
      'category': category,
      'status': status,
      'proposerId': '',
      'seconderIds': [],
      'votes': {'for': 0, 'against': 0, 'abstain': 0},
      if (source != null) 'source': source,
      if (ledgerNo != null) 'ledgerNo': ledgerNo,
    };

Widget _build(List<Map<String, dynamic>> topics) {
  final client = MockClient((req) async {
    if (req.url.path.endsWith('/topics')) {
      return http.Response(
        jsonEncode({'topics': topics}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    return http.Response('not found', 404);
  });
  final api = TopicApi(client: client, baseUrl: 'http://test', token: '');
  return MaterialApp(home: TopicScreen(api: api));
}

void main() {
  testWidgets('关键词过滤：搜索来源/编号/标题', (tester) async {
    await tester.pumpWidget(_build([
      _topic(
        id: 'a', name: 'proposal-m-01', title: '合伙人决议',
        category: '提案', status: 'proposed', source: '2026年第1周-提案1', ledgerNo: 'M-01',
      ),
      _topic(
        id: 'b', name: 'discussion-m-54', title: '创始人文章学习',
        category: '研讨', status: 'seconded', source: '第18周-研讨2', ledgerNo: 'M-54',
      ),
      _topic(
        id: 'c', name: 'plan-m-7', title: '工作检查',
        category: '计划', status: 'resolved', source: '第13周-计划1', ledgerNo: 'M-7',
      ),
    ]));
    await tester.pumpAndSettle();

    // 初始 3 条
    expect(find.byType(ListTile), findsNWidgets(3));

    // 按来源关键词
    await tester.enterText(find.byType(TextField), '研讨2');
    await tester.pump();
    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text('创始人文章学习'), findsOneWidget);

    // 按编号
    await tester.enterText(find.byType(TextField), 'M-01');
    await tester.pump();
    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text('合伙人决议'), findsOneWidget);

    // 清空恢复
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(find.byType(ListTile), findsNWidgets(3));
  });

  testWidgets('状态过滤：已决议仅剩一条', (tester) async {
    await tester.pumpWidget(_build([
      _topic(
        id: 'a', name: 'proposal-m-01', title: '合伙人决议',
        category: '提案', status: 'proposed', source: '2026年第1周-提案1', ledgerNo: 'M-01',
      ),
      _topic(
        id: 'b', name: 'discussion-m-54', title: '创始人文章学习',
        category: '研讨', status: 'seconded', source: '第18周-研讨2', ledgerNo: 'M-54',
      ),
      _topic(
        id: 'c', name: 'plan-m-7', title: '工作检查',
        category: '计划', status: 'resolved', source: '第13周-计划1', ledgerNo: 'M-7',
      ),
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('全部状态'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('已决议').last);
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text('工作检查'), findsOneWidget);
  });

  testWidgets('类别过滤：提案类剩一条', (tester) async {
    await tester.pumpWidget(_build([
      _topic(
        id: 'a', name: 'proposal-m-01', title: '合伙人决议',
        category: '提案', status: 'proposed', source: '2026年第1周-提案1', ledgerNo: 'M-01',
      ),
      _topic(
        id: 'b', name: 'discussion-m-54', title: '创始人文章学习',
        category: '研讨', status: 'seconded', source: '第18周-研讨2', ledgerNo: 'M-54',
      ),
      _topic(
        id: 'c', name: 'plan-m-7', title: '工作检查',
        category: '计划', status: 'resolved', source: '第13周-计划1', ledgerNo: 'M-7',
      ),
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('全部分类'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('提案').last);
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text('合伙人决议'), findsOneWidget);
  });

  testWidgets('无匹配显示空态', (tester) async {
    await tester.pumpWidget(_build([
      _topic(
        id: 'a', name: 'proposal-m-01', title: '合伙人决议',
        category: '提案', status: 'proposed', source: '2026年第1周-提案1', ledgerNo: 'M-01',
      ),
    ]));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '不存在的词');
    await tester.pump();
    expect(find.byType(ListTile), findsNothing);
    expect(find.text('没有匹配的议题'), findsOneWidget);
  });
}
