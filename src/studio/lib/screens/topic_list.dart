// 议题管理页：五流程（动议→附议→辩论→表决→决议）。

import 'package:flutter/material.dart';

import '../models/topic.dart';
import '../services/topic_api.dart';

class TopicScreen extends StatefulWidget {
  const TopicScreen({super.key, this.api});

  final TopicApi? api;

  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  late final TopicApi _api = widget.api ?? TopicApi(
    baseUrl: _baseUrl(),
    token: _token(),
  );
  late Future<List<Topic>> _future = _api.fetchTopics();

  static String _baseUrl() {
    const String fromEnv = String.fromEnvironment('QTCLOUD_DELIB_API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    return 'http://localhost:8080';
  }

  static String _token() => '';

  void _reload() {
    setState(() {
      _future = _api.fetchTopics();
    });
  }

  /// 新建动议。
  Future<void> _showCreate() async {
    final title = TextEditingController();
    final content = TextEditingController();
    final category = TextEditingController();
    final String? result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建动议'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: '议题标题')),
              TextField(controller: content, decoration: const InputDecoration(labelText: '动议内容'), maxLines: 4),
              TextField(controller: category, decoration: const InputDecoration(labelText: '分类')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, 'ok'), child: const Text('提交')),
        ],
      ),
    );
    if (result != 'ok' || title.text.trim().isEmpty) {
      return;
    }
    try {
      await _api.createTopic(
        title: title.text.trim(),
        content: content.text,
        category: category.text.trim(),
      );
      _reload();
    } on TopicApiException catch (e) {
      _toast(e.message);
    }
  }

  /// 五流程操作。
  Future<void> _action(Topic t, String label, Future<Topic> Function() op) async {
    try {
      await op();
      _reload();
    } on TopicApiException catch (e) {
      _toast(e.message);
    }
  }

  void _showVoteDialog(Topic t) {
    showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('表决'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'for'),
            child: const Text('赞成'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'against'),
            child: const Text('反对'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'abstain'),
            child: const Text('弃权'),
          ),
        ],
      ),
    ).then((choice) {
      if (choice != null) {
        _action(t, '表决', () => _api.vote(t.id, choice));
      }
    });
  }

  void _toast(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('议题管理')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreate,
        tooltip: '新建动议',
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Topic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 48),
                  const SizedBox(height: 12),
                  const Text('加载议题失败'),
                  Text('${snapshot.error}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _reload, child: const Text('重试')),
                ],
              ),
            );
          }
          final topics = snapshot.data ?? [];
          if (topics.isEmpty) {
            return const Center(child: Text('暂无议题，点击 + 新建动议'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              final f = _api.fetchTopics();
              setState(() => _future = f);
              await f;
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: topics.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) => _TopicTile(
                topic: topics[index],
                onSecond: () => _action(topics[index], '附议', () => _api.second(topics[index].id)),
                onDebate: () => _action(topics[index], '辩论', () => _api.debate(topics[index].id)),
                onVote: () => _showVoteDialog(topics[index]),
                onClose: () => _action(topics[index], '归档', () => _api.close(topics[index].id)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({
    required this.topic,
    required this.onSecond,
    required this.onDebate,
    required this.onVote,
    required this.onClose,
  });

  final Topic topic;
  final VoidCallback onSecond;
  final VoidCallback onDebate;
  final VoidCallback onVote;
  final VoidCallback onClose;

  String get _statusLabel => switch (topic.status) {
    'proposed' => '动议',
    'seconded' => '附议',
    'debated' => '辩论',
    'voted' => '表决',
    'resolved' => '已决议',
    'rejected' => '已否决',
    _ => topic.status,
  };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        topic.isActive ? Icons.topic : Icons.gavel,
        color: topic.isActive ? null : Colors.grey,
      ),
      title: Text(topic.title),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(label: Text(_statusLabel), visualDensity: VisualDensity.compact),
            if (topic.category.isNotEmpty)
              Text(topic.category, style: Theme.of(context).textTheme.bodySmall),
            if (topic.votes.for_ + topic.votes.against + topic.votes.abstain > 0)
              Text(
                '赞成 ${topic.votes.for_} / 反对 ${topic.votes.against} / 弃权 ${topic.votes.abstain}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (topic.status == 'resolved')
              Text('决议: ${topic.resolutionId ?? ''}',
                  style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      trailing: topic.isActive
          ? PopupMenuButton<String>(
              onSelected: (v) {
                switch (v) {
                  case 'second':
                    onSecond();
                  case 'debate':
                    onDebate();
                  case 'vote':
                    onVote();
                  case 'close':
                    onClose();
                }
              },
              itemBuilder: (_) => [
                if (topic.status == 'proposed' || topic.status == 'seconded')
                  const PopupMenuItem(value: 'second', child: Text('附议')),
                if (topic.status == 'seconded')
                  const PopupMenuItem(value: 'debate', child: Text('进入辩论')),
                if (topic.status == 'debated' || topic.status == 'voted')
                  const PopupMenuItem(value: 'vote', child: Text('表决')),
                if (topic.status == 'voted')
                  const PopupMenuItem(value: 'close', child: Text('归档')),
              ],
            )
          : null,
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(topic.title),
          content: SingleChildScrollView(
            child: Text(topic.content.isEmpty ? '（无内容）' : topic.content),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭'))],
        ),
      ),
    );
  }
}
