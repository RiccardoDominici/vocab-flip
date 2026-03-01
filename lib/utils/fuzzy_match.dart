import 'dart:math';

/// Result of comparing user input against the correct answer.
enum MatchGrade {
  /// Exact match (or trivially close, e.g. casing).
  correct,

  /// Close match — 1-2 small errors (typo, missing/extra letter, swap).
  close,

  /// Too many errors — considered wrong.
  wrong,
}

/// A single character-level diff operation for visual highlighting.
enum DiffOp { match, substitute, insert, delete }

class DiffChar {
  final String char;
  final DiffOp op;
  const DiffChar(this.char, this.op);
}

class MatchResult {
  final MatchGrade grade;
  final int distance;
  final List<DiffChar> diff;
  final String correct;
  final String input;

  const MatchResult({
    required this.grade,
    required this.distance,
    required this.diff,
    required this.correct,
    required this.input,
  });
}

class FuzzyMatch {
  /// Compare [input] against [correct] and return a detailed result.
  static MatchResult evaluate(String input, String correct) {
    final normInput = _normalize(input);
    final normCorrect = _normalize(correct);

    if (normInput == normCorrect) {
      return MatchResult(
        grade: MatchGrade.correct,
        distance: 0,
        diff: normCorrect.split('').map((c) => DiffChar(c, DiffOp.match)).toList(),
        correct: correct,
        input: input,
      );
    }

    final dist = _levenshtein(normInput, normCorrect);
    final maxLen = max(normInput.length, normCorrect.length);

    // Determine grade based on absolute distance and relative length.
    // For short words (<=4 chars): only 1 error tolerated as "close".
    // For longer words: up to 2 errors tolerated as "close".
    final threshold = maxLen <= 4 ? 1 : 2;

    MatchGrade grade;
    if (dist <= threshold) {
      grade = MatchGrade.close;
    } else {
      grade = MatchGrade.wrong;
    }

    final diff = _buildDiff(normInput, normCorrect);

    return MatchResult(
      grade: grade,
      distance: dist,
      diff: diff,
      correct: correct,
      input: input,
    );
  }

  /// Map a MatchGrade to the existing EvalResult values.
  /// correct -> known, close -> uncertain, wrong -> unknown
  static String gradeToEmoji(MatchGrade grade) {
    switch (grade) {
      case MatchGrade.correct:
        return '✓';
      case MatchGrade.close:
        return '~';
      case MatchGrade.wrong:
        return '✗';
    }
  }

  static String _normalize(String s) {
    return s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Standard Levenshtein distance.
  static int _levenshtein(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final m = a.length;
    final n = b.length;
    var prev = List<int>.generate(n + 1, (i) => i);
    var curr = List<int>.filled(n + 1, 0);

    for (var i = 1; i <= m; i++) {
      curr[0] = i;
      for (var j = 1; j <= n; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = min(min(curr[j - 1] + 1, prev[j] + 1), prev[j - 1] + cost);
      }
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }
    return prev[n];
  }

  /// Build a character-level diff using the Levenshtein matrix backtrace.
  /// The diff is relative to [correct] — showing what the user got right/wrong.
  static List<DiffChar> _buildDiff(String input, String correct) {
    final m = input.length;
    final n = correct.length;

    // Build full matrix for backtrace.
    final dp = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));
    for (var i = 0; i <= m; i++) {
      dp[i][0] = i;
    }
    for (var j = 0; j <= n; j++) {
      dp[0][j] = j;
    }

    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        final cost = input[i - 1] == correct[j - 1] ? 0 : 1;
        dp[i][j] = min(min(dp[i - 1][j] + 1, dp[i][j - 1] + 1), dp[i - 1][j - 1] + cost);
      }
    }

    // Backtrace to build diff aligned to the CORRECT word.
    final result = <DiffChar>[];
    var i = m;
    var j = n;

    while (i > 0 || j > 0) {
      if (i > 0 && j > 0 && input[i - 1] == correct[j - 1]) {
        result.add(DiffChar(correct[j - 1], DiffOp.match));
        i--;
        j--;
      } else if (i > 0 && j > 0 && dp[i][j] == dp[i - 1][j - 1] + 1) {
        // Substitution: user typed wrong char for this position in correct.
        result.add(DiffChar(correct[j - 1], DiffOp.substitute));
        i--;
        j--;
      } else if (i > 0 && dp[i][j] == dp[i - 1][j] + 1) {
        // Deletion: user typed an extra char (not in correct).
        result.add(DiffChar(input[i - 1], DiffOp.delete));
        i--;
      } else {
        // Insertion: user missed this char from correct.
        result.add(DiffChar(correct[j - 1], DiffOp.insert));
        j--;
      }
    }

    return result.reversed.toList();
  }
}
