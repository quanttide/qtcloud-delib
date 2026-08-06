// 决议管理页面
//
// 决议清单：从服务端（provider）加载决议记录（title），
// 点击列表项从右侧弹窗显示详情；支持下拉刷新与新建决议。

import 'package:flutter/material.dart';

import '../models/resolution.dart';
import '../services/resolution_api.dart';
import 'resolution_detail.dart';

class ResolutionScreen extends StatefulWidget {
  const ResolutionScreen({super.key, this.api});

  /// 决议 API 客户端（测试可注入替身，默认对接真实服务端）
  final ResolutionApi? api;

  @override
  State<ResolutionScreen> createState() => _ResolutionScreenState();
}

class _ResolutionScreenState extends State<ResolutionScreen> {
  late final ResolutionApi _api = widget.api ?? ResolutionApi();
  late Future<List<Resolution>> _future = _api.fetchResolutions();

  void _reload() {
    setState(() {
      _future = _api.fetchResolutions();
    });
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

  /// 新建决议：弹窗收集表单并提交服务端，成功后刷新列表
  Future<void> _createResolution() async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();
    final TextEditingController categoryController = TextEditingController();

    final bool? submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建决议'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: '标题 *',
                    hintText: '决定了什么（如：周会实行记名表决制）',
                  ),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? '请输入标题' : null,
                ),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '标识（slug）',
                    hintText: '留空则由标题生成（如 weekly-vote）',
                  ),
                ),
                TextFormField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: '分类',
                    hintText: '如：治理、审计、档案、技术',
                  ),
                ),
                TextFormField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: '陈述',
                    hintText: '决议陈述：依据、表决情况、执行安排等',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('提交'),
          ),
        ],
      ),
    );
    if (submitted != true || !mounted) {
      return;
    }

    final String title = titleController.text.trim();
    String name = nameController.text.trim();
    if (name.isEmpty) {
      name = _slugify(title);
    }
    try {
      await _api.createResolution(
        name: name,
        title: title,
        content: contentController.text.trim(),
        category: categoryController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('决议已创建')));
      _reload();
    } on ResolutionApiException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('创建失败：${e.message}')));
    }
  }

  /// 标题转 slug：小写、去标点、空白转连字符
  static String _slugify(String title) {
    final String normalized = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s-]', unicode: true), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
    return normalized.isEmpty ? 'resolution' : normalized;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('决议管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新建决议',
            onPressed: _createResolution,
          ),
        ],
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
            return const Center(child: Text('暂无决议，点击右上角新建'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              final Future<List<Resolution>> future = _api.fetchResolutions();
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
