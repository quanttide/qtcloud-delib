// 决议管理页面
//
// 决议清单：展示决策记录（title），点击列表项从右侧弹窗显示详情。

import 'package:flutter/material.dart';

import '../models/resolution.dart';
import 'resolution_detail.dart';

class ResolutionScreen extends StatelessWidget {
  const ResolutionScreen({super.key});

  static const List<Resolution> resolutions = [
    Resolution(
      id: 'f29eb8a9-dc51-4527-ac6b-019ce0d03d79',
      name: 'weekly-vote',
      title: '周会实行记名表决制',
      content:
          '自本周起，公司周会重大事项实行记名表决，常规事项不记名。'
          '表决结果实时统计并留痕存档，作为审计与合规依据。',
      category: '治理',
    ),
    Resolution(
      id: '86c66247-af30-49a8-b24b-3e4a611d316a',
      name: 'audit-charter',
      title: '通过《周会审计流程章程》',
      content:
          '审议通过《量潮科技周会审计流程章程》。'
          '会前、会中、会后三段式审计自下周起试运行，'
          '审计负责人周四完成审计报告审核，周五完成周报审核。',
      category: '审计',
    ),
    Resolution(
      id: 'e3c0649a-cdc9-4690-a898-a275278dc122',
      name: 'archive-weekly',
      title: '议事档案按年份+周次归档',
      content:
          '议事档案以议题为单位，按年份+周次组织，归档后标注时间确保可追溯。'
          '由书记处轮值书记负责整理汇总，每周一开始、周五提交。',
      category: '档案',
    ),
    Resolution(
      id: '1afdfac9-ca88-493c-9c01-f5ef944faf03',
      name: 'weekly-report-rules',
      title: '周报引用规则',
      content:
          '周报只可引用已提交到工作档案、工作章程、工作手册的资料，'
          '不可引用原始汇报文档与原始议事文档。',
      category: '规范',
    ),
  ];

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
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: resolutions.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final Resolution resolution = resolutions[index];
          return ListTile(
            leading: const Icon(Icons.gavel),
            title: Text(resolution.title),
            subtitle: Text(
              resolution.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDetail(context, resolution),
          );
        },
      ),
    );
  }
}
