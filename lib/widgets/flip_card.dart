import 'dart:math';
import 'package:flutter/material.dart';
import '../data/vocabulary.dart';
import '../models/word_progress.dart';
import '../screens/game_screen.dart' show AnswerCapture;
import '../utils/fuzzy_match.dart';
import '../utils/speech.dart';
import 'word_image.dart';

class FlipCardWidget extends StatefulWidget {
  final VocabWord word;
  final Color themeColor;
  final bool isFlipped;
  final VoidCallback onTap;
  final void Function(EvalResult)? onEvaluate;
  final VoidCallback? onNext;
  final VoidCallback? onRetry;
  final MatchResult? matchResult;

  const FlipCardWidget({
    super.key,
    required this.word,
    required this.themeColor,
    required this.isFlipped,
    required this.onTap,
    this.onEvaluate,
    this.onNext,
    this.onRetry,
    this.matchResult,
  });

  @override
  State<FlipCardWidget> createState() => _FlipCardWidgetState();
}

class _FlipCardWidgetState extends State<FlipCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isFlipped) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(FlipCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped && !oldWidget.isFlipped) {
      _controller.forward();
    } else if (!widget.isFlipped && oldWidget.isFlipped) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final angle = _animation.value * pi;
        final showBack = _animation.value >= 0.5;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: showBack
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(pi),
                  child: _BackCard(
                    word: widget.word,
                    themeColor: widget.themeColor,
                    onEvaluate: widget.onEvaluate,
                    onNext: widget.onNext,
                    onRetry: widget.onRetry,
                    matchResult: widget.matchResult,
                  ),
                )
              : _FrontCard(
                  word: widget.word,
                  themeColor: widget.themeColor,
                  onSubmit: widget.onTap,
                ),
        );
      },
    );
  }
}

/// Full-bleed image card with the Italian word and a text input.
class _FrontCard extends StatefulWidget {
  final VocabWord word;
  final Color themeColor;
  final VoidCallback onSubmit;

  const _FrontCard({
    required this.word,
    required this.themeColor,
    required this.onSubmit,
  });

  @override
  State<_FrontCard> createState() => _FrontCardState();
}

class _FrontCardState extends State<_FrontCard> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final controller = AnswerCapture.of(context);
    if (controller.text.trim().isEmpty) return;
    widget.onSubmit();
  }

  @override
  Widget build(BuildContext context) {
    final textController = AnswerCapture.of(context);
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full-bleed image
            WordImage(
              keyword: widget.word.imageSearchTerm,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.zero,
            ),
            // Gradient scrim at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 220,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),
            // Text overlay with input
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.word.italian,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                      shadows: [
                        Shadow(
                          blurRadius: 12,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  // Text input field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: textController,
                            focusNode: _focusNode,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Scrivi in inglese...',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _handleSubmit(),
                          ),
                        ),
                        GestureDetector(
                          onTap: _handleSubmit,
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: widget.themeColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: widget.onSubmit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Text(
                        'Non lo so, mostra risposta',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
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
    );
  }
}

/// Back card: image background with result overlay.
class _BackCard extends StatelessWidget {
  final VocabWord word;
  final Color themeColor;
  final void Function(EvalResult)? onEvaluate;
  final VoidCallback? onNext;
  final VoidCallback? onRetry;
  final MatchResult? matchResult;

  const _BackCard({
    required this.word,
    required this.themeColor,
    this.onEvaluate,
    this.onNext,
    this.onRetry,
    this.matchResult,
  });

  Color _gradeColor(MatchGrade grade) {
    switch (grade) {
      case MatchGrade.correct:
        return const Color(0xFF2ED573);
      case MatchGrade.close:
        return const Color(0xFFFFA502);
      case MatchGrade.wrong:
        return const Color(0xFFFF4757);
    }
  }

  IconData _gradeIcon(MatchGrade grade) {
    switch (grade) {
      case MatchGrade.correct:
        return Icons.check_circle_rounded;
      case MatchGrade.close:
        return Icons.info_rounded;
      case MatchGrade.wrong:
        return Icons.cancel_rounded;
    }
  }

