// lib/models/game.dart
class Game {
  final String? id;
  final String sessionId;
  final int gameNumber;
  final int totalScore;
  final DateTime? createdAt;

  Game({
    this.id,
    required this.sessionId,
    required this.gameNumber,
    required this.totalScore,
    this.createdAt,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'] as String?,
      sessionId: json['session_id'] as String,
      gameNumber: json['game_number'] as int,
      totalScore: json['total_score'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'session_id': sessionId,
      'game_number': gameNumber,
      'total_score': totalScore,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}