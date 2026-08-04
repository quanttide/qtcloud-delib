// 决议模型
//
// 决议是决策记录：title 概括"决定了什么"，description 展开决议陈述。
// 结构从实际议事档案标本中长出，不预设执行字段。

class Resolution {
  const Resolution({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;

  /// 决定了什么（如：周会实行记名表决制）
  final String title;

  /// 决议陈述：依据、表决情况、执行安排等（自由文本）
  final String description;
}
