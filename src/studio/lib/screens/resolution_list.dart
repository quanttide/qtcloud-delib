// 决议管理页面
//
// 决议清单：从本地内置数据源（profile 决议标本，assets/data/*.json）加载，
// 前后端解耦、离线可用；点击列表项从右侧弹窗显示详情，支持下拉刷新。
// （服务端 API 代码保留于 services/resolution_api.dart，未来恢复时切换注入）

import 'package:flutter/material.dart';

import '../models/resolution.dart';
import '../services/resolution_store.dart';
import 'resolution_detail.dart';

class ResolutionScreen extends StatefulWidget {
  const ResolutionScreen({super.key, this.store});

  /// 决议数据源（测试可注入替身，默认本地标本）
  final ResolutionStore? store;

  @override
  State<ResolutionScreen> createState() => _ResolutionScreenState();
}

class _ResolutionScreenState extends State<ResolutionScreen> {
  late final ResolutionStore _store =
      widget.store ?? const AssetResolutionStore();
  late Future<List<Resolution>> _future = _store.fetchResolutions();

  void _reload() {
    setState(() {
      _future = _store.fetchResolutions();
    });
  }

  /// 新建决议对话框（登录态下写入后端；本地标本只读会提示）。
  Future<void> _showCreate() async {
    final name = TextEditingController();
    final title = TextEditingController();
    final content = TextEditingController();
    final category = TextEditingController();
    final String? result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建决议'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: '名称（slug）')),
              TextField(controller: title, decoration: const InputDecoration(labelText: '标题')),
              TextField(controller: content, decoration: const InputDecoration(labelText: '内容'), maxLines: 3),
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
      await _store.createResolution(
        name: name.text.trim().isEmpty ? _slugify(title.text) : name.text.trim(),
        title: title.text.trim(),
        content: content.text,
        category: category.text.trim(),
      );
      _reload();
    } on ResolutionStoreException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  static String _slugify(String title) {
    return title.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  }

  /// 点击列表项，从右侧弹窗显示决议详情
  void _showDetail(BuildContext context, Resolution resolution) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '决议详情',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 8,
            child: SizedBox(
              width: 420,
              height: double.infinity,
              child: ResolutionDetailScreen(resolution: resolution),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: animation.drive(
            Tween(begin: const Offset(1, 0), end: Offset.zero),
          ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('决议管理')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreate,
        tooltip: '新建决议',
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Resolution>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorView(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }
          final List<Resolution> resolutions = snapshot.data ?? [];
          if (resolutions.isEmpty) {
            return const Center(child: Text('暂无决议'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              final Future<List<Resolution>> future = _store.fetchResolutions();
              setState(() {
                _future = future;
              });
              await future;
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: resolutions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final Resolution resolution = resolutions[index];
                return ListTile(
                  leading: const Icon(Icons.gavel),
                  title: Text(resolution.title),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (resolution.category.isNotEmpty)
                          Chip(
                            label: Text(resolution.category),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            labelStyle: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                            side: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.4),
                            ),
                          ),
                        Text(
                          resolution.name,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDetail(context, resolution),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// 加载失败视图：错误信息 + 重试
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 12),
            const Text('加载决议失败'),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
