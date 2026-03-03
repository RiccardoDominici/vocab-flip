import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../data/vocabulary.dart';
import '../models/word_progress.dart';
import '../screens/game_screen.dart' show AnswerCapture;
import '../theme/app_theme.dart';
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
            color: widget.themeColor.withValues(alpha: 0.25),
            blurRadius: 28,
            offset: const Offset(0, 12),
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
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),
            // Text overlay with input
            Positioned(
              left: 20.w,
              right: 20.w,
              bottom: 24.h,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.word.italian,
                    style: GoogleFonts.poppins(
                      fontSize: 30.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                      shadows: [
                        const Shadow(
                          blurRadius: 12,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 14.h),
                  // Text input field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: textController,
                            focusNode: _focusNode,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Scrivi in inglese...',
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 14.h,
                              ),
                            ),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _handleSubmit(),
                          ),
                        ),
                        GestureDetector(
                          onTap: _handleSubmit,
                          child: Container(
                            margin: EdgeInsets.only(right: 6.w),
                            padding: EdgeInsets.all(10.w),
                            decoration: BoxDecoration(
                              color: widget.themeColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Iconsax.send_1,
                              color: Colors.white,
                              size: 20.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  GestureDetector(
                    onTap: widget.onSubmit,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        'Non lo so, mostra risposta',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
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
        return AppTheme.success;
      case MatchGrade.close:
        return AppTheme.warning;
      case MatchGrade.wrong:
        return AppTheme.error;
    }
  }

  IconData _gradeIcon(MatchGrade grade) {
    switch (grade) {
      case MatchGrade.correct:
        return Iconsax.tick_circle;
      case MatchGrade.close:
        return Iconsax.info_circle;
      case MatchGrade.wrong:
        return Iconsax.close_circle;
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
            blurRadius: 28,
            offset: const Offset(0, 12),
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
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  // Grade badge (if we have a match result)
                  if (grade != null) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_gradeIcon(grade),
                              color: Colors.white, size: 20.sp),
                          SizedBox(width: 6.w),
                          Text(
                            _gradeLabel(grade),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15.sp,
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .scale(begin: const Offset(0.8, 0.8)),
                    SizedBox(height: 16.h),
                  ],
                  // English (answer)
                  Text(
                    word.english,
                    style: GoogleFonts.poppins(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                  SizedBox(height: 4.h),
                  Text(
                    word.italian,
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // Diff visualization (for close/wrong answers)
                  if (matchResult != null &&
                      grade != MatchGrade.correct) ...[
                    SizedBox(height: 16.h),
                    _DiffVisualization(matchResult: matchResult!),
                  ],
                  SizedBox(height: 16.h),
                  // Audio button
                  GestureDetector(
                    onTap: () => SpeechUtil.speak(word.english),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Iconsax.volume_high,
                              color: Colors.white, size: 20.sp),
                          SizedBox(width: 4.w),
                          Text(
                            'Ascolta',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  // Self-override buttons (only for close matches, before evaluation)
                  if (onEvaluate != null &&
                      grade == MatchGrade.close) ...[
                    Text(
                      'Come la consideri?',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _EvalButton(
                          label: 'Sbagliata',
                          icon: Iconsax.close_circle,
                          color: AppTheme.error,
                          onTap: () => onEvaluate!(EvalResult.unknown),
                        ),
                        SizedBox(width: 10.w),
                        _EvalButton(
                          label: 'Giusta',
                          icon: Iconsax.tick_circle,
                          color: AppTheme.success,
                          onTap: () => onEvaluate!(EvalResult.uncertain),
                        ),
                      ],
                    ),
                  ],
                  // Next / Retry buttons (after evaluation)
                  if (onNext != null) ...[
                    SizedBox(height: 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _EvalButton(
                          label: 'Riprova',
                          icon: Iconsax.refresh,
                          color: AppTheme.warning,
                          onTap: () => onRetry!(),
                        ),
                        SizedBox(width: 10.w),
                        _EvalButton(
                          label: 'Avanti',
                          icon: Iconsax.arrow_right_1,
                          color: AppTheme.success,
                          onTap: () => onNext!(),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 8.h),
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          // User's input label
          Text(
            'Correzione:',
            style: GoogleFonts.poppins(
              fontSize: 11.sp,
              color: Colors.white.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6.h),
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
                  bgColor = AppTheme.error.withValues(alpha: 0.4);
                  textColor = Colors.white;
                  decoration = null;
                case DiffOp.insert:
                  // Character missing from user's input
                  bgColor = AppTheme.warning.withValues(alpha: 0.4);
                  textColor = Colors.white;
                  decoration = TextDecoration.underline;
                case DiffOp.delete:
                  // Extra character user typed
                  bgColor = AppTheme.error.withValues(alpha: 0.3);
                  textColor = Colors.white.withValues(alpha: 0.6);
                  decoration = TextDecoration.lineThrough;
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  d.char == ' ' ? '\u00A0' : d.char,
                  style: GoogleFonts.poppins(
                    fontSize: 20.sp,
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
          SizedBox(height: 8.h),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(
                color: AppTheme.error.withValues(alpha: 0.4),
                label: 'Errore',
              ),
              SizedBox(width: 12.w),
              _LegendItem(
                color: AppTheme.warning.withValues(alpha: 0.4),
                label: 'Mancante',
                underline: true,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
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
        SizedBox(width: 4.w),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10.sp,
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
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
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
            Icon(icon, size: 22.sp, color: color),
            SizedBox(height: 2.h),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
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
