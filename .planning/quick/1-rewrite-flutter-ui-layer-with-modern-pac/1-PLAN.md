---
phase: quick
plan: 1
type: execute
wave: 1
depends_on: []
files_modified:
  - pubspec.yaml
  - lib/main.dart
  - lib/theme/app_theme.dart
  - lib/screens/home_screen.dart
  - lib/screens/settings_screen.dart
  - lib/screens/game_screen.dart
  - lib/screens/round_summary_screen.dart
  - lib/widgets/flip_card.dart
  - lib/widgets/word_image.dart
autonomous: false
requirements: [UI-REWRITE]

must_haves:
  truths:
    - "App uses Google Fonts (Poppins) throughout instead of default system font"
    - "All screens use flutter_animate for entrance animations (fade-in, slide-up)"
    - "Loading states use shimmer effect instead of CircularProgressIndicator"
    - "Theme cards on home screen use glassmorphism/frosted glass styling"
    - "Icons throughout use Iconsax icons instead of Material icons"
    - "All existing game logic, navigation flow, and state management work identically"
    - "FlipCard animation (SingleTickerProviderStateMixin 3D flip) still works"
    - "AnswerCapture InheritedWidget pattern still works"
  artifacts:
    - path: "pubspec.yaml"
      provides: "All 8 new packages declared as dependencies"
      contains: "flutter_animate"
    - path: "lib/theme/app_theme.dart"
      provides: "Centralized theme constants, colors, text styles using GoogleFonts"
    - path: "lib/main.dart"
      provides: "ScreenUtil initialization wrapping MaterialApp"
      contains: "ScreenUtilInit"
    - path: "lib/screens/home_screen.dart"
      provides: "Modernized home with glassmorphism cards, iconsax, animate"
    - path: "lib/screens/game_screen.dart"
      provides: "Modernized game screen preserving all logic"
    - path: "lib/widgets/flip_card.dart"
      provides: "Modernized flip card preserving animation logic"
  key_links:
    - from: "lib/main.dart"
      to: "lib/theme/app_theme.dart"
      via: "import for ThemeData"
      pattern: "import.*app_theme"
    - from: "lib/screens/game_screen.dart"
      to: "lib/widgets/flip_card.dart"
      via: "FlipCardWidget usage with AnswerCapture"
      pattern: "AnswerCapture"
    - from: "lib/screens/home_screen.dart"
      to: "lib/screens/game_screen.dart"
      via: "Navigator.push on theme card tap"
      pattern: "GameScreen\\(theme:"
---

<objective>
Rewrite the entire Flutter UI layer using modern packages (flutter_animate, google_fonts, flutter_screenutil, shimmer, glassmorphism_ui, iconsax_flutter) for a polished, contemporary look while preserving ALL existing logic, state management, and navigation flow.

Purpose: Transform the app from basic Material UI to a visually striking modern design with smooth animations, glass effects, premium typography, and cohesive iconography.
Output: All 6 screen/widget files rewritten with new visual treatment, centralized theme, responsive sizing.
</objective>

<execution_context>
@/Users/riccardo/.claude/get-shit-done/workflows/execute-plan.md
@/Users/riccardo/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@pubspec.yaml
@lib/main.dart
@lib/data/vocabulary.dart (VocabTheme model with IconData icon, int colorValue - PRESERVE)
@lib/models/word_progress.dart (EvalResult, RoundResult models - PRESERVE)
@lib/screens/home_screen.dart
@lib/screens/game_screen.dart (AnswerCapture InheritedWidget - PRESERVE EXACTLY)
@lib/screens/settings_screen.dart
@lib/screens/round_summary_screen.dart
@lib/widgets/flip_card.dart (SingleTickerProviderStateMixin flip animation - PRESERVE)
@lib/widgets/word_image.dart

<interfaces>
<!-- Key contracts that MUST be preserved exactly -->

From lib/data/vocabulary.dart:
```dart
class VocabWord {
  final String italian;
  final String english;
  final String? imageKeyword;
  String get imageSearchTerm => imageKeyword ?? english;
}

class VocabTheme {
  final String name;
  final String cefrLevel;
  final IconData icon;      // Uses Material IconData - keep working
  final int colorValue;     // Used as Color(colorValue) everywhere
  final List<VocabWord> words;
}

const Map<String, String> cefrLabels;
const Map<String, Color> cefrColors;
final List<VocabTheme> allThemes;
```

