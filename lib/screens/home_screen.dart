import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/vocabulary.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ProgressService? _progressService;
  String _selectedCefr = 'A1';

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    _progressService = await ProgressService.getInstance();
    if (mounted) setState(() {});
  }

  void _refreshProgress() {
    if (mounted) setState(() {});
  }

  List<VocabTheme> get _filteredThemes =>
      allThemes.where((t) => t.cefrLevel == _selectedCefr).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 8.h),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Iconsax.setting_2),
                            onPressed: () async {
                              await Navigator.of(context).push(
                                PageRouteBuilder(
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      const SettingsScreen(),
                                  transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) {
                                    return FadeTransition(
                                        opacity: animation, child: child);
                                  },
                                  transitionDuration:
                                      const Duration(milliseconds: 300),
                                ),
                              );
                              _refreshProgress();
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Icon(
                        Iconsax.book_1,
                        size: 48.sp,
                        color: AppTheme.primary,
                      )
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .scale(begin: const Offset(0.8, 0.8)),
                      SizedBox(height: 12.h),
                      Text(
                        'Vocab Flip',
                        style: GoogleFonts.poppins(
                          fontSize: 30.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .slideY(begin: -0.2),
                      SizedBox(height: 6.h),
                      Text(
                        'Impara l\'inglese giocando!',
                        style: GoogleFonts.poppins(
                          fontSize: 15.sp,
                          color: AppTheme.textSecondary,
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                      SizedBox(height: 24.h),
                      _CefrSelector(
                        selected: _selectedCefr,
                        onSelected: (level) =>
                            setState(() => _selectedCefr = level),
                      ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                      SizedBox(height: 8.h),
                      Text(
                        cefrLabels[_selectedCefr] ?? _selectedCefr,
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: cefrColors[_selectedCefr] ?? Colors.grey,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${_filteredThemes.length} categorie - ${_filteredThemes.fold<int>(0, (sum, t) => sum + t.words.length)} parole',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                sliver: SliverGrid(
                  gridDelegate:
                      SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200.w,
                    mainAxisSpacing: 16.h,
                    crossAxisSpacing: 16.w,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final theme = _filteredThemes[index];
                      return _ThemeCard(
                        theme: theme,
                        progressService: _progressService,
                        onReturn: _refreshProgress,
                      )
                          .animate()
                          .fadeIn(
                            delay: (80 * index).ms,
                            duration: 400.ms,
                          )
                          .slideY(begin: 0.15, duration: 400.ms);
                    },
                    childCount: _filteredThemes.length,
                  ),
                ),
              ),
              if (kIsWeb && defaultTargetPlatform != TargetPlatform.iOS)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 24, bottom: 16),
                    child: _ApkDownloadButton(),
                  ),
                ),
              SliverToBoxAdapter(
                child: SizedBox(height: 32.h),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CefrSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _CefrSelector({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: cefrLabels.keys.map((level) {
          final isSelected = level == selected;
          final color = cefrColors[level] ?? Colors.grey;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: FilterChip(
              label: Text(
                level,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp,
                  color: isSelected ? Colors.white : color,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onSelected(level),
              backgroundColor: color.withValues(alpha: 0.1),
              selectedColor: color,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ApkDownloadButton extends StatelessWidget {
  const _ApkDownloadButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        launchUrl(
          Uri.parse(
            'https://github.com/RiccardoDominici/Vocab-Flip/releases/latest/download/app-release.apk',
          ),
          mode: LaunchMode.externalApplication,
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppTheme.textPrimary,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.android_rounded, color: AppTheme.success, size: 16.sp),
            SizedBox(width: 6.w),
            Text(
              'Scarica per Android',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeCard extends StatefulWidget {
  final VocabTheme theme;
  final ProgressService? progressService;
  final VoidCallback onReturn;

  const _ThemeCard({
    required this.theme,
    this.progressService,
    required this.onReturn,
  });

  @override
  State<_ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends State<_ThemeCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final themeColor = Color(widget.theme.colorValue);
    final completion =
        widget.progressService?.getThemeCompletion(widget.theme.name) ?? 0.0;
    final completionPct = (completion * 100).round();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          onTap: () async {
            await Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    GameScreen(theme: widget.theme),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
            widget.onReturn();
          },
          child: Container(
            decoration: AppTheme.glassCard(
              opacity: 0.7,
              shadowColor: themeColor,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        themeColor.withValues(alpha: 0.15),
                        themeColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: themeColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      widget.theme.icon,
                      size: 28.sp,
                      color: themeColor,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Text(
                    widget.theme.name,
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${widget.theme.words.length} parole',
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    color: themeColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (completionPct > 0) ...[
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: completion,
                            minHeight: 4,
                            backgroundColor:
                                themeColor.withValues(alpha: 0.12),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(themeColor),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '$completionPct%',
                          style: GoogleFonts.poppins(
                            fontSize: 10.sp,
                            color: themeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
