import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/vocabulary.dart';
import '../models/word_progress.dart';

class ProgressService {
  static ProgressService? _instance;
  late SharedPreferences _prefs;
  final Map<String, ThemeProgress> _themeProgress = {};

  // Badge tracking
  int _totalMastered = 0;
  int _consecutivePerfectRounds = 0;

  ProgressService._();

  static Future<ProgressService> getInstance() async {
    if (_instance == null) {
      _instance = ProgressService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadAll();
  }

  void _loadAll() {
    for (final theme in allThemes) {
      final key = _themeKey(theme.name);
      final json = _prefs.getString(key);
      if (json != null) {
        _themeProgress[theme.name] =
            ThemeProgress.fromJson(jsonDecode(json) as Map<String, dynamic>);
      } else {
        _themeProgress[theme.name] = ThemeProgress(themeName: theme.name);
      }
      _themeProgress[theme.name]!.setTotalWords(theme.words.length);
    }

    _totalMastered = _prefs.getInt('total_mastered') ?? 0;
    _consecutivePerfectRounds =
        _prefs.getInt('consecutive_perfect_rounds') ?? 0;
  }

  Future<void> _saveTheme(String themeName) async {
    final progress = _themeProgress[themeName];
    if (progress != null) {
      await _prefs.setString(_themeKey(themeName), jsonEncode(progress.toJson()));
    }
  }

  String _themeKey(String themeName) => 'theme_progress_$themeName';

  static String wordId(String themeName, String italian) =>
      '${themeName.toLowerCase()}_${italian.toLowerCase().replaceAll(' ', '_')}';

  ThemeProgress getThemeProgress(String themeName) {
    return _themeProgress[themeName] ?? ThemeProgress(themeName: themeName);
  }

  double getThemeCompletion(String themeName) {
    return _themeProgress[themeName]?.completionPercent ?? 0.0;
  }

  /// Generate a round of cards using spaced repetition priority
  List<VocabWord> generateRound(VocabTheme theme, {int maxCards = 10}) {
    final progress = _themeProgress[theme.name]!;
    final currentRound = progress.currentRound;

    // Categorize words
    final List<VocabWord> redWords = []; // unknown from previous round
    final List<VocabWord> yellowWords = []; // uncertain awaiting review
    final List<VocabWord> newWords = []; // never seen
    final List<VocabWord> greenReinforcement = []; // known, due for review

    for (final word in theme.words) {
      final wId = wordId(theme.name, word.italian);
      final wp = progress.words[wId];

      if (wp == null) {
        newWords.add(word);
      } else if (wp.isMastered && wp.nextReviewRound > currentRound) {
        continue; // mastered and not due yet
      } else if (wp.confidenceLevel == 0 && wp.timesSeen > 0) {
        redWords.add(word);
      } else if (wp.confidenceLevel == 1) {
        yellowWords.add(word);
      } else if (wp.confidenceLevel >= 2 && wp.nextReviewRound <= currentRound) {
        greenReinforcement.add(word);
      } else if (wp.nextReviewRound <= currentRound) {
        yellowWords.add(word);
      }
    }

    // Build round with priority order
    final List<VocabWord> round = [];
    final rng = Random();

    // 1. Red words (immediate repetition)
    redWords.shuffle(rng);
    round.addAll(redWords);

    // 2. Yellow words (awaiting review)
    yellowWords.shuffle(rng);
    round.addAll(yellowWords);

    // 3. New words
    newWords.shuffle(rng);
    round.addAll(newWords);

    // 4. Green reinforcement (max 2-3)
    greenReinforcement.shuffle(rng);

    // Trim to maxCards, keeping green reinforcement at max 3
    if (round.length >= maxCards) {
      round.removeRange(maxCards, round.length);
    } else {
      final greenSlots = min(3, maxCards - round.length);
      round.addAll(greenReinforcement.take(greenSlots));
    }

    // If still not enough cards, add more new/random words
    if (round.length < maxCards) {
      final remaining = theme.words
          .where((w) => !round.contains(w))
          .toList()
        ..shuffle(rng);
      round.addAll(remaining.take(maxCards - round.length));
    }

    // Shuffle final order to avoid predictable patterns
    round.shuffle(rng);

    return round.take(maxCards).toList();
  }

  /// Record evaluation result for a word
  Future<void> recordEvaluation(
    String themeName,
    String italian,
    EvalResult result,
  ) async {
    final progress = _themeProgress[themeName]!;
    final wId = wordId(themeName, italian);

    if (!progress.words.containsKey(wId)) {
      progress.words[wId] = WordProgress(wordId: wId);
    }

    final wasMastered = progress.words[wId]!.isMastered;
    progress.words[wId]!.recordResult(result, progress.currentRound);
    final nowMastered = progress.words[wId]!.isMastered;

    if (!wasMastered && nowMastered) {
      _totalMastered++;
      await _prefs.setInt('total_mastered', _totalMastered);
    }

    await _saveTheme(themeName);
  }

  /// Complete current round and return results with badges
  Future<RoundResult> completeRound(
    String themeName,
    Map<String, EvalResult> results,
  ) async {
    final progress = _themeProgress[themeName]!;

    int known = 0, uncertain = 0, unknown = 0;
    for (final entry in results.entries) {
      switch (entry.value) {
        case EvalResult.known:
          known++;
        case EvalResult.uncertain:
          uncertain++;
        case EvalResult.unknown:
          unknown++;
      }
    }

    // Check for perfect round (no unknowns)
    if (unknown == 0 && results.isNotEmpty) {
      _consecutivePerfectRounds++;
    } else {
      _consecutivePerfectRounds = 0;
    }
    await _prefs.setInt(
        'consecutive_perfect_rounds', _consecutivePerfectRounds);

    // Increment round
    progress.currentRound++;
    await _saveTheme(themeName);

    // Generate badges
    final badges = <String>[];
    if (_totalMastered == 10) badges.add('10 parole padroneggiate!');
    if (_totalMastered == 25) badges.add('25 parole padroneggiate!');
    if (_totalMastered == 50) badges.add('50 parole padroneggiate!');
    if (_totalMastered == 100) badges.add('100 parole padroneggiate!');
    if (_consecutivePerfectRounds == 3) {
      badges.add('3 round di fila senza errori!');
    }
    if (_consecutivePerfectRounds == 5) {
      badges.add('5 round di fila senza errori!');
    }
    if (known == results.length && results.isNotEmpty) {
      badges.add('Round perfetto!');
    }

    return RoundResult(
      knownCount: known,
      uncertainCount: uncertain,
      unknownCount: unknown,
      totalCards: results.length,
      round: progress.currentRound,
      newBadges: badges,
    );
  }

  int get totalMastered => _totalMastered;
  int get consecutivePerfectRounds => _consecutivePerfectRounds;

  /// Reset all progress
  Future<void> resetAllProgress() async {
    _themeProgress.clear();
    _totalMastered = 0;
    _consecutivePerfectRounds = 0;

    final keys = _prefs.getKeys().toList();
    for (final key in keys) {
      if (key.startsWith('theme_progress_') ||
          key == 'total_mastered' ||
          key == 'consecutive_perfect_rounds') {
        await _prefs.remove(key);
      }
    }

    _loadAll();
  }

  /// Reset progress for a single theme
  Future<void> resetThemeProgress(String themeName) async {
    _themeProgress[themeName] = ThemeProgress(themeName: themeName);
    final theme = allThemes.firstWhere((t) => t.name == themeName);
    _themeProgress[themeName]!.setTotalWords(theme.words.length);
    await _prefs.remove(_themeKey(themeName));
  }
}
