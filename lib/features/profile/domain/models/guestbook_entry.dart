class GuestbookEntry {
  final String id;
  final String profileId;
  final String visitorId;
  final String message;
  final DateTime createdAt;
  
  // These fields are joined from profiles
  final String visitorName;
  final String visitorAvatar;

  const GuestbookEntry({
    required this.id,
    required this.profileId,
    required this.visitorId,
    required this.message,
    required this.createdAt,
    this.visitorName = 'Visitor',
    this.visitorAvatar = '',
  });

  factory GuestbookEntry.fromJson(Map<String, dynamic> json) {
    return GuestbookEntry(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      visitorId: json['visitor_id'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      visitorName: json['profiles']?['username'] ?? json['profiles']?['full_name'] ?? 'Visitor',
      visitorAvatar: json['profiles']?['avatar_url'] ?? '',
    );
  }
}
