/// Model for Audio Rooms (Live Spaces)
class AudioRoom {
  final String id;
  final String hostId;
  final String hostUsername;
  final String? hostAvatarUrl;
  final String title;
  final String? topic;
  final RoomStatus status;
  final List<AudioRoomParticipant> participants;
  final List<String> speakerIds;
  final int listenerCount;
  final bool isRecording;
  final DateTime createdAt;
  final DateTime? endedAt;
  final RoomPrivacy privacy;
  final String? scheduledFor;

  AudioRoom({
    required this.id,
    required this.hostId,
    required this.hostUsername,
    this.hostAvatarUrl,
    required this.title,
    this.topic,
    this.status = RoomStatus.live,
    this.participants = const [],
    this.speakerIds = const [],
    this.listenerCount = 0,
    this.isRecording = false,
    required this.createdAt,
    this.endedAt,
    this.privacy = RoomPrivacy.public,
    this.scheduledFor,
  });

  factory AudioRoom.fromJson(Map<String, dynamic> json) {
    return AudioRoom(
      id: json['id'],
      hostId: json['host_id'],
      hostUsername: json['host_username'] ?? 'Unknown',
      hostAvatarUrl: json['host_avatar_url'],
      title: json['title'],
      topic: json['topic'],
      status: RoomStatus.fromString(json['status'] ?? 'live'),
      participants:
          (json['participants'] as List?)
              ?.map((p) => AudioRoomParticipant.fromJson(p))
              .toList() ??
          [],
      speakerIds: (json['speaker_ids'] as List?)?.cast<String>() ?? [],
      listenerCount: json['listener_count'] ?? 0,
      isRecording: json['is_recording'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      endedAt:
          json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
      privacy: RoomPrivacy.fromString(json['privacy'] ?? 'public'),
      scheduledFor: json['scheduled_for'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'host_id': hostId,
      'title': title,
      'topic': topic,
      'status': status.value,
      'speaker_ids': speakerIds,
      'is_recording': isRecording,
      'privacy': privacy.value,
      'scheduled_for': scheduledFor,
    };
  }

  bool get isLive => status == RoomStatus.live;
  bool get isScheduled => status == RoomStatus.scheduled;
  bool get hasEnded => status == RoomStatus.ended;

  AudioRoom copyWith({
    String? title,
    String? topic,
    RoomStatus? status,
    List<AudioRoomParticipant>? participants,
    List<String>? speakerIds,
    int? listenerCount,
    bool? isRecording,
  }) {
    return AudioRoom(
      id: id,
      hostId: hostId,
      hostUsername: hostUsername,
      hostAvatarUrl: hostAvatarUrl,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      status: status ?? this.status,
      participants: participants ?? this.participants,
      speakerIds: speakerIds ?? this.speakerIds,
      listenerCount: listenerCount ?? this.listenerCount,
      isRecording: isRecording ?? this.isRecording,
      createdAt: createdAt,
      endedAt: endedAt,
      privacy: privacy,
      scheduledFor: scheduledFor,
    );
  }
}

enum RoomStatus {
  scheduled('scheduled'),
  live('live'),
  ended('ended');

  final String value;
  const RoomStatus(this.value);

  static RoomStatus fromString(String value) {
    return RoomStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => RoomStatus.live,
    );
  }
}

enum RoomPrivacy {
  public('public'),
  followers('followers'),
  invited('invited');

  final String value;
  const RoomPrivacy(this.value);

  static RoomPrivacy fromString(String value) {
    return RoomPrivacy.values.firstWhere(
      (p) => p.value == value,
      orElse: () => RoomPrivacy.public,
    );
  }
}

class AudioRoomParticipant {
  final String id;
  final String roomId;
  final String userId;
  final String username;
  final String? avatarUrl;
  final ParticipantRole role;
  final bool isMuted;
  final bool isSpeaking;
  final DateTime joinedAt;

  AudioRoomParticipant({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.role = ParticipantRole.listener,
    this.isMuted = true,
    this.isSpeaking = false,
    required this.joinedAt,
  });

  factory AudioRoomParticipant.fromJson(Map<String, dynamic> json) {
    return AudioRoomParticipant(
      id: json['id'],
      roomId: json['room_id'],
      userId: json['user_id'],
      username: json['username'] ?? 'Unknown',
      avatarUrl: json['avatar_url'],
      role: ParticipantRole.fromString(json['role'] ?? 'listener'),
      isMuted: json['is_muted'] ?? true,
      isSpeaking: json['is_speaking'] ?? false,
      joinedAt: DateTime.parse(json['joined_at']),
    );
  }

  bool get isSpeaker =>
      role == ParticipantRole.speaker || role == ParticipantRole.host;
  bool get isHost => role == ParticipantRole.host;
}

enum ParticipantRole {
  host('host'),
  coHost('co_host'),
  speaker('speaker'),
  listener('listener');

  final String value;
  const ParticipantRole(this.value);

  static ParticipantRole fromString(String value) {
    return ParticipantRole.values.firstWhere(
      (r) => r.value == value,
      orElse: () => ParticipantRole.listener,
    );
  }
}

/// Hand raise request
class HandRaiseRequest {
  final String id;
  final String roomId;
  final String userId;
  final String username;
  final String? avatarUrl;
  final DateTime requestedAt;
  final HandRaiseStatus status;

  HandRaiseRequest({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.requestedAt,
    this.status = HandRaiseStatus.pending,
  });

  factory HandRaiseRequest.fromJson(Map<String, dynamic> json) {
    return HandRaiseRequest(
      id: json['id'],
      roomId: json['room_id'],
      userId: json['user_id'],
      username: json['username'] ?? 'Unknown',
      avatarUrl: json['avatar_url'],
      requestedAt: DateTime.parse(json['requested_at']),
      status: HandRaiseStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => HandRaiseStatus.pending,
      ),
    );
  }
}

enum HandRaiseStatus { pending, approved, rejected }
