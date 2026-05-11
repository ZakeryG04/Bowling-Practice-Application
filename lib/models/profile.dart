// lib/models/profile.dart
class Profile {
  final String id;
  final String? fullName;
  final String? role;
  final String? team;
  final DateTime? createdAt;
  // Note: These are kept as variables in the class so your UI doesn't break,
  // but we won't send them to the database.
  final int totalScore;
  final int gameNumber;

  Profile({
    required this.id,
    this.fullName,
    this.role,
    this.team,
    this.createdAt,
    this.totalScore = 0,
    this.gameNumber = 0,
  });

  // Create Profile from JSON (from Supabase)
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      // Check if your DB uses 'name' or 'full_name'
      fullName: (json['full_name'] ?? json['name']) as String?, 
      role: json['role'] as String?,
      team: json['team'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      // We default these to 0 because they don't exist in your DB columns
      totalScore: 0, 
      gameNumber: 0,
    );
  }

  // Convert Profile to JSON (for Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName, // If DB uses 'name', change this key to 'name'
      'role': role,
      'team': team,
      'created_at': createdAt?.toIso8601String(),
      // REMOVED 'total_score' and 'game_number' from here.
      // This stops the "PostgrestException: Could not find column" error.
    };
  }

  // Create a copy with updated fields
  Profile copyWith({
    String? id,
    String? fullName,
    String? role,
    String? team,
    DateTime? createdAt,
    int? totalScore,
    int? gameNumber,
  }) {
    return Profile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      team: team ?? this.team,
      createdAt: createdAt ?? this.createdAt,
      totalScore: totalScore ?? this.totalScore,
      gameNumber: gameNumber ?? this.gameNumber,
    );
  }
}