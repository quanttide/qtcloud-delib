// 议题管理页面（占位）
//
// 服务端尚未提供议题 API，先占位保证侧边导航结构完整。
// 后续对齐决议领域落地：服务端 internal/topic（GET/POST /topics）
// + 客户端 Topic 模型 / TopicApi / 议题列表页。

import 'package:flutter/material.dart';

class TopicScreen extends StatelessWidget {
  const TopicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('议题管理')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.topic_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            const Text('议题功能建设中'),
            const SizedBox(height: 8),
            Text(
              '等待服务端议题 API（GET/POST /topics）接入',
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
