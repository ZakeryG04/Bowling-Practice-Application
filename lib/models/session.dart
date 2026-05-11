// lib/models/session.dart
class Session {
  final String? id;
  final String profileId;
  final String sessionType; // 'game' or 'drill'
  final DateTime? createdAt;

  Session({
    this.id,
    required this.profileId,
    required this.sessionType,
    this.createdAt,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String?,
      profileId: json['profile_id'] as String,
      sessionType: json['session_type'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'profile_id': profileId,
      'session_type': sessionType,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}