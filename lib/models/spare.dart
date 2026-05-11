// lib/models/spare.dartclass Spare

class Spare {
  final String? id;
  final String sessionId;
  final String targetSpare;
  final int makes;
  final int misses;
  final String? notes;
  final DateTime? createdAt;

  Spare({
    this.id,
    required this.sessionId,
    required this.targetSpare,
    required this.makes,
    required this.misses,
    this.notes,
    this.createdAt,
  });

  factory Spare.fromJson(Map<String, dynamic> json) {
    return Spare(
      id: json['id'] as String?,
      sessionId: json['session_id'] as String,
      targetSpare: json['target_spare'] as String,
      makes: json['makes'] as int,
      misses: json['misses'] as int,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'session_id': sessionId,
      'target_spare': targetSpare,
      'makes': makes,
      'misses': misses,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
