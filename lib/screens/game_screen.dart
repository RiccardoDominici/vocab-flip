import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../data/vocabulary.dart';
import '../models/word_progress.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../utils/fuzzy_match.dart';
import '../utils/image_helper.dart';
import '../widgets/flip_card.dart';
import 'round_summary_screen.dart';

class GameScreen extends StatefulWidget {
  final VocabTheme theme;

  const GameScreen({super.key, required this.theme});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late List<VocabWord> _words;
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _evaluated = false;
  static const int _cardsPerRound = 10;
  ProgressService? _progressService;
  final Map<String, EvalResult> _roundResults = {};

  /// Stores the current user's typed answer.
  final TextEditingController _answerController = TextEditingController();

  /// The match result for the current card (null until submitted).
  MatchResult? _currentMatch;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _initService() async {
    _progressService = await ProgressService.getInstance();
    setState(() {
      _words = _progressService!.generateRound(widget.theme, maxCards: _cardsPerRound);
    });
    _precacheUpcoming();
  }

  /// Precache images for the next card (and the one after) to avoid lag.
  void _precacheUpcoming() {
    if (!mounted) return;
    for (var i = _currentIndex + 1; i <= _currentIndex + 2 && i < _words.length; i++) {
      ImageHelper.precacheWord(context, _words[i].imageSearchTerm);
    }
  }

  /// Called when user submits their typed answer (or taps "non lo so").
  void _submitAnswer() {
    if (_isFlipped) return;

    final word = _words[_currentIndex];
    final userInput = _answerController.text.trim();

    MatchResult? match;
    if (userInput.isNotEmpty) {
      match = FuzzyMatch.evaluate(userInput, word.english);
    }

    setState(() {
      _isFlipped = true;
      _currentMatch = match;
    });

    // Auto-evaluate for correct and wrong answers.
    // Close matches let the user choose.
    if (match == null) {
      // User skipped — treat as unknown.
      _evaluate(EvalResult.unknown);
    } else if (match.grade == MatchGrade.correct) {
      _evaluate(EvalResult.known);
    } else if (match.grade == MatchGrade.wrong) {
      _evaluate(EvalResult.unknown);
    }
    // MatchGrade.close — user picks via buttons on the back card.
  }

  void _evaluate(EvalResult result) async {
    if (_evaluated) return;
    setState(() => _evaluated = true);

    final word = _words[_currentIndex];
    await _progressService?.recordEvaluation(
      widget.theme.name,
      word.italian,
      result,
    );

    _roundResults[ProgressService.wordId(widget.theme.name, word.italian)] = result;
  }

  void _nextCard() {
    if (_currentIndex < _words.length - 1) {
      _answerController.clear();
      setState(() {
        _currentIndex++;
        _isFlipped = false;
        _evaluated = false;
        _currentMatch = null;
      });
      _precacheUpcoming();
    } else {
      _showRoundSummary();
    }
  }

  void _retryCard() {
    _answerController.clear();
    setState(() {
      _isFlipped = false;
      _currentMatch = null;
    });
  }

  Future<void> _showRoundSummary() async {
    final roundResult = await _progressService?.completeRound(
      widget.theme.name,
      _roundResults,
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            RoundSummaryScreen(
          theme: widget.theme,
          result: roundResult!,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  String get _hintText {
    if (_isFlipped && !_evaluated) {
      if (_currentMatch?.grade == MatchGrade.close) {
        return 'Risposta vicina! Decidi tu come contarla';
      }
      if (_currentMatch?.grade == MatchGrade.correct) {
        return 'Risposta corretta!';
      }
      if (_currentMatch == null || _currentMatch?.grade == MatchGrade.wrong) {
        return 'Prossima parola...';
      }
    }
    if (_evaluated) {
      return 'Vai avanti o riprova';
    }
    return 'Scrivi la traduzione in inglese';
  }

  @override
  Widget build(BuildContext context) {
    if (_progressService == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final themeColor = Color(widget.theme.colorValue);
    final word = _words[_currentIndex];

    return Scaffold(
      // Prevent keyboard from pushing layout up excessively
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Iconsax.arrow_left),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Icon(widget.theme.icon, size: 28.sp, color: themeColor),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: Text(
                        widget.theme.name,
                        style: GoogleFonts.poppins(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: themeColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${_words.length}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: themeColor,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
              // Progress bar
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 4.h),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value:
                        (_currentIndex + (_isFlipped ? 1 : 0)) / _words.length,
                    minHeight: 6,
                    backgroundColor: themeColor.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              // Hint
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text(
                  _hintText,
                  style: GoogleFonts.poppins(
                    color: AppTheme.textSecondary,
                    fontSize: 14.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Card
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 32.w, vertical: 16.h),
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: 360, maxHeight: 480),
                      child: AnswerCapture(
                        controller: _answerController,
                        child: FlipCardWidget(
                          key: ValueKey('card-$_currentIndex'),
                          word: word,
                          themeColor: themeColor,
                          isFlipped: _isFlipped,
                          onTap: _submitAnswer,
                          onEvaluate: _isFlipped && !_evaluated ? _evaluate : null,
                          onNext: _isFlipped && _evaluated ? _nextCard : null,
                          onRetry: _isFlipped && _evaluated ? _retryCard : null,
                          matchResult: _currentMatch,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An InheritedWidget that provides the answer TextEditingController
/// to the front card's text field.
class AnswerCapture extends InheritedWidget {
  final TextEditingController controller;

  const AnswerCapture({
    super.key,
    required this.controller,
    required super.child,
  });

  static TextEditingController of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<AnswerCapture>();
    return widget!.controller;
  }

  @override
  bool updateShouldNotify(AnswerCapture oldWidget) {
    return controller != oldWidget.controller;
  }
}
