import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qu_bowling/services/game_service.dart';



class FullScoreTrackerPage extends StatefulWidget {
  const FullScoreTrackerPage({super.key});

  @override
  State<FullScoreTrackerPage> createState() => _FullScoreTrackerPageState();
}

class _FullScoreTrackerPageState extends State<FullScoreTrackerPage> {
  static const allPins = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

  final List<List<int?>> _frameRolls = List.generate(10, (_) => [null, null, null]);
  int _currentFrame = 0;
  int _currentShot = 1;
  final Set<int> _currentSelection = {};
  Set<int> _firstShotPins = {};
  Set<int> _secondShotPins = {};
  Set<int> _thirdShotPins = {};
  bool _gameComplete = false;
  int _finalScore = 0;

  List<int> get _availablePins {
    if (_currentFrame < 9) {
      if (_currentShot == 1) return allPins;
      return allPins.where((pin) => !_firstShotPins.contains(pin)).toList();
    }

    if (_currentShot == 1) return allPins;
    if (_currentShot == 2) {
      if (_frameRolls[9][0] == 10) return allPins;
      return allPins.where((pin) => !_firstShotPins.contains(pin)).toList();
    }
    if (_currentShot == 3) {
      if (_frameRolls[9][0] == 10) {
        if (_frameRolls[9][1] == 10) return allPins;
        return allPins.where((pin) => !_secondShotPins.contains(pin)).toList();
      }
      if ((_frameRolls[9][0] ?? 0) + (_frameRolls[9][1] ?? 0) == 10) return allPins;
    }
    return [];
  }

  int get _selectedCount => _currentSelection.length;

  String get _scoreLabel => 'Frame ${_currentFrame + 1} • Shot $_currentShot';

  bool get _showPrimaryAction => !_gameComplete && (_currentShot == 1 || _currentShot == 2 || (_currentFrame == 9 && _currentShot == 3));

  String get _primaryActionLabel {
    if (_currentShot == 1) return 'Strike';
    if (_currentFrame == 9 && _frameRolls[9][0] == 10) return 'Strike';
    if (_currentShot == 3) return 'Strike';
    return 'Spare';
  }

