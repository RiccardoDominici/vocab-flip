---
phase: quick-2
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/services/progress_service.dart
  - lib/screens/home_screen.dart
autonomous: true
requirements: [QUICK-2]

must_haves:
  truths:
    - "User sees an engaging overall progress indicator on the home screen showing mastery across all themes for the selected CEFR level"
    - "User sees a prominent 'Riprendi allenamento' button when they have previous progress, or 'Inizia allenamento' when they have none"
    - "Tapping the resume button navigates to GameScreen with the most appropriate theme"
    - "Progress bar animates smoothly on load and when CEFR level changes"
  artifacts:
    - path: "lib/services/progress_service.dart"
      provides: "Last-played theme tracking and overall stats computation"
      contains: "getLastPlayedTheme"
    - path: "lib/screens/home_screen.dart"
      provides: "Progress hero section with circular progress and resume button"
      contains: "_ProgressHero"
  key_links:
    - from: "lib/screens/home_screen.dart"
      to: "lib/services/progress_service.dart"
      via: "getOverallStats and getLastPlayedTheme methods"
      pattern: "getOverallStats|getLastPlayedTheme|saveLastPlayedTheme"
    - from: "lib/screens/home_screen.dart (_ProgressHero resume button)"
      to: "lib/screens/game_screen.dart"
      via: "Navigator.push with appropriate VocabTheme"
      pattern: "GameScreen\\(theme:"
---

<objective>
Add an engaging progress indicator and "Resume Training" button to the home screen.

Purpose: Give users immediate visual feedback on their learning journey and a one-tap way to continue where they left off (or start fresh based on their CEFR level).
Output: Updated home_screen.dart with a progress hero section; updated progress_service.dart with last-played tracking and overall stats.
</objective>

<execution_context>
@/Users/riccardo/.claude/get-shit-done/workflows/execute-plan.md
@/Users/riccardo/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@lib/services/progress_service.dart
@lib/screens/home_screen.dart
@lib/screens/game_screen.dart
@lib/data/vocabulary.dart
@lib/models/word_progress.dart
@lib/theme/app_theme.dart

<interfaces>
<!-- Key types and contracts the executor needs -->

From lib/data/vocabulary.dart:
```dart
class VocabTheme {
  final String name;
  final String cefrLevel; // A1, A2, B1, B2, C1, C2
  final IconData icon;
  final int colorValue;
  final List<VocabWord> words;
}
final List<VocabTheme> allThemes = [...];
const Map<String, String> cefrLabels = { 'A1': ..., ... };
const Map<String, Color> cefrColors = { 'A1': Color(...), ... };
```

From lib/services/progress_service.dart:
```dart
class ProgressService {
  static Future<ProgressService> getInstance();
  double getThemeCompletion(String themeName);
  ThemeProgress getThemeProgress(String themeName);
  List<VocabWord> generateRound(VocabTheme theme, {int maxCards = 10});
  int get totalMastered;
}
```

From lib/models/word_progress.dart:
```dart
class ThemeProgress {
  double get completionPercent;  // 0.0 to 1.0
  int get masteredCount;
  int get knownCount;
  int get unknownCount;
  int get unseenCount;
  int _totalThemeWords;
}
```

From lib/theme/app_theme.dart:
```dart
class AppTheme {
  static const Color primary = Color(0xFF6C63FF);
  static const Color success = Color(0xFF2ED573);
  static const Color warning = Color(0xFFFFA502);
  static const Color textPrimary, textSecondary, textMuted;
  static BoxDecoration glassCard({double opacity, double borderRadius, Color? shadowColor});
  static BoxDecoration accentGlassCard({required Color color, ...});
}
```

From lib/screens/game_screen.dart:
```dart
class GameScreen extends StatefulWidget {
  final VocabTheme theme;
  const GameScreen({super.key, required this.theme});
}
```
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add last-played tracking and overall stats to ProgressService</name>
  <files>lib/services/progress_service.dart</files>
  <action>
