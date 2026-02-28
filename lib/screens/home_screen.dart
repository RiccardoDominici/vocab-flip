import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/vocabulary.dart';
import '../services/progress_service.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ProgressService? _progressService;

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

  @override
  Widget build(BuildContext context) {
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
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Column(
                    children: [
                      // Settings icon top-right
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.settings_rounded),
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
                              foregroundColor: const Color(0xFF636E72),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '\u{1F3AF}',
                        style: TextStyle(fontSize: 48),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Vocab Flip',
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2D3436),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Impara l\'inglese giocando!',
                        style:
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: const Color(0xFF636E72),
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scegli un tema e indovina le parole',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF636E72),
                                ),
                      ),
                      // APK download button (web only)
                      if (kIsWeb) ...[
                        const SizedBox(height: 16),
                        _ApkDownloadButton(),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final theme = allThemes[index];
                      return _ThemeCard(
                        theme: theme,
                        progressService: _progressService,
                        onReturn: _refreshProgress,
                      );
                    },
                    childCount: allThemes.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApkDownloadButton extends StatelessWidget {
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2D3436),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.android_rounded, color: const Color(0xFF2ED573), size: 22),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scarica per Android',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'APK diretta \u2014 Android only',
                  style: TextStyle(
                    color: Color(0xFF636E72),
                    fontSize: 10,
                  ),
                ),
              ],
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
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: themeColor.withValues(alpha: 0.25),
                  blurRadius: _hovering ? 20 : 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      widget.theme.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.theme.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3436),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.theme.words.length} parole',
                  style: TextStyle(
                    fontSize: 12,
                    color: themeColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // Progress bar
                if (completionPct > 0) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        const SizedBox(height: 2),
                        Text(
                          '$completionPct%',
                          style: TextStyle(
                            fontSize: 10,
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