From lib/screens/game_screen.dart:
```dart
class AnswerCapture extends InheritedWidget {
  final TextEditingController controller;
  static TextEditingController of(BuildContext context);
  // MUST remain exactly as-is
}
```

From lib/widgets/flip_card.dart:
```dart
class FlipCardWidget extends StatefulWidget {
  final VocabWord word;
  final Color themeColor;
  final bool isFlipped;
  final VoidCallback onTap;
  final void Function(EvalResult)? onEvaluate;
  final VoidCallback? onNext;
  final VoidCallback? onRetry;
  final MatchResult? matchResult;
  // Constructor API MUST remain identical
}
// SingleTickerProviderStateMixin with AnimationController + Matrix4.rotateY
// MUST be preserved
```

From lib/models/word_progress.dart:
```dart
enum EvalResult { known, uncertain, unknown }
class RoundResult {
  final int knownCount, uncertainCount, unknownCount, totalCards, round;
  final List<String> newBadges;
}
```

From lib/services/progress_service.dart (DO NOT MODIFY):
```dart
// Used in home_screen: getThemeCompletion(themeName) -> double
// Used in game_screen: generateRound(theme, maxCards:) -> List<VocabWord>
// Used in game_screen: recordEvaluation(themeName, italian, result)
// Used in settings_screen: totalMastered, consecutivePerfectRounds, resetAllProgress()
```
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add packages, create theme foundation, rewrite home and settings screens</name>
  <files>
    pubspec.yaml
    lib/theme/app_theme.dart (NEW)
    lib/main.dart
    lib/screens/home_screen.dart
    lib/screens/settings_screen.dart
  </files>
  <action>
**Step 1: Add dependencies to pubspec.yaml**

Add these under `dependencies:`:
```yaml
flutter_animate: ^4.5.2
google_fonts: ^6.2.1
flutter_screenutil: ^5.9.3
shimmer: ^3.0.0
glassmorphism_ui: ^0.3.0
iconsax_flutter: ^1.0.0+1
```

Note: Skip `lottie` and `flutter_svg` — no asset files exist in the project, and adding packages without assets provides no value. These can be added later when actual Lottie/SVG assets are created.

Run `flutter pub get` to verify all packages resolve.

**Step 2: Create lib/theme/app_theme.dart (NEW FILE)**

Create a centralized theme file with:
- `AppTheme` class with static methods/constants
- Color palette: Keep existing brand color `0xFF6C63FF` as primary. Define surface colors, card colors, text colors as named constants.
- Define `darkSurface = Color(0xFF1A1A2E)`, `deepBackground = Color(0xFF16213E)`, `accentGradient` using primary.
- Text theme using `GoogleFonts.poppinsTextTheme()` as base, customized with weights.
- `static ThemeData get lightTheme` that builds a full Material 3 ThemeData using GoogleFonts.poppins for all text styles.
- Helper: `static BoxDecoration get gradientBackground` for the app background (upgrade from flat gray gradient to a richer gradient, e.g. soft indigo to white).
- Helper: `static BoxDecoration glassCard({double opacity = 0.15, double blur = 10})` that returns a BoxDecoration with frosted glass look (white with low opacity, rounded corners 20, subtle border, soft shadow).
- Export the ScreenUtil design size constants (designWidth: 393, designHeight: 852 — standard modern phone).

**Step 3: Rewrite lib/main.dart**

- Import `flutter_screenutil` and `app_theme.dart`
- Wrap MaterialApp with `ScreenUtilInit(designSize: Size(393, 852), ...)`
- Use `AppTheme.lightTheme` for the theme
- Keep `debugShowCheckedModeBanner: false` and `home: HomeScreen()`

**Step 4: Rewrite lib/screens/home_screen.dart**

PRESERVE ALL LOGIC: `_HomeScreenState`, `_initService()`, `_refreshProgress()`, `_filteredThemes`, navigation to GameScreen and SettingsScreen, `_CefrSelector` functionality, `_ApkDownloadButton` functionality.

