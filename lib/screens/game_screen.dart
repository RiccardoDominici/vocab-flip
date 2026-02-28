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
  late List<VocabWord> _currentWords;
  int _flippedCount = 0;
  static const int _cardsPerRound = 10;

  @override
  void initState() {
    super.initState();
    _loadRound();
  }

  void _loadRound() {
    final shuffled = List<VocabWord>.from(widget.theme.words)..shuffle(Random());
    _currentWords = shuffled.take(_cardsPerRound).toList();
    _flippedCount = 0;
  }

  void _onCardFlipped() {
    setState(() {
      _flippedCount++;
    });
  }

  void _newRound() {
    setState(() {
      _loadRound();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Color(widget.theme.colorValue);
    final allFlipped = _flippedCount >= _currentWords.length;

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
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_flippedCount / ${_currentWords.length}',
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
                    value: _currentWords.isEmpty
                        ? 0
                        : _flippedCount / _currentWords.length,
                    minHeight: 6,
                    backgroundColor: themeColor.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Hint text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  allFlipped
                      ? 'Bravo! Hai completato il round! 🎉'
                      : 'Pensa alla traduzione inglese, poi tocca la card',
                  style: TextStyle(
                    color: allFlipped ? themeColor : const Color(0xFF636E72),
                    fontSize: 14,
                    fontWeight: allFlipped ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Cards grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _currentWords.length,
                    itemBuilder: (context, index) {
                      return FlipCardWidget(
                        key: ValueKey('${_currentWords[index].english}-$_flippedCount-round'),
                        word: _currentWords[index],
                        themeColor: themeColor,
                        onFlipped: _onCardFlipped,
                      );
                    },
                  ),
                ),
              ),
              // Bottom buttons
              if (allFlipped)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
