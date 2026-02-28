import 'dart:math';
import 'package:flutter/material.dart';
import '../data/vocabulary.dart';
import '../widgets/flip_card.dart';

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
  static const int _cardsPerRound = 10;

  @override
  void initState() {
    super.initState();
    _loadRound();
  }

  void _loadRound() {
    final shuffled = List<VocabWord>.from(widget.theme.words)..shuffle(Random());
    _words = shuffled.take(_cardsPerRound).toList();
    _currentIndex = 0;
    _isFlipped = false;
  }

  void _flipCard() {
    if (!_isFlipped) {
      setState(() => _isFlipped = true);
    }
  }

  void _nextCard() {
    setState(() {
      if (_currentIndex < _words.length - 1) {
        _currentIndex++;
        _isFlipped = false;
      }
    });
  }

  void _newRound() {
    setState(() {
      _loadRound();
    });
  }

  bool get _isLastCard => _currentIndex >= _words.length - 1;
  bool get _roundComplete => _isLastCard && _isFlipped;

  @override
  Widget build(BuildContext context) {
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    value: (_currentIndex + (_isFlipped ? 1 : 0)) / _words.length,
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
                  _roundComplete
                      ? 'Bravo! Round completato!'
                      : _isFlipped
                          ? 'Premi la freccia per continuare'
                          : 'Come si dice in inglese? Tocca per scoprire',
                  style: TextStyle(
                    color: _roundComplete ? themeColor : const Color(0xFF636E72),
                    fontSize: 14,
                    fontWeight: _roundComplete ? FontWeight.w600 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Card - centered
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360, maxHeight: 480),
                      child: FlipCardWidget(
                        key: ValueKey('card-$_currentIndex'),
                        word: word,
                        themeColor: themeColor,
                        isFlipped: _isFlipped,
                        onTap: _flipCard,
                        onNext: _isLastCard ? null : _nextCard,
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom buttons when round complete
              if (_roundComplete)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.home_rounded),
                          label: const Text('Home'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _newRound,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Nuovo Round'),
                          style: FilledButton.styleFrom(
                            backgroundColor: themeColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
