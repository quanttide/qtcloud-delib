// 决议模型
//
// 《会议纪要决议案》——做什么、谁负责、何时完成。

enum ResolutionStatus {
  pending('待执行'),
  inProgress('执行中'),
  completed('已完成'),
  overdue('已逾期');

  const ResolutionStatus(this.label);

  final String label;
}

class Resolution {
  const Resolution({
    required this.id,
    required this.content,
    required this.assignee,
    required this.dueDate,
    required this.status,
    this.sourceMeeting,
  });

  /// 做什么
  final String content;

  /// 谁负责
  final String assignee;

  /// 何时完成
  final DateTime dueDate;

  /// 执行状态
  final ResolutionStatus status;

  /// 来源会议/动议
  final String? sourceMeeting;

  final String id;
}
