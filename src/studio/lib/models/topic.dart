// 议题模型：从动议到决议的五流程生命周期。

class Topic {
  const Topic({
    required this.id,
    required this.name,
    required this.title,
    required this.content,
    required this.category,
    required this.status,
    required this.proposerId,
    required this.seconderIds,
    required this.votes,
    this.resolutionId,
  });

  final String id;
  final String name; // slug
  final String title;
  final String content;
  final String category;
  final String status; // proposed → seconded → debated → voted → resolved / rejected
  final String proposerId;
  final List<String> seconderIds;
  final VoteResult votes;
  final String? resolutionId;

  bool get isActive =>
      status == 'proposed' || status == 'seconded' || status == 'debated' || status == 'voted';

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
    id: json['id'] as String,
    name: json['name'] as String,
    title: json['title'] as String,
    content: json['content'] as String? ?? '',
    category: json['category'] as String? ?? '',
    status: json['status'] as String,
    proposerId: json['proposerId'] as String? ?? '',
    seconderIds: (json['seconderIds'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
    votes: VoteResult.fromJson(json['votes'] as Map<String, dynamic>? ?? {}),
    resolutionId: json['resolutionId'] as String?,
  );
}

class VoteResult {
  const VoteResult({this.for_ = 0, this.against = 0, this.abstain = 0});

  final int for_;
  final int against;
  final int abstain;

  factory VoteResult.fromJson(Map<String, dynamic> json) => VoteResult(
    for_: json['for'] as int? ?? 0,
    against: json['against'] as int? ?? 0,
    abstain: json['abstain'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {'for': for_, 'against': against, 'abstain': abstain};
}
