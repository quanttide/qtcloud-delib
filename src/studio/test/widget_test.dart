// 量潮议事云冒烟测试

import 'package:flutter_test/flutter_test.dart';

import 'package:studio/main.dart';
import 'package:studio/screens/resolution_detail.dart';
import 'package:studio/screens/resolution_list.dart';

void main() {
  testWidgets('首页显示功能入口', (WidgetTester tester) async {
    await tester.pumpWidget(const DelibApp());

    expect(find.text('量潮议事云'), findsOneWidget);
    expect(find.text('决议管理'), findsOneWidget);
  });

  testWidgets('决议列表显示决议标题', (WidgetTester tester) async {
    await tester.pumpWidget(const DelibApp());

    await tester.tap(find.text('决议管理'));
    await tester.pumpAndSettle();

    expect(find.byType(ResolutionScreen), findsOneWidget);
    expect(find.text('周会实行记名表决制'), findsOneWidget);
    expect(find.text('通过《周会审计流程章程》'), findsOneWidget);
  });

  testWidgets('点击决议从右侧弹窗显示详情', (WidgetTester tester) async {
    await tester.pumpWidget(const DelibApp());

    await tester.tap(find.text('决议管理'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('周会实行记名表决制'));
    await tester.pumpAndSettle();

    expect(find.byType(ResolutionDetailScreen), findsOneWidget);
    expect(find.text('决议详情'), findsOneWidget);
    expect(find.text('编号：2026-W32-01 · 治理'), findsOneWidget);
    expect(find.textContaining('记名表决'), findsWidgets);
  });
}
