import 'package:flutter/material.dart';
import 'package:qu_bowling/models/profile.dart';
import 'package:qu_bowling/services/profile_service.dart';
import 'package:qu_bowling/services/game_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Future<Profile?> _profileFuture;
  late final Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    // Fetching the profile and statistics once on init to prevent re-runs on rebuilds
    _profileFuture = ProfileService().getCurrentUserProfile();
    _statsFuture = GameService().getUserStatistics();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Profile?>(
      future: _profileFuture,
      builder: (context, profileSnapshot) {
        return FutureBuilder<Map<String, dynamic>>(
          future: _statsFuture,
          builder: (context, statsSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting ||
                statsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final profile = profileSnapshot.data;
            final stats = statsSnapshot.data ?? {};

            // Logic for display name and initials
            final displayName = profile?.fullName?.trim().isNotEmpty == true
                ? profile!.fullName!
                : 'Player';

            final initials = displayName
                .split(' ')
                .where((part) => part.isNotEmpty)
                .map((part) => part[0].toUpperCase())
                .take(2)
                .join();

            // Get dynamic statistics from database
            final sevenPin = '${stats['sparePercentages']?['7-pin'] ?? '0.0'}%';
            final tenPin = '${stats['sparePercentages']?['10-pin'] ?? '0.0'}%';
            final spare310 = '${stats['sparePercentages']?['3-6-10'] ?? '0.0'}%';
            final cleanFrames = '${stats['sparePercentages']?['cleanFrames'] ?? '0.0'}%';
            final average = (stats['averageScore'] ?? 0.0).toStringAsFixed(1);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Hello, $displayName',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 42,
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                child: Text(
                                  initials.isEmpty ? 'Q' : initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile?.fullName ?? 'Quincy University Athlete',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      profile?.role ?? 'Athlete',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: Colors.grey[700],
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      profile?.team != null ? 'Team: ${profile!.team}' : 'Team not set',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Spare Percentages',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildStatRow('7-pin spare', sevenPin),
                                    const SizedBox(height: 12),
                                    _buildStatRow('10-pin spare', tenPin),
                                    const SizedBox(height: 12),
                                    _buildStatRow('3-6-10 spare', spare310),
                                    const SizedBox(height: 12),
                                    _buildStatRow('Clean frames', cleanFrames),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 200, 160, 150),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Average',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        average,
                                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'average from ${stats['totalGames'] ?? 0} games',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}