Visual changes:
- Import `flutter_animate`, `google_fonts`, `flutter_screenutil`, `glassmorphism_ui`, `iconsax_flutter`, `app_theme.dart`
- Replace background gradient with `AppTheme.gradientBackground`
- Replace `Icons.school_rounded` header icon with `IconsaxBold.teacher` (or `IconsaxBold.book_1`)
- Replace `Icons.settings_rounded` with `IconsaxBold.setting_2`
- Use `.sp` for font sizes, `.w`/`.h` for padding/spacing via ScreenUtil
- Apply `GoogleFonts.poppins()` to text styles (or rely on theme)
- Add `flutter_animate` entrance animations:
  - Title: `.animate().fadeIn(duration: 600.ms).slideY(begin: -0.2)`
  - CEFR selector: `.animate().fadeIn(delay: 200.ms, duration: 400.ms)`
  - Grid items: `.animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.1)` (staggered)
- `_ThemeCard`: Replace plain white Container with glassmorphism-styled card:
  - Use `GlassContainer` from glassmorphism_ui or manually create frosted look with `BackdropFilter` + `ClipRRect`
  - Keep the hover scale animation (AnimatedScale)
  - Replace `Icons.*` icon in card with corresponding Iconsax variant if logical match exists; otherwise keep Material icon since `VocabTheme.icon` is `IconData` from Material
  - Add subtle `.animate()` on hover or always-visible shimmer on the icon container
- `_CefrSelector`: Use ScreenUtil sizing, keep FilterChip logic
- Replace `Icons.android_rounded` in APK button with `IconsaxBold.mobile` or keep Android icon
- Keep ALL: ProgressService usage, Navigator.push with PageRouteBuilder, _hovering MouseRegion logic

**Step 5: Rewrite lib/screens/settings_screen.dart**

PRESERVE ALL LOGIC: FutureBuilder for ProgressService, _confirmReset dialog, _StatRow data display, navigation pop.

Visual changes:
- Import new packages
- Replace background with `AppTheme.gradientBackground`
- Replace `Icons.arrow_back_rounded` with `IconsaxBold.arrow_left`
- Stats container: Apply glass card styling
- `_StatRow`: Replace `Icons.star_rounded` with `IconsaxBold.star_1`, `Icons.local_fire_department_rounded` with `IconsaxBold.flame`
- Add entrance animations: stats card `.animate().fadeIn(duration: 500.ms).slideX(begin: -0.1)`
- Reset button: `.animate().fadeIn(delay: 300.ms)`
- Use ScreenUtil `.sp` for font sizes
- Replace `Icons.delete_outline_rounded` with `IconsaxBold.trash`
- Keep confirmation dialog logic exactly, just update icon references inside

Run `flutter analyze` to confirm no errors.
  </action>
  <verify>
    <automated>cd /Users/riccardo/Developer/VibeCoding/vocab_flip && flutter pub get && flutter analyze --no-fatal-infos</automated>
  </verify>
  <done>
    - pubspec.yaml has 6 new packages (flutter_animate, google_fonts, flutter_screenutil, shimmer, glassmorphism_ui, iconsax_flutter)
    - lib/theme/app_theme.dart exists with centralized theme, GoogleFonts, glass card helpers
    - main.dart wraps app with ScreenUtilInit and uses AppTheme
    - home_screen.dart uses Iconsax icons, flutter_animate entrance animations, glassmorphism cards, ScreenUtil sizing
    - settings_screen.dart uses Iconsax icons, flutter_animate, glass card styling
    - All existing logic (ProgressService, navigation, CEFR filtering, reset dialog) preserved
    - flutter analyze passes
  </done>
</task>

<task type="auto">
  <name>Task 2: Rewrite game screen, round summary, flip card, and word image with modern UI</name>
  <files>
    lib/screens/game_screen.dart
    lib/screens/round_summary_screen.dart
    lib/widgets/flip_card.dart
    lib/widgets/word_image.dart
  </files>
  <action>
**Step 1: Rewrite lib/widgets/word_image.dart**

PRESERVE ALL LOGIC: `_resolve()`, `_onLoadError()`, `_retriedAfterLoadError`, `didUpdateWidget`, the entire async image loading/retry chain.

Visual changes:
- Import `shimmer`
- Replace `CircularProgressIndicator` loading states with `Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Container(color: Colors.white))` for a polished loading shimmer
- Replace error placeholder icon with Iconsax icon: `IconsaxBold.gallery_slash` or `IconsaxBold.image`
- Keep `ClipRRect` with `borderRadius`, `Image.network` with `loadingBuilder`/`errorBuilder` pattern

**Step 2: Rewrite lib/widgets/flip_card.dart**