  String _gradeLabel(MatchGrade grade) {
    switch (grade) {
      case MatchGrade.correct:
        return 'Perfetto!';
      case MatchGrade.close:
        return 'Quasi giusto!';
      case MatchGrade.wrong:
        return 'Non corretto';
    }
  }

  @override
  Widget build(BuildContext context) {
    final grade = matchResult?.grade;
    final overlayColor = grade != null ? _gradeColor(grade) : themeColor;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: overlayColor.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image (dimmed)
            WordImage(
              keyword: word.imageSearchTerm,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.zero,
            ),
            // Colored gradient overlay
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    overlayColor.withValues(alpha: 0.75),
                    overlayColor.withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  // Grade badge (if we have a match result)
                  if (grade != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_gradeIcon(grade), color: Colors.white, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            _gradeLabel(grade),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // English (answer)
                  Text(
                    word.english,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    word.italian,
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // Diff visualization (for close/wrong answers)
                  if (matchResult != null && grade != MatchGrade.correct) ...[
                    const SizedBox(height: 16),
                    _DiffVisualization(matchResult: matchResult!),
                  ],
                  const SizedBox(height: 16),
                  // Audio button
                  GestureDetector(
                    onTap: () => SpeechUtil.speak(word.english),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.volume_up_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 4),
                          Text(
                            'Ascolta',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  // Self-override buttons (only for close matches, before evaluation)
                  if (onEvaluate != null && grade == MatchGrade.close) ...[
                    Text(
                      'Come la consideri?',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _EvalButton(
                          label: 'Sbagliata',
                          icon: Icons.close_rounded,
                          color: const Color(0xFFFF4757),
                          onTap: () => onEvaluate!(EvalResult.unknown),
                        ),
                        const SizedBox(width: 10),
                        _EvalButton(
                          label: 'Giusta',
                          icon: Icons.check_rounded,
                          color: const Color(0xFF2ED573),
                          onTap: () => onEvaluate!(EvalResult.uncertain),
                        ),
                      ],
                    ),
                  ],
                  // Next / Retry buttons (after evaluation)
                  if (onNext != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _EvalButton(
                          label: 'Riprova',
                          icon: Icons.refresh_rounded,
                          color: const Color(0xFFFFA502),
                          onTap: () => onRetry!(),
                        ),
                        const SizedBox(width: 10),
                        _EvalButton(
                          label: 'Avanti',
                          icon: Icons.arrow_forward_rounded,
                          color: const Color(0xFF2ED573),
                          onTap: () => onNext!(),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the character diff between user input and correct answer.
class _DiffVisualization extends StatelessWidget {
  final MatchResult matchResult;

  const _DiffVisualization({required this.matchResult});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // User's input label
          Text(
            'Correzione:',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          // Diff characters
          Wrap(
            alignment: WrapAlignment.center,
            children: matchResult.diff.map((d) {
              Color bgColor;
              Color textColor;
              TextDecoration? decoration;

              switch (d.op) {
                case DiffOp.match:
                  bgColor = Colors.transparent;
                  textColor = Colors.white;
                  decoration = null;
                case DiffOp.substitute:
                  bgColor = const Color(0xFFFF4757).withValues(alpha: 0.4);
                  textColor = Colors.white;
                  decoration = null;
                case DiffOp.insert:
                  // Character missing from user's input
                  bgColor = const Color(0xFFFFA502).withValues(alpha: 0.4);
                  textColor = Colors.white;
                  decoration = TextDecoration.underline;
                case DiffOp.delete:
                  // Extra character user typed
                  bgColor = const Color(0xFFFF4757).withValues(alpha: 0.3);
                  textColor = Colors.white.withValues(alpha: 0.6);
                  decoration = TextDecoration.lineThrough;
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  d.char == ' ' ? '\u00A0' : d.char,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    decoration: decoration,
                    decorationColor: Colors.white,
                    decorationThickness: 2,
                    letterSpacing: 1,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(
                color: const Color(0xFFFF4757).withValues(alpha: 0.4),
                label: 'Errore',
              ),
              const SizedBox(width: 12),
              _LegendItem(
                color: const Color(0xFFFFA502).withValues(alpha: 0.4),
                label: 'Mancante',
                underline: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool underline;

  const _LegendItem({
    required this.color,
    required this.label,
    this.underline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _EvalButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _EvalButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
