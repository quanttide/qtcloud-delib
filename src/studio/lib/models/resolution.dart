// 决议模型
//
// 决议是决策记录：id 为 UUID，title 概括"决定了什么"，content 展开决议陈述，
// category 标注决议分类（如：治理、审计、档案、技术等）。
// 结构从实际议事档案标本中长出，不预设执行字段。
// content 当前为纯文本，未来可扩展为结构化内容。

class Resolution {
  const Resolution({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
  });

  /// 决议唯一标识（UUID）
  final String id;

  /// 决定了什么（如：周会实行记名表决制）
  final String title;

  /// 决议陈述：依据、表决情况、执行安排等（当前为文本，未来可扩展）
  final String content;

  /// 决议分类（如：治理、审计、档案、技术等）
  final String category;
}