CRITICAL PRESERVATION:
- `FlipCardWidget` constructor API (all parameters) MUST remain identical
- `_FlipCardWidgetState` with `SingleTickerProviderStateMixin` MUST remain
- `AnimationController`, `_animation`, `didUpdateWidget` forward/reverse logic MUST remain
- `AnimatedBuilder` with `Matrix4.identity()..setEntry(3,2,0.001)..rotateY(angle)` MUST remain
- `AnswerCapture.of(context)` usage in `_FrontCard` MUST remain
- `_handleSubmit()` logic MUST remain
- `_BackCard` evaluation flow (onEvaluate, onNext, onRetry) MUST remain
- `_DiffVisualization` with DiffOp switch MUST remain
- `_EvalButton` callback pattern MUST remain
- `SpeechUtil.speak()` call MUST remain

Visual changes to `_FrontCard`:
- Use ScreenUtil `.sp` for font sizes
- Italian word text: Apply `GoogleFonts.poppins()` with bold weight
- Text input container: Upgrade frosted glass look using `BackdropFilter` or enhanced opacity layering
- Send button: Replace `Icons.send_rounded` with `IconsaxBold.send_1`
- "Non lo so" button: Slight glass effect styling
- Add subtle `.animate().fadeIn()` on the text overlay column

Visual changes to `_BackCard`:
- Use ScreenUtil `.sp` for font sizes
- English answer text: `GoogleFonts.poppins()` bold
- Grade badge icons: Replace `Icons.check_circle_rounded` with `IconsaxBold.tick_circle`, `Icons.info_rounded` with `IconsaxBold.info_circle`, `Icons.cancel_rounded` with `IconsaxBold.close_circle`
- Audio button: Replace `Icons.volume_up_rounded` with `IconsaxBold.volume_high`
- `_EvalButton` icons: Replace `Icons.close_rounded` with `IconsaxBold.close_circle`, `Icons.check_rounded` with `IconsaxBold.tick_circle`, `Icons.refresh_rounded` with `IconsaxBold.refresh`, `Icons.arrow_forward_rounded` with `IconsaxBold.arrow_right_1`
- Add `.animate().fadeIn(duration: 400.ms)` to the content column when back card appears
- `_DiffVisualization`: Apply glass container styling to the diff box

**Step 3: Rewrite lib/screens/game_screen.dart**

CRITICAL PRESERVATION — ALL of these must remain identical in logic:
- `_GameScreenState` with all fields (_words, _currentIndex, _isFlipped, _evaluated, _cardsPerRound, _progressService, _roundResults, _answerController, _currentMatch)
- `_initService()`, `_precacheUpcoming()`, `_submitAnswer()`, `_evaluate()`, `_nextCard()`, `_retryCard()`, `_showRoundSummary()`, `_hintText` getter
- `AnswerCapture` InheritedWidget class — copy EXACTLY as-is, do not modify
- `resizeToAvoidBottomInset: false`
- `FlipCardWidget` instantiation with all parameters (key, word, themeColor, isFlipped, onTap, onEvaluate, onNext, onRetry, matchResult)
- `ConstrainedBox` with `maxWidth: 360, maxHeight: 480`

Visual changes:
- Import new packages and app_theme
- Replace background gradient with `AppTheme.gradientBackground`
- Header back button: Replace `Icons.arrow_back_rounded` with `IconsaxBold.arrow_left`
- Counter badge: Apply glass styling
- Progress bar: Enhanced styling with rounded ends (already has ClipRRect, keep it)
- Hint text: Use ScreenUtil `.sp` sizing
- Add entrance animation on header: `.animate().fadeIn(duration: 400.ms).slideY(begin: -0.1)`

**Step 4: Rewrite lib/screens/round_summary_screen.dart**

PRESERVE ALL LOGIC: knownPct/uncertainPct/unknownPct calculations, Navigator.pop for home, Navigator.pushReplacement for new round, badge display, _StatCard data display.

Visual changes:
- Import new packages and app_theme
- Replace background with `AppTheme.gradientBackground`
- Trophy icon: Replace `Icons.emoji_events_rounded` with `IconsaxBold.cup`, `Icons.bar_chart_rounded` with `IconsaxBold.chart`
- Title text: `GoogleFonts.poppins()` bold
- `_StatCard`: Apply glass card styling, use ScreenUtil sizing
  - Replace `Icons.check_circle_rounded` with `IconsaxBold.tick_circle`
  - Replace `Icons.help_rounded` with `IconsaxBold.warning_2`
  - Replace `Icons.cancel_rounded` with `IconsaxBold.close_circle`
