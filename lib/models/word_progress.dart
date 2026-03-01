enum EvalResult { known, uncertain, unknown }

class WordProgress {
  final String wordId;
  int confidenceLevel; // 0-4
  int timesSeen;
  String lastSeen; // ISO date
  EvalResult lastResult;
  int nextReviewRound;

  WordProgress({
    required this.wordId,
    this.confidenceLevel = 0,
    this.timesSeen = 0,
    String? lastSeen,
    this.lastResult = EvalResult.unknown,
    this.nextReviewRound = 0,
  }) : lastSeen = lastSeen ?? DateTime.now().toIso8601String().split('T')[0];

  bool get isMastered => confidenceLevel >= 4;

  void recordResult(EvalResult result, int currentRound) {
    timesSeen++;
    lastSeen = DateTime.now().toIso8601String().split('T')[0];
    lastResult = result;

    switch (result) {
      case EvalResult.known:
        confidenceLevel = (confidenceLevel + 1).clamp(0, 4);
        // Known words come back every 3-5 rounds for reinforcement
        nextReviewRound = currentRound + 2 + confidenceLevel;
      case EvalResult.uncertain:
        confidenceLevel = 1;
        // Uncertain words come back next round
        nextReviewRound = currentRound + 1;
      case EvalResult.unknown:
        confidenceLevel = 0;
        // Unknown words come back immediately (same round) and next
        nextReviewRound = currentRound;
    }
  }

  Map<String, dynamic> toJson() => {
        'word_id': wordId,
        'confidence_level': confidenceLevel,
        'times_seen': timesSeen,
        'last_seen': lastSeen,
        'last_result': lastResult.name,
        'next_review_round': nextReviewRound,
      };

  factory WordProgress.fromJson(Map<String, dynamic> json) => WordProgress(
        wordId: json['word_id'] as String,
        confidenceLevel: json['confidence_level'] as int? ?? 0,
        timesSeen: json['times_seen'] as int? ?? 0,
        lastSeen: json['last_seen'] as String?,
        lastResult: EvalResult.values.firstWhere(
          (e) => e.name == json['last_result'],
          orElse: () => EvalResult.unknown,
        ),
        nextReviewRound: json['next_review_round'] as int? ?? 0,
      );
}

class ThemeProgress {
  final String themeName;
  final Map<String, WordProgress> words;
  int currentRound;

  ThemeProgress({
    required this.themeName,
    Map<String, WordProgress>? words,
    this.currentRound = 0,
  }) : words = words ?? {};

  int get totalWords => words.length;
  int get knownCount =>
      words.values.where((w) => w.lastResult == EvalResult.known && w.confidenceLevel >= 2).length;
  int get uncertainCount =>
      words.values.where((w) => w.lastResult == EvalResult.uncertain || w.confidenceLevel == 1).length;
  int get unknownCount =>
      words.values.where((w) => w.confidenceLevel == 0 && w.timesSeen > 0).length;
  int get masteredCount => words.values.where((w) => w.isMastered).length;
  int get unseenCount => words.values.where((w) => w.timesSeen == 0).length +
      (_totalThemeWords - words.length);

  int _totalThemeWords = 0;
  void setTotalWords(int total) => _totalThemeWords = total;

  double get completionPercent {
    if (_totalThemeWords == 0) return 0;
    // Weight: mastered=1.0, known(conf>=2)=0.6, uncertain=0.3, unknown=0.1
    double score = 0;
    for (final w in words.values) {
      if (w.isMastered) {
        score += 1.0;
      } else if (w.confidenceLevel >= 2) {
        score += 0.6;
      } else if (w.confidenceLevel == 1) {
        score += 0.3;
      } else if (w.timesSeen > 0) {
        score += 0.1;
      }
    }
    return (score / _totalThemeWords).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
        'theme_name': themeName,
        'current_round': currentRound,
        'words': words.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory ThemeProgress.fromJson(Map<String, dynamic> json) {
    final wordsMap = <String, WordProgress>{};
    if (json['words'] != null) {
      (json['words'] as Map<String, dynamic>).forEach((key, value) {
        wordsMap[key] = WordProgress.fromJson(value as Map<String, dynamic>);
      });
    }
    return ThemeProgress(
      themeName: json['theme_name'] as String,
      words: wordsMap,
      currentRound: json['current_round'] as int? ?? 0,
    );
  }
}

class RoundResult {
  final int knownCount;
  final int uncertainCount;
  final int unknownCount;
  final int totalCards;
  final int round;
  final List<String> newBadges;

  const RoundResult({
    required this.knownCount,
    required this.uncertainCount,
    required this.unknownCount,
    required this.totalCards,
    required this.round,
    this.newBadges = const [],
  });
}
