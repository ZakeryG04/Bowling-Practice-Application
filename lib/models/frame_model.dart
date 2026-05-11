// lib/models/frame.dart
class Frame {
  final String? id;
  final String gameId;
  final int frameNumber; // 1-10
  final int? shot1;
  final int? shot2;
  final int? shot3;
  final List<int> pinsRemaining;
  final bool isSplit;
  final bool isMakeable;
  final DateTime? createdAt;

  Frame({
    this.id,
    required this.gameId,
    required this.frameNumber,
    this.shot1,
    this.shot2,
    this.shot3,
    this.pinsRemaining = const [],
    this.isSplit = false,
    this.isMakeable = true,
    this.createdAt,
  });

  factory Frame.fromJson(Map<String, dynamic> json) {
    return Frame(
      id: json['id'] as String?,
      gameId: json['game_id'] as String,
      frameNumber: json['frame_number'] as int,
      shot1: json['shot_1'] as int?,
      shot2: json['shot_2'] as int?,
      shot3: json['shot_3'] as int?,
      pinsRemaining: List<int>.from(json['pins_remaining'] ?? []),
      isSplit: json['is_split'] as bool? ?? false,
      isMakeable: json['is_makeable'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'game_id': gameId,
      'frame_number': frameNumber,
      if (shot1 != null) 'shot_1': shot1,
      if (shot2 != null) 'shot_2': shot2,
      if (shot3 != null) 'shot_3': shot3,
      'pins_remaining': pinsRemaining,
      'is_split': isSplit,
      'is_makeable': isMakeable,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}