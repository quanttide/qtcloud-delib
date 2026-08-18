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
  final TextEditingController _searchCtrl = TextEditingController();
  String _statusFilter = _statusAll;
  String? _categoryFilter;

  static const String _statusAll = '全部状态';

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

  /// 本地过滤（245 条全量已拉取）：关键词 + 状态 + 类别。
  List<Topic> _applyFilters(List<Topic> topics) {
    final q = _searchCtrl.text.trim().toLowerCase();
    return topics.where((t) {
      if (_statusFilter != _statusAll && _statusLabel(t.status) != _statusFilter) {
        return false;
      }
      if (_categoryFilter != null && t.category != _categoryFilter) {
        return false;
      }
      if (q.isNotEmpty) {
        final haystack =
            '${t.title} ${t.content} ${t.source ?? ''} ${t.ledgerNo ?? ''} ${t.category} ${_statusLabel(t.status)}'
                .toLowerCase();
        if (!haystack.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
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
          final filtered = _applyFilters(topics);
          final categories = topics.map((t) => t.category).where((c) => c.isNotEmpty).toSet().toList()..sort();
          return Column(
            children: [
              _FilterBar(
                searchCtrl: _searchCtrl,
                statusFilter: _statusFilter,
                categoryFilter: _categoryFilter,
                categories: categories,
                statusOptions: _statusOptions,
                onSearchChanged: (_) => setState(() {}),
                onStatusChanged: (v) => setState(() => _statusFilter = v),
                onCategoryChanged: (v) => setState(() => _categoryFilter = v),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    final f = _api.fetchTopics();
                    setState(() => _future = f);
                    await f;
                  },
                  child: filtered.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: Text('没有匹配的议题')),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) => _TopicTile(
                            topic: filtered[index],
                            onSecond: () => _action(filtered[index], '附议', () => _api.second(filtered[index].id)),
                            onDebate: () => _action(filtered[index], '辩论', () => _api.debate(filtered[index].id)),
                            onVote: () => _showVoteDialog(filtered[index]),
                            onClose: () => _action(filtered[index], '归档', () => _api.close(filtered[index].id)),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 状态中文标签（列表 chip 与过滤共用）。
String _statusLabel(String status) => switch (status) {
  'proposed' => '动议',
  'seconded' => '附议',
  'debated' => '辩论',
  'voted' => '表决',
  'resolved' => '已决议',
  'rejected' => '已否决',
  _ => status,
};

const List<String> _statusOptions = ['全部状态', '动议', '附议', '辩论', '表决', '已决议', '已否决'];

/// 过滤栏：关键词搜索 + 状态 + 类别。
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.searchCtrl,
    required this.statusFilter,
    required this.categoryFilter,
    required this.categories,
    required this.statusOptions,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onCategoryChanged,
  });

  final TextEditingController searchCtrl;
  final String statusFilter;
  final String? categoryFilter;
  final List<String> categories;
  final List<String> statusOptions;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 220,
            child: TextField(
              controller: searchCtrl,
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                hintText: '搜索标题 / 内容 / 来源 / 编号',
                isDense: true,
                prefixIcon: Icon(Icons.search, size: 18),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          DropdownButton<String>(
            value: statusFilter,
            onChanged: (v) => onStatusChanged(v ?? statusFilter),
            items: [for (final s in statusOptions) DropdownMenuItem(value: s, child: Text(s))],
          ),
          DropdownButton<String?>(
            value: categoryFilter,
            hint: const Text('全部分类'),
            onChanged: onCategoryChanged,
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('全部分类')),
              for (final c in categories) DropdownMenuItem<String?>(value: c, child: Text(c)),
            ],
          ),
        ],
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
            Chip(label: Text(_statusLabel(topic.status)), visualDensity: VisualDensity.compact),
            if (topic.category.isNotEmpty)
              Text(topic.category, style: Theme.of(context).textTheme.bodySmall),
            if ((topic.source ?? '').isNotEmpty)
              Text(topic.source ?? '', style: Theme.of(context).textTheme.bodySmall),
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
