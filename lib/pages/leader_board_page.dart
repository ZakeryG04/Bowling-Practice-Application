import 'package:flutter/material.dart';
import '../services/game_service.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  // State for toggles
  bool isAverageView = true;
  String selectedSpareType = '7 Pins';
  final GameService _gameService = GameService();
  
  // Cached data
  late Future<List<Map<String, dynamic>>> _leaderboardFuture;

  // Theme Colors
  final Color primaryBrown = const Color.fromARGB(255, 109, 51, 40);

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  void _loadLeaderboard() {
    _leaderboardFuture = isAverageView
        ? _gameService.getLeaderboardByAverageScore()
        : _gameService.getLeaderboardBySparePercentage(selectedSpareType);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        
        // 1. Primary Toggle (Average vs Spares)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<bool>(
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: primaryBrown,
              selectedForegroundColor: Colors.white,
            ),
            segments: const [
              ButtonSegment(
                value: true, 
                label: Text('Season Avg'), 
                icon: Icon(Icons.analytics_outlined)
              ),
              ButtonSegment(
                value: false, 
                label: Text('Spare %'), 
                icon: Icon(Icons.track_changes)
              ),
            ],
            selected: {isAverageView},
            onSelectionChanged: (Set<bool> newSelection) {
              setState(() {
                isAverageView = newSelection.first;
                _loadLeaderboard();
              });
            },
          ),
        ),

        // 2. Secondary Toggle (Only shown if Spares is selected)
        AnimatedCrossFade(
          firstChild: const SizedBox(height: 0),
          secondChild: _buildSpareFilter(),
          crossFadeState: isAverageView ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 250),
        ),

        const SizedBox(height: 24),

        // 3. The Leaderboard (Podium + List)
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _leaderboardFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('No leaderboard data available'),
                );
              }

              final leaderboardData = snapshot.data!;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Podium
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _buildPodium(leaderboardData),
                    ),

                    const SizedBox(height: 16),
                    
                    // Header for the "rest of the field"
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      width: double.infinity,
                      color: Colors.grey[100],
                      child: Text(
                        "RANKINGS",
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.grey[600],
                          letterSpacing: 1.2
                        ),
                      ),
                    ),

                    // Full List (skip top 3 since they're on podium)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: leaderboardData.length > 3 ? leaderboardData.length - 3 : 0, 
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        // Offset by 3 to skip the podium finishers
                        final userData = leaderboardData[index + 3]; 
                        final displayIndex = index + 4;
                        final metric = isAverageView 
                          ? (userData['averageScore']?.toDouble() ?? 0.0).toStringAsFixed(1)
                          : (userData['percentage']?.toDouble() ?? 0.0).toStringAsFixed(1);

                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.grey[200],
                            child: Text('$displayIndex', 
                              style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(userData['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(userData['team'] ?? 'Quincy University'),
                          trailing: Text(
                            isAverageView ? '$metric' : '$metric%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 15,
                              color: primaryBrown
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSpareFilter() {
    return Column(
      children: [
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ['7 Pins', '10 Pins', '3-6-10\'s', 'Clean Frames'].map((type) {
              final isSelected = selectedSpareType == type;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(type, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
                  selected: isSelected,
                  selectedColor: primaryBrown.withOpacity(0.8),
                  onSelected: (val) {
                    setState(() {
                      selectedSpareType = type;
                      _loadLeaderboard();
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> leaderboardData) {
    // Get top 3 or less if not available
    final top3 = leaderboardData.take(3).toList();

    // Ensure we have at least placeholders for the podium
    while (top3.length < 3) {
      top3.add({'name': 'N/A', 'team': '', 'averageScore': 0.0, 'percentage': 0.0});
    }

    // Reorder for display: 2nd, 1st, 3rd
    final displayOrder = [
      if (top3.length > 1) top3[1],
      top3[0],
      if (top3.length > 2) top3[2],
    ];

    final metrics = displayOrder.map((user) {
      double val = isAverageView 
        ? (user['averageScore']?.toDouble() ?? 0.0) 
        : (user['percentage']?.toDouble() ?? 0.0);
      return val.toStringAsFixed(1);
    }).toList();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd Place
        if (displayOrder.length > 0)
          _podiumSpot(
            rank: 2, 
            height: 110, 
            name: displayOrder[0]['name'] ?? 'N/A', 
            metric: isAverageView ? metrics[0] : '${metrics[0]}%', 
            color: Colors.blueGrey.shade300
          ),
        const SizedBox(width: 4),
        // 1st Place
        if (displayOrder.length > 1)
          _podiumSpot(
            rank: 1, 
            height: 150, 
            name: displayOrder[1]['name'] ?? 'N/A', 
            metric: isAverageView ? metrics[1] : '${metrics[1]}%', 
            color: const Color(0xFFFFD700)
          ),
        const SizedBox(width: 4),
        // 3rd Place
        if (displayOrder.length > 2)
          _podiumSpot(
            rank: 3, 
            height: 90, 
            name: displayOrder[2]['name'] ?? 'N/A', 
            metric: isAverageView ? metrics[2] : '${metrics[2]}%', 
            color: Colors.orange.shade300
          ),
      ],
    );
  }

  Widget _podiumSpot({
    required int rank, 
    required double height, 
    required String name, 
    required String metric,
    required Color color
  }) {
    bool isFirst = rank == 1;
    return Column(
      children: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            CircleAvatar(
              radius: isFirst ? 38 : 32,
              backgroundColor: color,
              child: CircleAvatar(
                radius: isFirst ? 35 : 30,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: isFirst ? 40 : 30, color: color),
              ),
            ),
            if (isFirst)
              const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 28),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 95,
          child: Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        Text(metric, style: TextStyle(color: primaryBrown, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          width: 95,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withOpacity(0.7)],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, -2))
            ]
          ),
          child: Center(
            child: Text(
              '$rank',
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}