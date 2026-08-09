// 量潮议事云冒烟测试
//
// 主框架（侧边导航）与决议列表通过注入替身数据源（_FakeResolutionStore）测试，
// 不依赖真实资产加载与网络。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:studio/main.dart';
import 'package:studio/models/resolution.dart';
import 'package:studio/screens/resolution_detail.dart';
import 'package:studio/screens/resolution_list.dart';
import 'package:studio/services/resolution_store.dart';

/// 内存替身：不发网络请求，直接返回/记录数据
class _FakeResolutionStore implements ResolutionStore {
  _FakeResolutionStore({List<Resolution>? items, this.fetchImpl})
    : items = items ?? [];

  final List<Resolution> items;

  /// 可替换的列表实现（测试注入故障等场景）
  final Future<List<Resolution>> Function()? fetchImpl;

  @override
  Future<List<Resolution>> fetchResolutions() async {
    if (fetchImpl != null) {
      return fetchImpl!();
    }
    return List.of(items);
  }
}

const Resolution sample = Resolution(
  id: 'f29eb8a9-dc51-4527-ac6b-019ce0d03d79',
  name: 'weekly-vote',
  title: '周会实行记名表决制',
  content: '自本周起，公司周会重大事项实行记名表决。',
  category: '治理',
);

Widget _shellWith(_FakeResolutionStore store) =>
    MaterialApp(home: MainShell(store: store));

Widget _screenWith(_FakeResolutionStore store) =>
    MaterialApp(home: ResolutionScreen(store: store));

void main() {
  testWidgets('主框架显示侧边导航（议题/决议），默认选中议题', (WidgetTester tester) async {
    await tester.pumpWidget(_shellWith(_FakeResolutionStore()));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('议题'), findsOneWidget);
    expect(find.text('决议'), findsOneWidget);
    expect(find.text('议题功能建设中'), findsOneWidget);
    expect(find.byType(ResolutionScreen), findsNothing);
  });

  testWidgets('点击决议导航项切换为决议列表', (WidgetTester tester) async {
    await tester.pumpWidget(_shellWith(_FakeResolutionStore(items: [sample])));
    await tester.pumpAndSettle();

    await tester.tap(find.text('决议'));
    await tester.pumpAndSettle();

    expect(find.byType(ResolutionScreen), findsOneWidget);
    expect(find.text('周会实行记名表决制'), findsOneWidget);
  });

  testWidgets('决议列表显示标本决议标题', (WidgetTester tester) async {
    await tester.pumpWidget(_screenWith(_FakeResolutionStore(items: [sample])));
    await tester.pumpAndSettle();

    expect(find.text('周会实行记名表决制'), findsOneWidget);
  });

  testWidgets('决议列表为空时显示空状态', (WidgetTester tester) async {
    await tester.pumpWidget(_screenWith(_FakeResolutionStore()));
    await tester.pumpAndSettle();

    expect(find.text('暂无决议'), findsOneWidget);
  });

  testWidgets('加载失败显示错误信息与重试', (WidgetTester tester) async {
    bool fail = true;
    final List<Resolution> items = [sample];
    final _FakeResolutionStore store = _FakeResolutionStore(
      items: items,
      fetchImpl: () async {
        if (fail) {
          throw Exception('load failed');
        }
        return List.of(items);
      },
    );

    await tester.pumpWidget(_screenWith(store));
    await tester.pumpAndSettle();

    expect(find.text('加载决议失败'), findsOneWidget);

    // 恢复后点击重试，列表正常显示
    fail = false;
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    expect(find.text('周会实行记名表决制'), findsOneWidget);
  });

  testWidgets('点击决议从右侧弹窗显示详情', (WidgetTester tester) async {
    await tester.pumpWidget(_screenWith(_FakeResolutionStore(items: [sample])));
    await tester.pumpAndSettle();

    await tester.tap(find.text('周会实行记名表决制'));
    await tester.pumpAndSettle();

    expect(find.byType(ResolutionDetailScreen), findsOneWidget);
    expect(find.text('决议详情'), findsOneWidget);
    expect(
      find.text('编号：f29eb8a9-dc51-4527-ac6b-019ce0d03d79 · 治理'),
      findsOneWidget,
    );
    // Markdown 渲染的正文在 RichText 中，需 findRichText 匹配
    expect(find.textContaining('记名表决', findRichText: true), findsWidgets);
  });

  testWidgets('决议列表无新建入口（本地标本只读）', (WidgetTester tester) async {
    await tester.pumpWidget(_screenWith(_FakeResolutionStore(items: [sample])));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add), findsNothing);
  });
}
