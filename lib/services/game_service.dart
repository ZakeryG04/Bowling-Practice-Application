// lib/services/game_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import '../models/game.dart';
import '../models/session.dart' as bowling_session;
import 'package:flutter/foundation.dart';

class GameService {
  final SupabaseClient _client = SupabaseConfig.client;

  // Get or create a game session for the current user
  Future<bowling_session.Session> getOrCreateGameSession() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Try to find an existing game session for today
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final existingSession = await _client
        .from('sessions')
        .select()
        .eq('profile_id', user.id)
        .eq('session_type', 'game')
        .gte('created_at', startOfDay.toIso8601String())
        .lt('created_at', endOfDay.toIso8601String())
        .maybeSingle();

    if (existingSession != null) {
      return bowling_session.Session.fromJson(existingSession);
    }

    // Create a new session
    final newSession = bowling_session.Session(
      profileId: user.id,
      sessionType: 'game',
      createdAt: DateTime.now(),
    );

    final response = await _client
        .from('sessions')
        .insert(newSession.toJson())
        .select()
        .single();

    return bowling_session.Session.fromJson(response);
  }

  // Save a completed game with frames
  Future<Game> saveGameWithFrames({
    required int totalScore,
    required List<List<int?>> frameRolls,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final session = await getOrCreateGameSession();

    // Get the next game number for this session
    final existingGames = await _client
        .from('games')
        .select('game_number')
        .eq('session_id', session.id!)
        .order('game_number', ascending: false)
        .limit(1);

    final nextGameNumber = existingGames.isNotEmpty
        ? (existingGames[0]['game_number'] as int) + 1
        : 1;

    // Create the game
    final game = Game(
      sessionId: session.id!,
      gameNumber: nextGameNumber,
      totalScore: totalScore,
      createdAt: DateTime.now(),
    );

    final gameResponse = await _client
        .from('games')
        .insert(game.toJson())
        .select()
        .single();

    final savedGame = Game.fromJson(gameResponse);

    // Save individual frames
    await _saveFrames(savedGame.id!, frameRolls);

    // Note: Stats are now calculated directly from games table, no cache needed

    return savedGame;
  }

  // Save frames for a game
  Future<void> _saveFrames(String gameId, List<List<int?>> frameRolls) async {
    final frames = <Map<String, dynamic>>[];

    for (int i = 0; i < frameRolls.length && i < 10; i++) {
      final frameData = frameRolls[i];
      frames.add({
        'game_id': gameId,
        'frame_number': i + 1,
        'shot_1': frameData.isNotEmpty ? frameData[0] : null,
        'shot_2': frameData.length > 1 ? frameData[1] : null,
        'shot_3': frameData.length > 2 ? frameData[2] : null,
        'pins_remaining': [], // Could be calculated based on shots
        'is_split': false, // Could be determined based on pin layout
        'is_makeable': true,
      });
    }

    if (frames.isNotEmpty) {
      await _client.from('frames').insert(frames);
    }
  }

  // Get user statistics directly from games table
  Future<Map<String, dynamic>> getUserStatistics() async {
    final user = _client.auth.currentUser;
    if (user == null) return {};

    // Get all sessions for this user
    final sessionsResponse = await _client
        .from('sessions')
        .select('id')
        .eq('profile_id', user.id)
        .eq('session_type', 'game');

    if (sessionsResponse.isEmpty) {
      return {
        'totalGames': 0,
        'averageScore': 0.0,
        'sparePercentages': {
          '7-pin': 0.0,
          '10-pin': 0.0,
          '3-6-10': 0.0,
          'cleanFrames': 0.0,
        },
      };
    }

    final sessionIds = sessionsResponse.map((s) => s['id'] as String).toList();

    // Calculate total games and total score from all games across all sessions
    final gamesResponse = await _client
        .from('games')
        .select('total_score')
        .inFilter('session_id', sessionIds);

    final totalGames = gamesResponse.length;
    final totalScoreSum = gamesResponse.fold<int>(0, (sum, game) => sum + (game['total_score'] as int? ?? 0));
    final averageScore = totalGames > 0 ? totalScoreSum / totalGames : 0.0;

    // Get spare statistics from spare_practice table
    final spareStats = await _getSpareStatistics(user.id);

    return {
      'totalGames': totalGames,
      'averageScore': averageScore,
      'sparePercentages': spareStats,
    };
  }

  // Get spare statistics for the user
  Future<Map<String, String>> _getSpareStatistics(String userId) async {
    try {
      // Get all drill sessions for this user
      final drillSessions = await _client
          .from('sessions')
          .select('id')
          .eq('profile_id', userId)
          .eq('session_type', 'drill');

      if (drillSessions.isEmpty) {
        return {
          '7-pin': '0.0',
          '10-pin': '0.0',
          '3-6-10': '0.0',
          'cleanFrames': '0.0',
        };
      }

      final sessionIds = drillSessions.map((s) => s['id'] as String).toList();

      // Get all spare practice data for these sessions
      final spareData = await _client
          .from('spare_practice')
          .select('target_spare, makes, misses')
          .inFilter('session_id', sessionIds);

      // Aggregate statistics by spare type
      final Map<String, Map<String, int>> statsByType = {};

      for (final row in spareData) {
        final targetSpare = row['target_spare'] as String;
        final makes = row['makes'] as int? ?? 0;
        final misses = row['misses'] as int? ?? 0;

        if (!statsByType.containsKey(targetSpare)) {
          statsByType[targetSpare] = {'makes': 0, 'misses': 0};
        }

        statsByType[targetSpare]!['makes'] = statsByType[targetSpare]!['makes']! + makes;
        statsByType[targetSpare]!['misses'] = statsByType[targetSpare]!['misses']! + misses;
      }

      // Calculate percentages for each spare type
      final Map<String, String> percentages = {};

      // Map the database names to display names
      final nameMapping = {
        '7 Pin\'s': '7-pin',
        '10 Pin\'s': '10-pin',
        '3-6-10\'s': '3-6-10',
        'Clean Frames': 'cleanFrames',
      };

      for (final entry in statsByType.entries) {
        final displayName = nameMapping[entry.key] ?? entry.key.toLowerCase();
        final makes = entry.value['makes'] ?? 0;
        final misses = entry.value['misses'] ?? 0;
        final total = makes + misses;
        final percentage = total > 0 ? (makes / total) * 100 : 0.0;
        percentages[displayName] = percentage.toStringAsFixed(1);
      }

      // Ensure all spare types have entries (default to 0.0 if not present)
      final allSpareTypes = ['7-pin', '10-pin', '3-6-10', 'cleanFrames'];
      for (final type in allSpareTypes) {
        percentages.putIfAbsent(type, () => '0.0');
      }

      return percentages;
    } catch (e) {
      // Return default values if there's an error
      return {
        '7-pin': '0.0',
        '10-pin': '0.0',
        '3-6-10': '0.0',
        'cleanFrames': '0.0',
      };
    }
  }

  // Get all games for current user (for compatibility)
  Future<List<Game>> getUserGames() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    // Get user's sessions first
    final sessions = await _client
        .from('sessions')
        .select('id')
        .eq('profile_id', user.id)
        .eq('session_type', 'game');

    if (sessions.isEmpty) return [];

    final sessionIds = sessions.map((s) => s['id'] as String).toList();

    final response = await _client
        .from('games')
        .select()
        .inFilter('session_id', sessionIds)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Game.fromJson(json)).toList();
  }

      // Get leaderboard data for all users sorted by average score
  Future<List<Map<String, dynamic>>> getLeaderboardByAverageScore() async {
    try {
      // This single query gets profiles and their related games in one go
      final response = await _client
          .from('profiles')
          .select('''
            full_name,
            team,
            sessions!inner (
              id,
              games (
                total_score
              )
            )
          ''')
          .eq('sessions.session_type', 'game');

      final leaderboardData = (response as List).map((profile) {
        final allGames = (profile['sessions'] as List)
            .expand((session) => session['games'] as List)
            .toList();

        double averageScore = 0.0;
        if (allGames.isNotEmpty) {
          final totalScore = allGames.fold<int>(0, (sum, g) => sum + (g['total_score'] as int? ?? 0));
          averageScore = totalScore / allGames.length;
        }

        return {
          'name': profile['full_name'] ?? 'Unknown',
          'team': profile['team'] ?? 'Quincy University',
          'averageScore': averageScore,
          'totalGames': allGames.length,
        };
      }).toList();

      // Sort descending
      leaderboardData.sort((a, b) => (b['averageScore'] as double).compareTo(a['averageScore'] as double));
      return leaderboardData;
    } catch (e) {
      debugPrint('Error: $e');
      return [];
    }
  }

  // Get leaderboard data for all users sorted by spare percentage
  Future<List<Map<String, dynamic>>> getLeaderboardBySparePercentage(String spareType) async {
    try {
      final profiles = await _client.from('profiles').select('id, full_name, team');
      final sessions = await _client.from('sessions').select('id, profile_id').eq('session_type', 'drill');
      
      // Map UI names to your database text values
      // Inside getLeaderboardBySparePercentage in game_service.dart
      final typeMapping = {
        '7 Pins': "7 Pin's",     // Matches the apostrophe used in _getSpareStatistics
        '10 Pins': "10 Pin's",
        "3-6-10's": "3-6-10's",
        'Clean Frames': 'Clean Frames',
      };
      final dbType = typeMapping[spareType] ?? spareType;

      final spareData = await _client
          .from('spare_practice')
          .select('makes, misses, session_id')
          .eq('target_spare', dbType);

      final leaderboardData = <Map<String, dynamic>>[];

      for (final profile in profiles) {
        final userId = profile['id'];
        
        final userSessionIds = sessions
            .where((s) => s['profile_id'] == userId)
            .map((s) => s['id'])
            .toList();

        final userSpares = spareData.where((d) => userSessionIds.contains(d['session_id']));

        int totalMakes = 0;
        int totalMisses = 0;
        for (var row in userSpares) {
          totalMakes += (row['makes'] as int? ?? 0);
          totalMisses += (row['misses'] as int? ?? 0);
        }

        int totalAttempts = totalMakes + totalMisses;
        double percentage = totalAttempts > 0 ? (totalMakes / totalAttempts) * 100 : 0.0;

        leaderboardData.add({
          'name': profile['full_name'] ?? 'Unknown',
          'team': profile['team'] ?? 'Quincy University',
          'percentage': percentage,
          'makes': totalMakes,
          'total': totalAttempts,
        });
      }

      leaderboardData.sort((a, b) => (b['percentage'] as double).compareTo(a['percentage'] as double));

      return leaderboardData;
    } catch (e) {
      debugPrint('Error fetching spare leaderboard: $e');
      return [];
    }
  }
}