  void _togglePin(int pin) {
    if (!_availablePins.contains(pin) || _gameComplete) return;
    if (_currentFrame < 9 && _currentShot == 2 && _firstShotPins.contains(pin)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot unmark pins from first shot')),
      );
      return;
    }
    setState(() {
      if (_currentSelection.contains(pin)) {
        _currentSelection.remove(pin);
      } else {
        _currentSelection.add(pin);
      }
    });
  }

  void _primaryAction() {
    if (!_showPrimaryAction) return;
    _commitShot(markAll: true);
  }

  void _markGutter() {
    if (_gameComplete) return;
    _commitShot(gutter: true);
  }

  void _nextShot() {
    if (_selectedCount == 0 || _gameComplete) return;
    _commitShot();
  }

  void _commitShot({bool gutter = false, bool markAll = false}) {
    final knocked = gutter
        ? 0
        : markAll
            ? _availablePins.length
            : _selectedCount;

    setState(() {
      _frameRolls[_currentFrame][_currentShot - 1] = knocked;
      if (_currentShot == 1) {
        _firstShotPins = markAll ? Set.from(_availablePins) : Set.from(_currentSelection);
      }
      if (_currentFrame == 9 && _currentShot == 2) {
        _secondShotPins = markAll ? Set.from(_availablePins) : Set.from(_currentSelection);
      }
      if (_currentFrame == 9 && _currentShot == 3) {
        _thirdShotPins = markAll ? Set.from(_availablePins) : Set.from(_currentSelection);
      }
      _advanceTurn(knocked);
      _currentSelection.clear();
    });
  }

  void _advanceTurn(int knocked) {
    if (_currentFrame < 9) {
      if (_currentShot == 1) {
        if (knocked == 10) {
          _advanceFrame();
          return;
        }
        _currentShot = 2;
        return;
      }
      _advanceFrame();
      return;
    }

    if (_currentShot == 1) {
      _currentShot = 2;
      return;
    }

    if (_currentShot == 2) {
      final first = _frameRolls[9][0] ?? 0;
      final second = _frameRolls[9][1] ?? 0;
      if (first == 10 || first + second == 10) {
        _currentShot = 3;
        return;
      }
      _completeGame();
      return;
    }

    if (_currentShot == 3) {
      _completeGame();
    }
  }

  void _advanceFrame() {
    _currentFrame += 1;
    _currentShot = 1;
    _firstShotPins.clear();
    _secondShotPins.clear();
    if (_currentFrame >= 10) {
      _completeGame();
    }
  }

  void _completeGame() {
    _gameComplete = true;
    _finalScore = _calculateTotalScore();

    // Save game to database
    _saveGameToDatabase();
  }

  void _saveGameToDatabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Save game with frames using the new method
      await GameService().saveGameWithFrames(
        totalScore: _finalScore,
        frameRolls: _frameRolls,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Game saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save game: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int _getStandingPins() {
    if (_currentShot == 2 && _currentFrame < 9) {
      return allPins.length - _firstShotPins.length;
    }
    if (_currentFrame == 9 && _currentShot == 3 && _frameRolls[9][0] == 10 && _frameRolls[9][1] != 10) {
      return allPins.length - _secondShotPins.length;
    }
    return _availablePins.length;
  }

  void _resetCurrentFrame() {
    setState(() {
      _frameRolls[_currentFrame] = [null, null, null];
      _currentShot = 1;
      _currentSelection.clear();
      _firstShotPins.clear();
      _secondShotPins.clear();
      _thirdShotPins.clear();
      _gameComplete = false;
      _finalScore = 0;
    });
  }

  void _resetGame() async {
    // Game stats are now handled by the GameService.saveGameWithFrames method
    // which updates the stats_cache table automatically

    setState(() {
      for (var i = 0; i < 10; i++) {
        _frameRolls[i] = [null, null, null];
      }
      _currentFrame = 0;
      _currentShot = 1;
      _currentSelection.clear();
      _firstShotPins.clear();
      _secondShotPins.clear();
      _thirdShotPins.clear();
      _gameComplete = false;
      _finalScore = 0;
    });
  }

  bool _canGoNext() {
    return _currentSelection.isNotEmpty;
  }

  List<int?> _runningFrameScores() {
    final running = List<int?>.filled(10, null);
    int total = 0;
    for (var i = 0; i < 10; i++) {
      final score = _frameScore(i);
      if (score == null) break;
      total += score;
      running[i] = total;
    }
    return running;
  }

  int? _frameScore(int index) {
    final first = _frameRolls[index][0];
    final second = _frameRolls[index][1];
    final third = _frameRolls[index][2];

    if (index < 9) {
      if (first == null) return null;
      if (first == 10) {
        final extra = _nextRolls(index, 2);
        if (extra.length < 2) return null;
        return 10 + extra[0] + extra[1];
      }
      if (second == null) return null;
      if (first + second == 10) {
        final extra = _nextRolls(index, 1);
        if (extra.isEmpty) return null;
        return 10 + extra[0];
      }
      return first + second;
    }

    if (first == null || second == null) return null;
    if (first == 10) {
      if (third == null) return null;
      return 10 + second + third;
    }
    if (first + second == 10) {
      if (third == null) return null;
      return 10 + third;
    }
    return first + second;
  }

  List<int> _nextRolls(int index, int count) {
    final values = <int>[];
    for (var i = index + 1; i < 10 && values.length < count; i++) {
      final f = _frameRolls[i][0];
      final s = _frameRolls[i][1];
      final t = _frameRolls[i][2];
      if (f != null) values.add(f);
      if (i < 9 && f == 10) continue;
      if (s != null) values.add(s);
      if (i == 9 && t != null) values.add(t);
    }
    return values.take(count).toList();
  }

  int _calculateTotalScore() {
    return _runningFrameScores().lastWhere((score) => score != null, orElse: () => 0) ?? 0;
  }

  Widget _buildFrameCell(int index) {
    final isTenth = index == 9;
    final runningScore = _runningFrameScores()[index];
    final first = _frameRolls[index][0];
    final second = _frameRolls[index][1];
    final third = _frameRolls[index][2];

    String firstText = first == null ? '' : (first == 10 ? 'X' : (first == 0 ? '-' : first.toString()));
    String secondText = '';
    String thirdText = '';

    if (!isTenth) {
      if (second != null) {
        secondText = first != null && first != 10 && first + second == 10 ? '/' : (second == 0 ? '-' : second.toString());
      }
    } else {
      if (second != null) {
        secondText = first != null && first != 10 && first + second == 10 ? '/' : (second == 10 ? 'X' : (second == 0 ? '-' : second.toString()));
      }
      if (third != null) {
        thirdText = third == 10 ? 'X' : (third == 0 ? '-' : third.toString());
      }
    }

    return Container(
      width: isTenth ? 120 : 110,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.brown.shade800, width: 2),
        borderRadius: BorderRadius.circular(10),
        color: Colors.brown.shade50,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              '${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (!isTenth)
            Stack(
              children: [
                Container(
                  height: 64,
                  width: double.infinity,
                  color: Colors.white,
                  child: Center(
                    child: Text(
                      firstText,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    height: 22,
                    width: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.brown.shade800, width: 1.5),
                      color: Colors.brown.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      secondText,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              height: 64,
              width: double.infinity,
              color: Colors.white,
              child: Row(
                children: [
                  _buildSplitBox(firstText),
                  _buildSplitBox(secondText),
                  _buildSplitBox(thirdText),
                ],
              ),
            ),
          Container(
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.brown.shade100,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Text(
              runningScore != null ? runningScore.toString() : '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitBox(String value) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.brown.shade400, width: 1)),
        ),
        child: Center(
          child: Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildPinButton(int pin) {
    final isSelected = _currentSelection.contains(pin);
    final isDisabled = !_availablePins.contains(pin);
    final alreadyHit = _firstShotPins.contains(pin) || _secondShotPins.contains(pin) || _thirdShotPins.contains(pin);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: ElevatedButton(
          onPressed: isDisabled ? null : () => _togglePin(pin),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected
                ? Colors.brown.shade700
                : alreadyHit
                    ? Colors.brown.shade200
                    : Colors.brown.shade300,
            foregroundColor: isSelected || alreadyHit ? Colors.white : Colors.black,
            shape: const CircleBorder(),
          ),
          child: Text(pin.toString()),
        ),
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onPressed, {bool visible = true}) {
    if (!visible) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Full Score Tracker',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            _scoreLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.brown.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.brown.shade200, width: 2),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [_buildPinButton(7), _buildPinButton(8), _buildPinButton(9), _buildPinButton(10)],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [_buildPinButton(4), _buildPinButton(5), _buildPinButton(6)],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [_buildPinButton(2), _buildPinButton(3)],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [const SizedBox(width: 46), _buildPinButton(1), const SizedBox(width: 46)],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          IntrinsicHeight(
          child: Container(
            padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.brown.shade200, width: 2),
              ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch, 
              children: [
        if (_showPrimaryAction)
          Expanded(
            child: _actionButton(_primaryActionLabel, Colors.brown.shade700, _primaryAction),
          ),
        if (_showPrimaryAction) const SizedBox(width: 8), // Spacing between buttons
        
        Expanded(
          child: _actionButton('Gutter/Foul', Colors.grey.shade800, _markGutter),
        ),
        const SizedBox(width: 8),
        
        if (_canGoNext())
          Expanded(
            child: _actionButton('Next Throw', Colors.teal.shade700, _nextShot),
          ),
        if (_canGoNext()) const SizedBox(width: 8),
        
        Expanded(
          child: _actionButton('Clear Frame', Colors.red.shade700, _resetCurrentFrame),
        ),
      ],
    ),
  ),
),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(10, (index) => _buildFrameCell(index)),
            ),
          ),
          const SizedBox(height: 20),
          if (_gameComplete) ...[
            const SizedBox(height: 20),
            Card(
              color: Colors.brown.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Game Complete', style: Theme.of(context).textTheme.titleMedium),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Final Score', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('$_finalScore', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.brown.shade900)),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _resetGame,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.brown.shade800, foregroundColor: Colors.white),
                          child: const Text('Next Game'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}