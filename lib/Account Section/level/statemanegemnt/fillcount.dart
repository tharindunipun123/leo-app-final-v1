class FillCount {
  static final FillCount _instance = FillCount._internal();

  factory FillCount() {
    return _instance;
  }

  FillCount._internal();

  int _fillCount = 0;
  int _fetchedMinutes = 0;
  int _want = 0;

  int get fillCount => _fillCount;
  int get fetchedMinutes => _fetchedMinutes;
  int get want => _want;

  void updateFillCount(int count) {
    _fillCount = count;
  }

  void updateFetchedMinutes(int minutes) {
    _fetchedMinutes = minutes;
  }

  void updateWantCount(int want) {
    _want = want;
  }
}

// Create a global instance
final fillCount = FillCount();
