// 量潮议事云入口

import 'package:flutter/material.dart';

import 'screens/resolution_list.dart';

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
      home: const HomeScreen(),
    );
  }
}

// 首页：功能入口
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('量潮议事云'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.gavel),
            title: const Text('决议管理'),
            subtitle: const Text('决议看板：做什么、谁负责、何时完成'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const ResolutionScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
