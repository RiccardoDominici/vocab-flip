import 'package:flutter/material.dart';
import '../data/vocabulary.dart';
import '../models/word_progress.dart';
import '../services/progress_service.dart';
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

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    _progressService = await ProgressService.getInstance();
    setState(() {
      _words = _progressService!.generateRound(widget.theme, maxCards: _cardsPerRound);
    });
  }

  void _flipCard() {
    if (!_isFlipped) {
      setState(() => _isFlipped = true);
    }
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

    // Auto-advance after a short delay
    await Future.delayed(const Duration(milliseconds: 350));

    if (!mounted) return;

    if (_currentIndex < _words.length - 1) {
      setState(() {
        _currentIndex++;
        _isFlipped = false;
        _evaluated = false;
      });
    } else {
      // Round complete — show summary
      _showRoundSummary();
    }
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2D3436),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.theme.icon,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.theme.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${_words.length}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: themeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Progress bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
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
              const SizedBox(height: 8),
              // Hint
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _isFlipped && !_evaluated
                      ? 'Come ti senti? Valuta la tua risposta'
                      : _evaluated
                          ? 'Prossima parola...'
                          : 'Come si dice in inglese? Tocca per scoprire',
                  style: TextStyle(
                    color: const Color(0xFF636E72),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Card - centered
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: 360, maxHeight: 480),
                      child: FlipCardWidget(
                        key: ValueKey('card-$_currentIndex'),
                        word: word,
                        themeColor: themeColor,
                        isFlipped: _isFlipped,
                        onTap: _flipCard,
                        onEvaluate: _isFlipped && !_evaluated ? _evaluate : null,
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
