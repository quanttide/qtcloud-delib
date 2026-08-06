// 决议详情页面
//
// 展示决议的完整陈述（content，Markdown 渲染），由决议列表右侧弹窗打开。

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/resolution.dart';

class ResolutionDetailScreen extends StatelessWidget {
  const ResolutionDetailScreen({super.key, required this.resolution});

  final Resolution resolution;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('决议详情'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(resolution.title, style: textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              '编号：${resolution.id} · ${resolution.category}',
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const Divider(height: 32),
            Markdown(
              data: resolution.content,
              padding: EdgeInsets.zero,
              // 内部 ListView 收缩包裹，嵌入外层 SingleChildScrollView
              shrinkWrap: true,
              styleSheet: MarkdownStyleSheet.fromTheme(
                Theme.of(context),
              ).copyWith(p: textTheme.bodyLarge?.copyWith(height: 1.6)),
            ),
          ],
        ),
      ),
    );
  }
}
