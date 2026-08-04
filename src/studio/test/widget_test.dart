// 量潮议事云冒烟测试

import 'package:flutter_test/flutter_test.dart';

import 'package:studio/main.dart';
import 'package:studio/screens/resolution_list.dart';

void main() {
  testWidgets('首页显示功能入口', (WidgetTester tester) async {
    await tester.pumpWidget(const DelibApp());

    expect(find.text('量潮议事云'), findsOneWidget);
    expect(find.text('决议管理'), findsOneWidget);
  });

  testWidgets('点击决议管理进入决议看板', (WidgetTester tester) async {
    await tester.pumpWidget(const DelibApp());

    await tester.tap(find.text('决议管理'));
    await tester.pumpAndSettle();

    expect(find.byType(ResolutionScreen), findsOneWidget);
    expect(find.text('待执行'), findsWidgets);
    expect(find.text('已逾期'), findsWidgets);
  });
}