Add three capabilities to ProgressService:

1. **Last-played theme tracking** — persist the last theme name played via SharedPreferences key `last_played_theme`:
   - `Future<void> saveLastPlayedTheme(String themeName)` — save theme name
   - `String? getLastPlayedTheme()` — return stored name (sync, already loaded in _init)
   - Load the value in `_loadAll()` into a `String? _lastPlayedTheme` field
   - Clear it in `resetAllProgress()`

2. **Overall stats for a CEFR level** — add a method:
   ```dart
   OverallStats getOverallStats(String cefrLevel)
   ```
   This computes across all themes where `theme.cefrLevel == cefrLevel`:
   - `totalWords`: sum of all theme word counts for that level
   - `masteredWords`: sum of masteredCount across those themes
   - `knownWords`: sum of knownCount (confidence >= 2, not mastered)
   - `seenWords`: total words with timesSeen > 0
   - `overallCompletion`: weighted average of all theme completionPercent values (0.0-1.0)

3. **OverallStats data class** — add at the bottom of the file:
   ```dart
   class OverallStats {
     final int totalWords;
     final int masteredWords;
     final int knownWords;
     final int seenWords;
     final double overallCompletion;
     const OverallStats({...});
   }
   ```

4. **Best theme to resume** — add a method:
   ```dart
   VocabTheme? getResumeTheme(String cefrLevel)
   ```
   Logic: If `_lastPlayedTheme` is set AND its cefrLevel matches the given level AND it's not 100% complete, return that theme. Otherwise, find the first theme at that level with the lowest non-zero completion (in-progress theme). If all are either 0% or 100%, return the first theme at 0% (to start fresh). Return null only if no themes exist for that level.

Also: call `saveLastPlayedTheme` from within `completeRound()` automatically, so we always track the most recently completed round's theme. This is the most reliable place since it means the user actually engaged with the theme.
  </action>
  <verify>
    <automated>cd /Users/riccardo/Developer/VibeCoding/vocab_flip && flutter analyze lib/services/progress_service.dart 2>&1 | tail -5</automated>
  </verify>
  <done>ProgressService has getLastPlayedTheme, saveLastPlayedTheme, getOverallStats(cefrLevel), getResumeTheme(cefrLevel), and OverallStats class. All compile without errors.</done>
</task>

<task type="auto">
  <name>Task 2: Build progress hero section with animated ring and resume button on home screen</name>
  <files>lib/screens/home_screen.dart</files>
  <action>
Add a `_ProgressHero` widget and insert it in the home screen's `CustomScrollView` between the CEFR selector area and the theme grid. This section replaces the current plain text stats line ("X categorie - Y parole") with a much more engaging visual.

**_ProgressHero widget** — a `StatelessWidget` receiving `ProgressService`, `String cefrLevel`, and `VoidCallback onReturn` (to refresh after game). Layout:

1. **Glass card container** using `AppTheme.glassCard()` with horizontal padding 24.w, containing a Row:

   Left side — **Animated circular progress ring** (custom painted):
   - Size: 90.w x 90.w
   - Use a `CustomPainter` (`_ProgressRingPainter`) that draws:
     - Background circle track: `cefrColor.withValues(alpha: 0.12)`, strokeWidth 8
     - Foreground arc: gradient sweep from `cefrColor.withValues(alpha: 0.6)` to `cefrColor`, strokeWidth 8, rounded caps, sweeping `overallCompletion * 2 * pi`
   - Center text: percentage number in bold Poppins 22.sp + "%" in 12.sp below it
   - Wrap the `CustomPaint` in a `TweenAnimationBuilder<double>` (tween from 0 to `overallCompletion`, duration 800ms, curve `Curves.easeOutCubic`) so the ring animates on appear

   Right side — **Stats and button column** (Expanded, crossAxisAlignment start):
   - Row of mini stats: mastered count with a green dot, known count with a blue dot, remaining with a gray dot — each in Poppins 11.sp
   - SizedBox(height: 10.h)
   - **Resume button**: a Container with gradient background from `cefrColor` to `cefrColor.withValues(alpha: 0.8)`, borderRadius 14, padding symmetric(horizontal: 16.w, vertical: 12.h). Contains a Row with:
     - Icon: `Iconsax.play_circle` (or `Iconsax.play` if play_circle unavailable), white, 20.sp
     - SizedBox(width: 8.w)
     - Text column (crossAxisAlignment start):
       - Primary text: "Riprendi" if there's a last-played theme in progress at this level, otherwise "Inizia" — in Poppins 14.sp bold white
       - Secondary text: theme name (e.g., "Cibo e Bevande") in Poppins 10.sp white70 — only shown if a resume theme exists
   - The button calls `_progressService.getResumeTheme(_selectedCefr)`. If non-null, navigates to `GameScreen(theme: resumeTheme)` using the same `PageRouteBuilder` with `FadeTransition` pattern already used in `_ThemeCard`. After returning, calls `onReturn()` and also calls `_progressService!.saveLastPlayedTheme(resumeTheme.name)` is NOT needed here since completeRound already does it.

2. **Entrance animation**: Wrap the entire `_ProgressHero` with `.animate().fadeIn(delay: 350.ms, duration: 500.ms).slideY(begin: 0.1)`.

**Integration into _HomeScreenState.build():**
- Remove the current stats Text widget ("X categorie - Y parole")
- Insert `_ProgressHero(progressService: _progressService, cefrLevel: _selectedCefr, onReturn: _refreshProgress)` after the CEFR label text and before `SizedBox(height: 20.h)`
- Keep the SizedBox(height: 20.h) before the grid

**_ProgressRingPainter** — a `CustomPainter` class:
- Constructor takes: `double progress` (0-1), `Color color`
- paint(): draw background circle, then foreground arc using `SweepGradient` shader on the paint, rotating start to -pi/2 (12 o'clock position)
- Use `strokeCap: StrokeCap.round` for the foreground arc
- shouldRepaint: compare progress and color values

**Edge cases:**
- If `_progressService` is null (still loading), show a shimmer placeholder or just don't show the hero
- If overall completion is 0 and no themes played, show "Inizia allenamento" with the first theme of the level
- The resume button should always be tappable (there's always at least one theme per CEFR level)
  </action>
  <verify>
    <automated>cd /Users/riccardo/Developer/VibeCoding/vocab_flip && flutter analyze lib/screens/home_screen.dart 2>&1 | tail -5</automated>
  </verify>
  <done>Home screen displays an animated circular progress ring with overall mastery percentage for the selected CEFR level, mini stats (mastered/known/remaining), and a gradient "Riprendi allenamento" or "Inizia allenamento" button that navigates to the appropriate GameScreen theme. The progress ring animates on load. All compiles without errors.</done>
</task>

</tasks>

<verification>
Run full project analysis and smoke test:
```bash
cd /Users/riccardo/Developer/VibeCoding/vocab_flip && flutter analyze && flutter test
```
</verification>

<success_criteria>
- Home screen shows an animated circular progress ring reflecting overall mastery for the selected CEFR level
- Progress ring animates from 0 to current value on load with easeOutCubic curve
- Mini stats show mastered/known/remaining word counts
- A gradient "Riprendi allenamento" button appears with the resume theme name when progress exists
- Button shows "Inizia allenamento" with the first available theme when no progress exists
- Tapping the button navigates to GameScreen with the correct theme
- Returning from GameScreen refreshes the progress display
- Switching CEFR levels updates the progress ring and resume target
- flutter analyze passes with no errors
- flutter test passes
</success_criteria>

<output>
After completion, create `.planning/quick/2-add-engaging-progress-bar-and-resume-tra/2-SUMMARY.md`
</output>
