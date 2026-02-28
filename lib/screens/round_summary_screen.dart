import 'package:flutter/material.dart';
import '../data/vocabulary.dart';
import '../models/word_progress.dart';
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(flex: 1),
                Icon(
                  result.unknownCount == 0
                      ? Icons.emoji_events_rounded
                      : Icons.bar_chart_rounded,
                  size: 64,
                  color: result.unknownCount == 0
                      ? const Color(0xFFFFD700)
                      : themeColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Round ${result.round} completato!',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(theme.icon, size: 20, color: themeColor),
                    const SizedBox(width: 6),
                    Text(
                      theme.name,
                      style: TextStyle(
                        fontSize: 18,
                        color: themeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Stats cards
                Row(
                  children: [
                    _StatCard(
                      icon: Icons.check_circle_rounded,
                      label: 'La so!',
                      count: result.knownCount,
                      percent: knownPct,
                      color: const Color(0xFF2ED573),
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.help_rounded,
                      label: 'Incerto',
                      count: result.uncertainCount,
                      percent: uncertainPct,
                      color: const Color(0xFFFFA502),
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.cancel_rounded,
                      label: 'Non la sapevo',
                      count: result.unknownCount,
                      percent: unknownPct,
                      color: const Color(0xFFFF4757),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
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
                            child: Container(
                                color: const Color(0xFF2ED573)),
                          ),
                        if (result.uncertainCount > 0)
                          Expanded(
                            flex: result.uncertainCount,
                            child: Container(
                                color: const Color(0xFFFFA502)),
                          ),
                        if (result.unknownCount > 0)
                          Expanded(
                            flex: result.unknownCount,
                            child: Container(
                                color: const Color(0xFFFF4757)),
                          ),
                      ],
                    ),
                  ),
                ),
                // Badges
                if (result.newBadges.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  ...result.newBadges.map((badge) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                themeColor.withValues(alpha: 0.15),
                                themeColor.withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: themeColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.military_tech_rounded,
                                  size: 24, color: themeColor),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  badge,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: themeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
                const Spacer(flex: 2),
                // Action buttons
                Row(
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF636E72),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              '${(percent * 100).round()}%',
              style: TextStyle(
                fontSize: 13,
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