- Badge container: Glass effect styling
  - Replace `Icons.military_tech_rounded` with `IconsaxBold.medal_star`
- Action buttons: Replace `Icons.home_rounded` with `IconsaxBold.home_2`, `Icons.refresh_rounded` with `IconsaxBold.refresh`
- Add staggered entrance animations:
  - Trophy/title: `.animate().fadeIn(duration: 600.ms).scale(begin: Offset(0.8, 0.8))`
  - Stat cards: `.animate().fadeIn(delay: 200.ms).slideY(begin: 0.2)` staggered
  - Buttons: `.animate().fadeIn(delay: 400.ms)`

Run `flutter analyze` to confirm no errors.
  </action>
  <verify>
    <automated>cd /Users/riccardo/Developer/VibeCoding/vocab_flip && flutter analyze --no-fatal-infos</automated>
  </verify>
  <done>
    - word_image.dart uses shimmer for loading states instead of CircularProgressIndicator
    - flip_card.dart uses Iconsax icons, GoogleFonts, ScreenUtil sizing, glass effects
    - flip_card.dart preserves: FlipCardWidget constructor API, SingleTickerProviderStateMixin animation, AnswerCapture.of(context), all eval/next/retry callbacks
    - game_screen.dart uses Iconsax icons, glass styling, flutter_animate on header
    - game_screen.dart preserves: AnswerCapture InheritedWidget (exact copy), all game logic methods, FlipCardWidget instantiation with all params
    - round_summary_screen.dart uses Iconsax icons, glass cards, staggered animations
    - All navigation (pop, pushReplacement) preserved
    - flutter analyze passes
  </done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>Complete UI rewrite of all screens and widgets using flutter_animate, google_fonts, flutter_screenutil, shimmer, glassmorphism_ui, and iconsax_flutter. All game logic, navigation, and state management preserved.</what-built>
  <how-to-verify>
    1. Run the app: `flutter run` (or `flutter run -d chrome` for web)
    2. HOME SCREEN: Verify smooth entrance animations (title fades in, cards stagger in). Check glassmorphism/frosted card effect on theme cards. Confirm Poppins font is visible. Check Iconsax icons (settings gear, etc). Tap between CEFR levels — filter still works.
    3. GAME SCREEN: Tap a theme card. Verify header animates in. Type an answer and submit — card flips with preserved 3D animation. Check back card shows correct/close/wrong state. Verify eval buttons (Giusta/Sbagliata) work for close matches. Verify Next/Retry buttons work. Complete a round to reach summary.
    4. ROUND SUMMARY: Verify staggered entrance animations. Check stat cards have glass effect. Check badge display if earned. Tap "Home" — returns home. Tap "Nuovo Round" — starts new round.
    5. SETTINGS: Tap settings from home. Verify stats display with glass card. Verify reset button shows confirmation dialog. Cancel dialog, then go back.
    6. LOADING STATES: On flip card front, observe image loading — should show shimmer effect instead of spinner.
    7. RESPONSIVE: If testing on web, resize window — ScreenUtil should handle proportional sizing.
  </how-to-verify>
  <resume-signal>Type "approved" if the UI looks good and all functionality works, or describe any visual issues or broken functionality</resume-signal>
</task>

</tasks>

<verification>
- `flutter pub get` succeeds with all 6 new packages
- `flutter analyze --no-fatal-infos` passes with no errors
- App launches without crashes
- All navigation flows work: Home -> Game -> Summary -> Home, Home -> Settings -> Home
- FlipCard 3D animation works (front -> back flip on answer submit)
- AnswerCapture text input works (type answer, submit, see result)
- Progress tracking works (completion % shown on home cards)
- CEFR filter works (switching levels filters theme cards)
</verification>

<success_criteria>
- All 6 new packages integrated and used meaningfully
- GoogleFonts Poppins applied as primary font
- ScreenUtil responsive sizing on all text and spacing
- flutter_animate entrance animations on all screens
- Shimmer loading states replace all CircularProgressIndicator widgets
- Glassmorphism/glass card effects on theme cards and stat containers
- Iconsax icons replace Material icons throughout
- Zero logic changes — all game mechanics, navigation, state management identical
- flutter analyze passes clean
</success_criteria>

<output>
After completion, create `.planning/quick/1-rewrite-flutter-ui-layer-with-modern-pac/1-SUMMARY.md`
</output>
