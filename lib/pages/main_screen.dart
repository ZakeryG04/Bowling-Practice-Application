import 'package:flutter/material.dart';
import 'package:qu_bowling/services/auth_service.dart';
import '../main.dart';
import 'home_page.dart';
import 'spare_tracker_page.dart';
import 'full_score_tracker_page.dart';
import 'leader_board_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<String> _titles = [
    'Home', 
    'Spare Tracker', 
    'Full Score Tracker', 
    'Leaderboard'
  ];

  final List<Widget> _pages = [
    const HomePage(),
    const SpareTrackerPage(),
    const FullScoreTrackerPage(),
    const LeaderboardPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                // 1. Sign out first
                await AuthService().signOut();

                // 2. FORCE the app to reset to the start
                // This removes the "stuck" MainScreen and reveals the AuthWrapper underneath
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthWrapper()),
                    (route) => false,
                  );
                }
              } catch (e) {
                debugPrint('Logout Error: $e');
              }
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.adjust),
            label: 'Spare',
          ),
          BottomNavigationBarItem(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.close, size: 14),
                SizedBox(width: 2),
                Icon(Icons.close, size: 14),
                SizedBox(width: 2),
                Icon(Icons.close, size: 14),
              ],
            ),
            label: 'Score',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Leaderboard',
          ),
        ],
        selectedItemColor: const Color.fromARGB(255, 80, 35, 25),
        unselectedItemColor: const Color.fromARGB(255, 150, 100, 90),
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}