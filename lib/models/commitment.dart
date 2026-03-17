enum CommitmentStatus { open, closed }

enum MemberIntent { inTrying, out, pending }

class CommitmentResponse {
  final String userId;
  final MemberIntent intent;
  final bool completed;
  final DateTime? completedAt;
  final String? note; // short reaction or emoji

  CommitmentResponse({
    required this.userId,
    required this.intent,
    this.completed = false,
    this.completedAt,
    this.note,
  });

  factory CommitmentResponse.fromJson(Map<String, dynamic> json) {
    return CommitmentResponse(
      userId: json['user_id'] as String,
      intent: MemberIntent.values.firstWhere(
        (e) => e.name == (json['intent'] as String? ?? 'pending'),
        orElse: () => MemberIntent.pending,
      ),
      completed: json['completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'intent': intent.name,
      'completed': completed,
      'completed_at': completedAt?.toIso8601String(),
      'note': note,
    };
  }

  CommitmentResponse copyWith({
    String? userId,
    MemberIntent? intent,
    bool? completed,
    DateTime? completedAt,
    String? note,
  }) {
    return CommitmentResponse(
      userId: userId ?? this.userId,
      intent: intent ?? this.intent,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      note: note ?? this.note,
    );
  }
}

class Commitment {
  final String id;
  final String circleId;
  final String createdBy;
  final String title;
  final String? description;
  final DateTime dueDate;
  final CommitmentStatus status;
  final Map<String, CommitmentResponse> responses; // userId → response
  final DateTime createdAt;

  Commitment({
    required this.id,
    required this.circleId,
    required this.createdBy,
    required this.title,
    this.description,
    required this.dueDate,
    this.status = CommitmentStatus.open,
    this.responses = const {},
    required this.createdAt,
  });

  factory Commitment.fromJson(Map<String, dynamic> json) {
    final rawResponses =
        json['responses'] as Map<String, dynamic>? ?? {};
    final responses = rawResponses.map(
      (k, v) => MapEntry(k, CommitmentResponse.fromJson(v as Map<String, dynamic>)),
    );

    return Commitment(
      id: json['id'] as String,
      circleId: json['circle_id'] as String,
      createdBy: json['created_by'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: DateTime.parse(json['due_date'] as String),
      status: CommitmentStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'open'),
        orElse: () => CommitmentStatus.open,
      ),
      responses: responses,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'circle_id': circleId,
      'created_by': createdBy,
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String(),
      'status': status.name,
      'responses': responses.map((k, v) => MapEntry(k, v.toJson())),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Number of members who have completed this commitment.
  int get completedCount =>
      responses.values.where((r) => r.completed).length;

  /// Number of members who intend to try.
  int get inCount =>
      responses.values.where((r) => r.intent == MemberIntent.inTrying).length;

  bool isCompletedBy(String userId) =>
      responses[userId]?.completed ?? false;

  MemberIntent intentOf(String userId) =>
      responses[userId]?.intent ?? MemberIntent.pending;

  Commitment copyWith({
    String? id,
    String? circleId,
    String? createdBy,
    String? title,
    String? description,
    DateTime? dueDate,
    CommitmentStatus? status,
    Map<String, CommitmentResponse>? responses,
    DateTime? createdAt,
  }) {
    return Commitment(
      id: id ?? this.id,
      circleId: circleId ?? this.circleId,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      responses: responses ?? this.responses,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
