// 量潮议事云入口

import 'package:flutter/material.dart';

import 'screens/resolution_list.dart';
import 'screens/topic_list.dart';
import 'services/resolution_store.dart';

void main() {
  runApp(const DelibApp());
}

class DelibApp extends StatelessWidget {
  const DelibApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '量潮议事云',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const MainShell(),
    );
  }
}

// 主框架：侧边导航栏（议题 / 决议）+ 内容区
//
// 桌面端采用 NavigationRail（Material 3）；后续如需响应式，
// 可用 LayoutBuilder 在窄屏降级为 Drawer。

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.store});

  /// 决议数据源（测试可注入替身，默认本地标本）
  final ResolutionStore? store;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    const TopicScreen(),
    ResolutionScreen(store: widget.store),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.topic_outlined),
                selectedIcon: Icon(Icons.topic),
                label: Text('议题'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.gavel_outlined),
                selectedIcon: Icon(Icons.gavel),
                label: Text('决议'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}
