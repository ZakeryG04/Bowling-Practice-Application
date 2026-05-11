// lib/services/spare_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/session.dart' as bowling_session;
import '../supabase_config.dart';

class SpareService {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<bowling_session.Session> getOrCreateSpareSession() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final existingSession = await _client
        .from('sessions')
        .select()
        .eq('profile_id', user.id)
        .eq('session_type', 'drill')
        .gte('created_at', startOfDay.toIso8601String())
        .lt('created_at', endOfDay.toIso8601String())
        .maybeSingle();

    if (existingSession != null) {
      return bowling_session.Session.fromJson(existingSession);
    }

    final newSession = bowling_session.Session(
      profileId: user.id,
      sessionType: 'drill',
      createdAt: DateTime.now(),
    );

    final response = await _client
        .from('sessions')
        .insert(newSession.toJson())
        .select()
        .single();

    return bowling_session.Session.fromJson(response);
  }

  Future<void> saveSpareAttempt({
    required String targetSpare,
    required bool made,
  }) async {
    await saveSpareSession(
      spareAttempts: [
        {
          'target_spare': targetSpare,
          'makes': made ? 1 : 0,
          'misses': made ? 0 : 1,
          'created_at': DateTime.now(),
        }
      ],
    );
  }

  Future<void> saveSpareSession({
    required List<Map<String, dynamic>> spareAttempts,
  }) async {
    if (spareAttempts.isEmpty) {
      return;
    }

    final session = await getOrCreateSpareSession();
    if (session.id == null) {
      throw Exception('Unable to create session.');
    }

    final Map<String, Map<String, dynamic>> aggregatedAttempts = {};
    for (final attempt in spareAttempts) {
      final targetSpare = attempt['target_spare'] as String;
      final makes = attempt['makes'] as int;
      final misses = attempt['misses'] as int;
      final createdAt = attempt['created_at'] as DateTime;

      if (aggregatedAttempts.containsKey(targetSpare)) {
        final existing = aggregatedAttempts[targetSpare]!;
        existing['makes'] = (existing['makes'] as int) + makes;
        existing['misses'] = (existing['misses'] as int) + misses;
        if ((existing['created_at'] as DateTime).isAfter(createdAt)) {
          existing['created_at'] = createdAt;
        }
      } else {
        aggregatedAttempts[targetSpare] = {
          'target_spare': targetSpare,
          'makes': makes,
          'misses': misses,
          'created_at': createdAt,
          if (attempt['notes'] != null) 'notes': attempt['notes'] as String,
        };
      }
    }

    final existingRows = await _client
        .from('spare_practice')
        .select()
        .eq('session_id', session.id!)
        .inFilter('target_spare', aggregatedAttempts.keys.toList());

    final Map<String, Map<String, dynamic>> existingBySpare = {};
    if (existingRows is List) {
      for (final row in existingRows.cast<Map<String, dynamic>>()) {
        final targetSpare = row['target_spare'] as String?;
        if (targetSpare != null) {
          existingBySpare[targetSpare] = row;
        }
      }
    }

    final List<Map<String, dynamic>> inserts = [];
    final List<Future> updates = [];

    for (final attempt in aggregatedAttempts.values) {
      final targetSpare = attempt['target_spare'] as String;
      final makes = attempt['makes'] as int;
      final misses = attempt['misses'] as int;
      final createdAt = attempt['created_at'] as DateTime;
      final notes = attempt['notes'] as String?;

      final existing = existingBySpare[targetSpare];
      if (existing != null) {
        final updatedMakes = (existing['makes'] as int? ?? 0) + makes;
        final updatedMisses = (existing['misses'] as int? ?? 0) + misses;
        final updatePayload = <String, dynamic>{
          'makes': updatedMakes,
          'misses': updatedMisses,
        };
        if (notes != null) {
          updatePayload['notes'] = notes;
        }

        updates.add(
          _client
              .from('spare_practice')
              .update(updatePayload)
              .eq('session_id', session.id!)
              .eq('target_spare', targetSpare),
        );
      } else {
        inserts.add({
          'session_id': session.id!,
          'target_spare': targetSpare,
          'makes': makes,
          'misses': misses,
          'created_at': createdAt.toIso8601String(),
          if (notes != null) 'notes': notes,
        });
      }
    }

    if (inserts.isNotEmpty) {
      await _client.from('spare_practice').insert(inserts);
    }
    if (updates.isNotEmpty) {
      await Future.wait(updates);
    }
  }
}