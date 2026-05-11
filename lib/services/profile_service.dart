// lib/services/profile_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import '../models/profile.dart';

class ProfileService {
  final SupabaseClient _client = SupabaseConfig.client;

  /// 1. Get the profile of the currently logged-in user
  Future<Profile?> getCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return await getProfile(user.id);
  }

  /// 2. Get any specific profile by ID
  Future<Profile?> getProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;
      return Profile.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  /// 3. Create or update a profile
  /// Note: Ensure your Profile.toJson() only includes columns that exist in your DB
  Future<Profile> upsertProfile(Profile profile) async {
    final response = await _client
        .from('profiles')
        .upsert(profile.toJson())
        .select()
        .single();

    return Profile.fromJson(response);
  }

  /// 4. Specifically for the Create Account screen
  Future<Profile> createProfile({
    required String userId,
    String? fullName,
    String? role,
    String? team,
  }) async {
    final profile = Profile(
      id: userId,
      fullName: fullName,
      role: role,
      team: team ?? 'Quincy University',
      createdAt: DateTime.now(),
      // We are NOT including totalScore/gameNumber here to avoid DB errors
    );

    return await upsertProfile(profile);
  }

  /// 5. Update specific fields without a full Profile object
  Future<void> updateBasicInfo({
    required String userId,
    required String name,
    required String role,
  }) async {
    await _client.from('profiles').update({
      'name': name, 
      'role': role,
    }).eq('id', userId);
  }
}