import 'dart:math';
import 'package:flutter/material.dart';
import '../data/vocabulary.dart';
import '../models/word_progress.dart';
import '../utils/speech.dart';
import 'word_image.dart';

class FlipCardWidget extends StatefulWidget {
  final VocabWord word;
  final Color themeColor;
  final bool isFlipped;
  final VoidCallback onTap;
  final void Function(EvalResult)? onEvaluate;

  const FlipCardWidget({
    super.key,
    required this.word,
    required this.themeColor,
    required this.isFlipped,
    required this.onTap,
    this.onEvaluate,
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.isFlipped ? null : widget.onTap,
      child: AnimatedBuilder(
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
                    ),
                  )
                : _FrontCard(
                    word: widget.word,
                    themeColor: widget.themeColor,
                  ),
          );
        },
      ),
    );
  }
}

class _FrontCard extends StatelessWidget {
  final VocabWord word;
  final Color themeColor;

  const _FrontCard({required this.word, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          WordImage(
            keyword: word.imageSearchTerm,
            size: 120,
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              word.italian,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Tocca per girare',
              style: TextStyle(
                fontSize: 14,
                color: themeColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackCard extends StatelessWidget {
  final VocabWord word;
  final Color themeColor;
  final void Function(EvalResult)? onEvaluate;

  const _BackCard({
    required this.word,
    required this.themeColor,
    this.onEvaluate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeColor,
            themeColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          WordImage(
            keyword: word.imageSearchTerm,
            size: 80,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              word.english,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              word.italian,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.75),
              ),
              textAlign: TextAlign.center,
            ),
          ),
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
          const SizedBox(height: 20),
          // Evaluation buttons
          if (onEvaluate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Text(
                    'La sapevi?',
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
                        label: 'No',
                        icon: Icons.close_rounded,
                        color: const Color(0xFFFF4757),
                        onTap: () => onEvaluate!(EvalResult.unknown),
                      ),
                      const SizedBox(width: 10),
                      _EvalButton(
                        label: 'Incerto',
                        icon: Icons.help_outline_rounded,
                        color: const Color(0xFFFFA502),
                        onTap: () => onEvaluate!(EvalResult.uncertain),
                      ),
                      const SizedBox(width: 10),
                      _EvalButton(
                        label: 'La so!',
                        icon: Icons.check_rounded,
                        color: const Color(0xFF2ED573),
                        onTap: () => onEvaluate!(EvalResult.known),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
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
