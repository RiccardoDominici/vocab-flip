import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../data/vocabulary.dart';
import '../models/word_progress.dart';
import '../theme/app_theme.dart';
import 'game_screen.dart';

class RoundSummaryScreen extends StatelessWidget {
  final VocabTheme theme;
  final RoundResult result;

  const RoundSummaryScreen({
    super.key,
    required this.theme,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = Color(theme.colorValue);
    final knownPct =
        result.totalCards > 0 ? (result.knownCount / result.totalCards) : 0.0;
    final uncertainPct = result.totalCards > 0
        ? (result.uncertainCount / result.totalCards)
        : 0.0;
    final unknownPct = result.totalCards > 0
        ? (result.unknownCount / result.totalCards)
        : 0.0;

    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              children: [
                const Spacer(flex: 1),
                Icon(
                  result.unknownCount == 0
                      ? Iconsax.cup
                      : Iconsax.chart,
                  size: 64.sp,
                  color: result.unknownCount == 0
                      ? AppTheme.gold
                      : themeColor,
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(begin: const Offset(0.6, 0.6)),
                SizedBox(height: 16.h),
                Text(
                  'Round ${result.round} completato!',
                  style: GoogleFonts.poppins(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 500.ms)
                    .slideY(begin: 0.2),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(theme.icon, size: 20.sp, color: themeColor),
                    SizedBox(width: 6.w),
                    Text(
                      theme.name,
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        color: themeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                SizedBox(height: 32.h),
                // Stats cards
                Row(
                  children: [
                    _StatCard(
                      icon: Iconsax.tick_circle,
                      label: 'La so!',
                      count: result.knownCount,
                      percent: knownPct,
                      color: AppTheme.success,
                    ),
                    SizedBox(width: 12.w),
                    _StatCard(
                      icon: Iconsax.warning_2,
                      label: 'Incerto',
                      count: result.uncertainCount,
                      percent: uncertainPct,
                      color: AppTheme.warning,
                    ),
                    SizedBox(width: 12.w),
                    _StatCard(
                      icon: Iconsax.close_circle,
                      label: 'Non la sapevo',
                      count: result.unknownCount,
                      percent: unknownPct,
                      color: AppTheme.error,
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 500.ms)
                    .slideY(begin: 0.15),
                SizedBox(height: 24.h),
                // Progress bar visualization
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 12,
                    child: Row(
                      children: [
                        if (result.knownCount > 0)
                          Expanded(
                            flex: result.knownCount,
                            child: Container(color: AppTheme.success),
                          ),
                        if (result.uncertainCount > 0)
                          Expanded(
                            flex: result.uncertainCount,
                            child: Container(color: AppTheme.warning),
                          ),
                        if (result.unknownCount > 0)
                          Expanded(
                            flex: result.unknownCount,
                            child: Container(color: AppTheme.error),
                          ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
                // Badges
                if (result.newBadges.isNotEmpty) ...[
                  SizedBox(height: 24.h),
                  ...result.newBadges.asMap().entries.map((entry) => Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.w, vertical: 12.h),
                          decoration: AppTheme.accentGlassCard(
                            color: themeColor,
                            opacity: 0.12,
                            borderRadius: 16,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Iconsax.medal_star,
                                  size: 24.sp, color: themeColor),
                              SizedBox(width: 8.w),
                              Flexible(
                                child: Text(
                                  entry.value,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                    color: themeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(delay: (600 + entry.key * 150).ms)
                            .slideX(begin: 0.2),
                      )),
                ],
                const Spacer(flex: 2),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Iconsax.home_2, size: 20.sp),
                        label: Text(
                          'Home',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      GameScreen(theme: theme),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                return FadeTransition(
                                    opacity: animation, child: child);
                              },
                              transitionDuration:
                                  const Duration(milliseconds: 300),
                            ),
                          );
                        },
                        icon: Icon(Iconsax.refresh, size: 20.sp),
                        label: Text(
                          'Nuovo Round',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: themeColor,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 400.ms)
                    .slideY(begin: 0.2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final double percent;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
        decoration: AppTheme.glassCard(
          opacity: 0.7,
          shadowColor: color,
        ),
        child: Column(
          children: [
            Icon(icon, size: 28.sp, color: color),
            SizedBox(height: 6.h),
            Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11.sp,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6.h),
            Text(
              '${(percent * 100).round()}%',
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
