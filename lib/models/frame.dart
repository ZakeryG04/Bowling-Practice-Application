// ====================== MODEL ======================

class Frame {
  List<int> shots = []; // 10 = strike, -1 = spare, 0 = gutter, else pins
  List<int>? firstShotPins;
  int runningTotal = 0;

  void addShot(int pins, {List<int>? firstShotPins}) {
    shots.add(pins);
    if (firstShotPins != null) this.firstShotPins = firstShotPins;
  }

  void removeLastShot() {
    if (shots.isNotEmpty) shots.removeLast();
  }

  bool get isComplete {
    if (shots.isEmpty) return false;
    if (shots[0] == 10) return shots.length >= (shots.length > 1 && shots[1] == 10 ? 3 : 2); // 10th frame
    return shots.length >= 2 || (shots.length == 1 && shots[0] == 10);
  }

  int calculateFrameScore(List<Frame> allFrames, int index) {
    if (shots.isEmpty) return 0;

    final first = shots[0];
    if (first == 10) { // Strike
      return 10 + _nextTwoShots(allFrames, index);
    }

    if (shots.length < 2) return 0;

    final second = shots[1];
    if (second == -1) { // Spare
      return 10 + _nextOneShot(allFrames, index);
    }

    return first + (second == -1 ? 10 - first : second);
  }

  int _nextTwoShots(List<Frame> allFrames, int index) {
    int total = 0;
    int count = 0;
    int i = index + 1;

    while (count < 2 && i < 10) {
      if (allFrames[i].shots.isNotEmpty) {
        for (var shot in allFrames[i].shots) {
          if (shot == -1) continue; // skip spare marker
          total += shot == 10 ? 10 : shot;
          count++;
          if (count >= 2) break;
        }
      }
      i++;
    }
    return total;
  }

  int _nextOneShot(List<Frame> allFrames, int index) {
    int i = index + 1;
    while (i < 10) {
      if (allFrames[i].shots.isNotEmpty) {
        final shot = allFrames[i].shots[0];
        return shot == 10 ? 10 : shot;
      }
      i++;
    }
    return 0;
  }

  void reset() {
    shots.clear();
    firstShotPins = null;
    runningTotal = 0;
  }
} 