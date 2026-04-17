/// Model for enhanced interactive polls
class EnhancedPoll {
  final String id;
  final String? postId;
  final String question;
  final PollType pollType;
  final bool isAnonymous;
  final DateTime? endsAt;
  final DateTime createdAt;
  final List<PollOption> options;
  final int totalVotes;
  final bool hasVoted;
  final String? userVotedOptionId;

  EnhancedPoll({
    required this.id,
    this.postId,
    required this.question,
    this.pollType = PollType.single,
    this.isAnonymous = false,
    this.endsAt,
    required this.createdAt,
    required this.options,
    this.totalVotes = 0,
    this.hasVoted = false,
    this.userVotedOptionId,
  });

  bool get isExpired => endsAt != null && DateTime.now().isAfter(endsAt!);
  bool get isActive => !isExpired;

  EnhancedPoll copyWith({
    String? id,
    String? postId,
    String? question,
    PollType? pollType,
    bool? isAnonymous,
    DateTime? endsAt,
    DateTime? createdAt,
    List<PollOption>? options,
    int? totalVotes,
    bool? hasVoted,
    String? userVotedOptionId,
  }) {
    return EnhancedPoll(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      question: question ?? this.question,
      pollType: pollType ?? this.pollType,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      endsAt: endsAt ?? this.endsAt,
      createdAt: createdAt ?? this.createdAt,
      options: options ?? this.options,
      totalVotes: totalVotes ?? this.totalVotes,
      hasVoted: hasVoted ?? this.hasVoted,
      userVotedOptionId: userVotedOptionId ?? this.userVotedOptionId,
    );
  }

  factory EnhancedPoll.fromJson(Map<String, dynamic> json) {
    return EnhancedPoll(
      id: json['id'],
      postId: json['post_id'],
      question: json['question'],
      pollType: PollType.fromString(json['poll_type'] ?? 'single'),
      isAnonymous: json['is_anonymous'] ?? false,
      endsAt: json['ends_at'] != null ? DateTime.parse(json['ends_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      options:
          (json['options'] as List?)
              ?.map((o) => PollOption.fromJson(o))
              .toList() ??
          [],
      totalVotes: json['total_votes'] ?? 0,
      hasVoted: json['has_voted'] ?? false,
      userVotedOptionId: json['user_voted_option_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'question': question,
      'poll_type': pollType.value,
      'is_anonymous': isAnonymous,
      'ends_at': endsAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

enum PollType {
  single('single', 'Single Choice'),
  multiple('multiple', 'Multiple Choice'),
  thisOrThat('this_or_that', 'This or That'),
  quiz('quiz', 'Quiz');

  final String value;
  final String label;
  const PollType(this.value, this.label);

  static PollType fromString(String value) {
    return PollType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => PollType.single,
    );
  }
}

class PollOption {
  final String id;
  final String pollId;
  final String text;
  final int order;
  final bool isCorrect;
  final int voteCount;
  final double percentage;

  PollOption({
    required this.id,
    required this.pollId,
    required this.text,
    this.order = 0,
    this.isCorrect = false,
    this.voteCount = 0,
    this.percentage = 0,
  });

  PollOption copyWith({
    String? id,
    String? pollId,
    String? text,
    int? order,
    bool? isCorrect,
    int? voteCount,
    double? percentage,
  }) {
    return PollOption(
      id: id ?? this.id,
      pollId: pollId ?? this.pollId,
      text: text ?? this.text,
      order: order ?? this.order,
      isCorrect: isCorrect ?? this.isCorrect,
      voteCount: voteCount ?? this.voteCount,
      percentage: percentage ?? this.percentage,
    );
  }

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'],
      pollId: json['poll_id'],
      text: json['option_text'],
      order: json['option_order'] ?? 0,
      isCorrect: json['is_correct'] ?? false,
      voteCount: json['vote_count'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'poll_id': pollId,
      'option_text': text,
      'option_order': order,
      'is_correct': isCorrect,
    };
  }
}

class PollVote {
  final String id;
  final String pollId;
  final String optionId;
  final String userId;
  final DateTime createdAt;

  PollVote({
    required this.id,
    required this.pollId,
    required this.optionId,
    required this.userId,
    required this.createdAt,
  });

  factory PollVote.fromJson(Map<String, dynamic> json) {
    return PollVote(
      id: json['id'],
      pollId: json['poll_id'],
      optionId: json['option_id'],
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
