// 决议管理页面
//
// 决议看板：展示决议的执行状态，逾期未完成逐级预警。

import 'package:flutter/material.dart';

import '../models/resolution.dart';

class ResolutionScreen extends StatefulWidget {
  const ResolutionScreen({super.key});

  @override
  State<ResolutionScreen> createState() => ResolutionScreenState();
}

class ResolutionScreenState extends State<ResolutionScreen> {
  final List<Resolution> _resolutions = [
    Resolution(
      id: '1',
      content: '搭建议事云议题管理模块，支持九种议题类型模板化创建',
      assignee: '张三',
      dueDate: DateTime(2026, 8, 7),
      status: ResolutionStatus.inProgress,
      sourceMeeting: '2026年第32周周会',
    ),
    Resolution(
      id: '2',
      content: '完成议事档案按年份+周次自动归档功能',
      assignee: '李四',
      dueDate: DateTime(2026, 8, 1),
      status: ResolutionStatus.overdue,
      sourceMeeting: '2026年第31周周会',
    ),
    Resolution(
      id: '3',
      content: '制定电子表决规则（记名/不记名）并同步至章程',
      assignee: '王五',
      dueDate: DateTime(2026, 8, 14),
      status: ResolutionStatus.pending,
      sourceMeeting: '2026年第32周周会',
    ),
    Resolution(
      id: '4',
      content: '周会审计评分机制上线试运行',
      assignee: '赵六',
      dueDate: DateTime(2026, 7, 25),
      status: ResolutionStatus.completed,
      sourceMeeting: '2026年第29周周会',
    ),
  ];

  void _updateStatus(Resolution resolution, ResolutionStatus status) {
    setState(() {
      final int index = _resolutions.indexOf(resolution);
      _resolutions[index] = Resolution(
        id: resolution.id,
        content: resolution.content,
        assignee: resolution.assignee,
        dueDate: resolution.dueDate,
        status: status,
        sourceMeeting: resolution.sourceMeeting,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('决议管理'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          for (final resolution in _resolutions) _ResolutionCard(
            resolution: resolution,
            onStatusChanged: (status) => _updateStatus(resolution, status),
          ),
        ],
      ),
    );
  }
}

class _ResolutionCard extends StatelessWidget {
  const _ResolutionCard({
    required this.resolution,
    required this.onStatusChanged,
  });

  final Resolution resolution;
  final ValueChanged<ResolutionStatus> onStatusChanged;

  Color _statusColor(BuildContext context) {
    switch (resolution.status) {
      case ResolutionStatus.completed:
        return Colors.green;
      case ResolutionStatus.overdue:
        return Colors.red;
      case ResolutionStatus.inProgress:
        return Colors.blue;
      case ResolutionStatus.pending:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    resolution.content,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text(resolution.status.label),
                  backgroundColor: _statusColor(context).withValues(alpha: 0.15),
                  labelStyle: TextStyle(color: _statusColor(context)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('负责人：${resolution.assignee}'),
            Text('截止：${resolution.dueDate.toString().split(' ').first}'),
            if (resolution.sourceMeeting != null)
              Text('来源：${resolution.sourceMeeting}'),
            if (resolution.status == ResolutionStatus.overdue) ...[
              const SizedBox(height: 8),
              Text(
                '⚠ 已逾期，请尽快处理',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                for (final status in ResolutionStatus.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(status.label),
                      onPressed: status == resolution.status
                          ? null
                          : () => onStatusChanged(status),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
