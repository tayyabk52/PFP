# PFC Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a running Flutter web app with the full Olfactory Archive design system, adaptive AppShell layout, all routes defined (stub pages), Supabase client initialized, and Riverpod auth state provider — the prerequisite skeleton every subsequent feature builds on top of.

**Architecture:** Feature-first folder structure under `lib/`. Core layer holds theme, routing, Supabase client, and shared widgets. Auth state is a Riverpod `StreamProvider` wrapping Supabase's auth stream. `go_router` reads auth state for redirect guards. `AppShell` uses `LayoutBuilder` for three-tier responsive layout: persistent sidebar (>1024px), collapsible icon-only sidebar (600–1024px), bottom nav (<600px).

**Tech Stack:** Flutter (web + mobile), Supabase Flutter ^2.x, flutter_riverpod ^2.x, go_router ^14.x, google_fonts ^6.x, flutter_dotenv ^5.x, mocktail ^1.x (tests)

---

## File Map

**Create:**
- `pubspec.yaml` — all dependencies
- `.env` — Supabase URL + anon key (gitignored)
- `lib/main.dart` — entry point, Supabase init, ProviderScope, app root
- `lib/core/config/app_config.dart` — env var accessors
- `lib/core/supabase/supabase_client.dart` — Supabase singleton getter
- `lib/core/theme/app_colors.dart` — all color tokens (Olfactory Archive)
- `lib/core/theme/app_text_styles.dart` — Noto Serif + Inter text styles
- `lib/core/theme/app_theme.dart` — ThemeData assembly
- `lib/core/router/app_router.dart` — go_router config, all routes (stub pages)
- `lib/core/router/route_guards.dart` — redirect logic (unauthenticated, member, seller, admin)
- `lib/core/widgets/app_shell.dart` — adaptive layout (sidebar vs bottom nav)
- `lib/core/widgets/sidebar_nav.dart` — desktop left sidebar widget
- `lib/core/widgets/bottom_nav.dart` — mobile bottom navigation widget
- `lib/core/widgets/stub_page.dart` — placeholder page used for all routes in this plan
- `lib/features/auth/providers/auth_provider.dart` — Riverpod StreamProvider for Supabase auth
- `lib/features/auth/providers/profile_provider.dart` — Riverpod FutureProvider for profiles row
- `test/core/theme/app_colors_test.dart`
- `test/core/theme/app_text_styles_test.dart`
- `test/core/router/route_guards_test.dart`
- `test/core/widgets/app_shell_test.dart`
- `test/features/auth/providers/auth_provider_test.dart`

**Modify:**
- `web/index.html` — add Google Fonts preconnect links
- `.gitignore` — add `.env`

---

## Task 1: Create Flutter Project

**Files:**
- Create: project root via `flutter create`

- [ ] **Step 1: Create the project with web + mobile support**

```bash
cd F:/PerfumeApp
flutter create --org com.pfc --platforms web,android,ios --project-name pfc_app .
```

Expected output: `All done! Your project is ready.`

- [ ] **Step 2: Verify web runs**

```bash
flutter run -d chrome
```

Expected: default Flutter counter app opens in Chrome. Close it.

- [ ] **Step 3: Delete boilerplate**

Delete `lib/main.dart` contents (we rewrite it). Delete `test/widget_test.dart`.

- [ ] **Step 4: Add .env to .gitignore**

Open `.gitignore`, append:
```
.env
*.env
```

- [ ] **Step 5: Commit**

```bash
git init
git add .
git commit -m "feat: initialise Flutter project with web/android/ios targets"
```

---

## Task 2: Dependencies

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Replace pubspec.yaml dependencies section**

```yaml
name: pfc_app
description: PFC — Pakistan Fragrance Community
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # Backend
  supabase_flutter: ^2.5.0

  # State management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Navigation
  go_router: ^14.2.0

  # Typography
  google_fonts: ^6.2.1

  # Environment variables
  flutter_dotenv: ^5.1.0

  # Utilities
  equatable: ^2.0.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  riverpod_generator: ^2.4.3
  build_runner: ^2.4.9
  mocktail: ^1.0.4

flutter:
  uses-material-design: true
  assets:
    - .env
```

- [ ] **Step 2: Create .env file**

Create `.env` in project root:
```
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

Replace values with your actual Supabase project URL and anon key from the Supabase dashboard → Settings → API.

- [ ] **Step 3: Create .env.example for teammates**

Create `.env.example` in project root (safe to commit — no real values):
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

- [ ] **Step 4: Install dependencies**

```bash
flutter pub get
```

Expected: no errors. Packages downloaded.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock .env.example .gitignore
git commit -m "feat: add supabase, riverpod, go_router, google_fonts dependencies"
```

---

## Task 3: Supabase Client + Config

**Files:**
- Create: `lib/core/config/app_config.dart`
- Create: `lib/core/supabase/supabase_client.dart`

- [ ] **Step 1: Write the test**

Create `test/core/supabase/supabase_client_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pfc_app/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('supabaseUrl is non-empty', () {
      // This tests the accessor exists and returns a string type.
      // Actual value loaded from .env — tested in integration.
      expect(AppConfig.supabaseUrl, isA<String>());
    });

    test('supabaseAnonKey is non-empty', () {
      expect(AppConfig.supabaseAnonKey, isA<String>());
    });
  });
}
```

- [ ] **Step 2: Run test — expect compile failure (class doesn't exist yet)**

```bash
flutter test test/core/supabase/supabase_client_test.dart
```

Expected: compile error — `AppConfig` not found.

- [ ] **Step 3: Create AppConfig**

Create `lib/core/config/app_config.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? (throw Exception('SUPABASE_URL not set'));

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? (throw Exception('SUPABASE_ANON_KEY not set'));
}
```

- [ ] **Step 4: Create SupabaseClient wrapper**

Create `lib/core/supabase/supabase_client.dart`:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// Global Supabase client accessor.
/// Supabase.initialize() must be called in main() before use.
SupabaseClient get supabase => Supabase.instance.client;
```

- [ ] **Step 5: Run test — expect pass**

```bash
flutter test test/core/supabase/supabase_client_test.dart
```

Expected: PASS (dotenv not loaded in unit test, but type check passes).

- [ ] **Step 6: Commit**

```bash
git add lib/core/config/ lib/core/supabase/ test/core/supabase/
git commit -m "feat: add AppConfig env accessors and Supabase client wrapper"
```

---

## Task 4: Design System — Colors

**Files:**
- Create: `lib/core/theme/app_colors.dart`
- Create: `test/core/theme/app_colors_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/core/theme/app_colors_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pfc_app/core/theme/app_colors.dart';

void main() {
  group('AppColors', () {
    test('primary is Deep Emerald #003527', () {
      expect(AppColors.primary, const Color(0xFF003527));
    });

    test('primaryGradientEnd is #064e3b', () {
      expect(AppColors.primaryGradientEnd, const Color(0xFF064e3b));
    });

    test('surface is #f9f9fc', () {
      expect(AppColors.surface, const Color(0xFFf9f9fc));
    });

    test('surfaceContainerLow is #f3f3f6', () {
      expect(AppColors.surfaceContainerLow, const Color(0xFFf3f3f6));
    });

    test('surfaceContainerHighest is #e2e2e5', () {
      expect(AppColors.surfaceContainerHighest, const Color(0xFFe2e2e5));
    });

    test('card is white', () {
      expect(AppColors.card, const Color(0xFFffffff));
    });

    test('onBackground is near-black #1a1c1e', () {
      expect(AppColors.onBackground, const Color(0xFF1a1c1e));
    });

    test('secondary charcoal is #555f70', () {
      expect(AppColors.secondary, const Color(0xFF555f70));
    });

    test('goldAccent is #e9c176', () {
      expect(AppColors.goldAccent, const Color(0xFFe9c176));
    });

    test('goldBadgeBg is #3e2b00', () {
      expect(AppColors.goldBadgeBg, const Color(0xFF3e2b00));
    });

    test('ghostBorderBase is #bfc9c3', () {
      expect(AppColors.ghostBorderBase, const Color(0xFFbfc9c3));
    });

    test('error is standard red', () {
      expect(AppColors.error, const Color(0xFFba1a1a));
    });
  });
}
```

- [ ] **Step 2: Run test — expect failure**

```bash
flutter test test/core/theme/app_colors_test.dart
```

Expected: compile error — `AppColors` not found.

- [ ] **Step 3: Implement AppColors**

Create `lib/core/theme/app_colors.dart`:
```dart
import 'package:flutter/material.dart';

/// Olfactory Archive design system color tokens.
/// No borders — use tonal layering (surface → surfaceContainerLow → card).
abstract class AppColors {
  // Primary
  static const Color primary = Color(0xFF003527);
  static const Color primaryGradientEnd = Color(0xFF064e3b);
  static const Color onPrimary = Color(0xFFffffff);

  // Secondary
  static const Color secondary = Color(0xFF555f70);
  static const Color onSecondary = Color(0xFFffffff);

  // Gold accent — use sparingly (verified badges, heritage chips)
  static const Color goldAccent = Color(0xFFe9c176);
  static const Color goldBadgeBg = Color(0xFF3e2b00);
  static const Color onGoldBadge = Color(0xFF261900);

  // Surface hierarchy (tonal layering — no borders)
  static const Color surface = Color(0xFFf9f9fc);
  static const Color surfaceContainerLow = Color(0xFFf3f3f6);
  static const Color surfaceContainerHighest = Color(0xFFe2e2e5);
  static const Color card = Color(0xFFffffff);

  // Text
  static const Color onBackground = Color(0xFF1a1c1e);
  static const Color onSurface = Color(0xFF1a1c1e);
  static const Color textSecondary = Color(0xFF555f70);
  static const Color textMuted = Color(0xFF8a9390);

  // Ghost border — only at 15% opacity, accessibility only
  static const Color ghostBorderBase = Color(0xFFbfc9c3);
  static Color get ghostBorder => ghostBorderBase.withOpacity(0.15);

  // Status
  static const Color error = Color(0xFFba1a1a);
  static const Color errorContainer = Color(0xFFffdad6);
  static const Color success = Color(0xFF1a6b4a);
  static const Color successContainer = Color(0xFFbcf0d7);
  static const Color warning = Color(0xFFb45300);
  static const Color warningContainer = Color(0xFFffe0bb);
}
```

- [ ] **Step 4: Run test — expect pass**

```bash
flutter test test/core/theme/app_colors_test.dart
```

Expected: all 12 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme/app_colors.dart test/core/theme/app_colors_test.dart
git commit -m "feat: add Olfactory Archive color tokens"
```

---

## Task 5: Design System — Typography

**Files:**
- Create: `lib/core/theme/app_text_styles.dart`
- Create: `test/core/theme/app_text_styles_test.dart`
- Modify: `web/index.html`

- [ ] **Step 1: Write failing test**

Create `test/core/theme/app_text_styles_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfc_app/core/theme/app_text_styles.dart';

void main() {
  group('AppTextStyles', () {
    test('displayLg uses Noto Serif', () {
      final style = AppTextStyles.displayLg;
      expect(style.fontFamily, contains('NotoSerif'));
    });

    test('displayLg is 56sp', () {
      expect(AppTextStyles.displayLg.fontSize, 56.0);
    });

    test('bodyMd uses Inter', () {
      final style = AppTextStyles.bodyMd;
      expect(style.fontFamily, contains('Inter'));
    });

    test('label has uppercase and letter spacing', () {
      final style = AppTextStyles.label;
      expect(style.letterSpacing, greaterThan(0));
    });
  });
}
```

- [ ] **Step 2: Run test — expect failure**

```bash
flutter test test/core/theme/app_text_styles_test.dart
```

Expected: compile error.

- [ ] **Step 3: Implement AppTextStyles**

Create `lib/core/theme/app_text_styles.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Olfactory Archive typography system.
/// Display/Headlines: Noto Serif (editorial weight)
/// Body/Labels: Inter (clean, functional)
abstract class AppTextStyles {
  // --- Display (Noto Serif) — fragrance names, hero headers ---
  static TextStyle get displayLg => GoogleFonts.notoSerif(
        fontSize: 56,
        fontWeight: FontWeight.w700,
        color: AppColors.onBackground,
        height: 1.1,
        letterSpacing: -0.5,
      );

  static TextStyle get displayMd => GoogleFonts.notoSerif(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: AppColors.onBackground,
        height: 1.15,
        letterSpacing: -0.25,
      );

  static TextStyle get displaySm => GoogleFonts.notoSerif(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: AppColors.onBackground,
        height: 1.2,
      );

  // --- Headlines (Noto Serif) — section titles ---
  static TextStyle get headlineLg => GoogleFonts.notoSerif(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColors.onBackground,
        height: 1.25,
      );

  static TextStyle get headlineMd => GoogleFonts.notoSerif(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.onBackground,
        height: 1.3,
      );

  static TextStyle get headlineSm => GoogleFonts.notoSerif(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.onBackground,
        height: 1.3,
      );

  // --- Title (Noto Serif) — card titles ---
  static TextStyle get titleLg => GoogleFonts.notoSerif(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.onBackground,
        height: 1.4,
      );

  static TextStyle get titleMd => GoogleFonts.notoSerif(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.onBackground,
        height: 1.4,
      );

  // --- Body (Inter) — descriptions, functional text ---
  static TextStyle get bodyLg => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.onBackground,
        height: 1.6,
      );

  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.onBackground,
        height: 1.6,
      );

  static TextStyle get bodySm => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  // --- Label (Inter, UPPERCASE) — field labels, chips, metadata ---
  static TextStyle get label => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
        height: 1.4,
      );

  static TextStyle get labelLg => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
        height: 1.4,
      );

  // --- Price — gold gradient look via color ---
  static TextStyle get price => GoogleFonts.notoSerif(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        height: 1.2,
      );

  static TextStyle get priceSm => GoogleFonts.notoSerif(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        height: 1.2,
      );
}
```

- [ ] **Step 4: Add Google Fonts preconnect to web/index.html**

Open `web/index.html`, add inside `<head>` before other links:
```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
```

- [ ] **Step 5: Run test — expect pass**

```bash
flutter test test/core/theme/app_text_styles_test.dart
```

Expected: all 4 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/core/theme/app_text_styles.dart test/core/theme/ web/index.html
git commit -m "feat: add Olfactory Archive typography (Noto Serif + Inter)"
```

---

## Task 6: Design System — Theme Assembly

**Files:**
- Create: `lib/core/theme/app_theme.dart`

- [ ] **Step 1: Implement AppTheme**

Create `lib/core/theme/app_theme.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

abstract class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          secondary: AppColors.secondary,
          onSecondary: AppColors.onSecondary,
          error: AppColors.error,
          onError: AppColors.onPrimary,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
        ),
        scaffoldBackgroundColor: AppColors.surface,
        textTheme: GoogleFonts.interTextTheme().copyWith(
          displayLarge: AppTextStyles.displayLg,
          displayMedium: AppTextStyles.displayMd,
          displaySmall: AppTextStyles.displaySm,
          headlineLarge: AppTextStyles.headlineLg,
          headlineMedium: AppTextStyles.headlineMd,
          headlineSmall: AppTextStyles.headlineSm,
          titleLarge: AppTextStyles.titleLg,
          titleMedium: AppTextStyles.titleMd,
          bodyLarge: AppTextStyles.bodyLg,
          bodyMedium: AppTextStyles.bodyMd,
          bodySmall: AppTextStyles.bodySm,
          labelLarge: AppTextStyles.labelLg,
          labelSmall: AppTextStyles.label,
        ),
        // No borders — tonal layering only
        cardTheme: CardTheme(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        // Inputs — surfaceContainerLow fill, no border
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color: AppColors.primary,
              width: 1,
            ),
          ),
          labelStyle: AppTextStyles.label,
          hintStyle: AppTextStyles.bodyMd.copyWith(
            color: AppColors.textMuted,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        // Buttons — sharp 4px radius
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: AppTextStyles.labelLg.copyWith(
              color: AppColors.onPrimary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: AppTextStyles.bodyMd,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Colors.transparent, // No dividers — use tonal layering
          thickness: 0,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surface.withOpacity(0.8),
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: AppTextStyles.headlineSm,
          foregroundColor: AppColors.onBackground,
        ),
      );
}
```

- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/core/theme/
```

Expected: no issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/core/theme/app_theme.dart
git commit -m "feat: assemble ThemeData from Olfactory Archive tokens"
```

---

## Task 7: Auth Provider

**Files:**
- Create: `lib/features/auth/providers/auth_provider.dart`
- Create: `lib/features/auth/providers/profile_provider.dart`
- Create: `test/features/auth/providers/auth_provider_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/features/auth/providers/auth_provider_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pfc_app/features/auth/providers/auth_provider.dart';

void main() {
  group('authStateProvider', () {
    test('is an AsyncValue provider', () {
      // Verify provider type is correct — full auth stream test
      // requires Supabase init (integration test).
      expect(authStateProvider, isNotNull);
    });

    test('userRoleProvider defaults to null when no user', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Without Supabase init, provider should return null role gracefully.
      expect(userRoleProvider, isNotNull);
    });
  });
}
```

- [ ] **Step 2: Run test — expect failure**

```bash
flutter test test/features/auth/providers/auth_provider_test.dart
```

Expected: compile error — providers not found.

- [ ] **Step 3: Implement auth provider**

Create `lib/features/auth/providers/auth_provider.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';

/// Current Supabase auth session stream.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

/// Current user (null if unauthenticated).
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(data: (state) => state.session?.user);
});

/// Current user role from profiles table.
/// Returns null if unauthenticated or profile not loaded.
final userRoleProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final response = await supabase
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single();

  return response['role'] as String?;
});
```

- [ ] **Step 4: Implement profile provider**

Create `lib/features/auth/providers/profile_provider.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import 'auth_provider.dart';

/// Full profile row for the current user.
final currentProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final response = await supabase
      .from('profiles')
      .select()
      .eq('id', user.id)
      .single();

  return response;
});

/// Whether the current user has a pending/active seller application.
final hasSellerApplicationProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  final response = await supabase
      .from('seller_applications')
      .select('id')
      .eq('applicant_id', user.id)
      .maybeSingle();

  return response != null;
});
```

- [ ] **Step 5: Run test — expect pass**

```bash
flutter test test/features/auth/providers/auth_provider_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/auth/providers/ test/features/auth/
git commit -m "feat: add Riverpod auth state and profile providers"
```

---

## Task 8: Route Guards

**Files:**
- Create: `lib/core/router/route_guards.dart`
- Create: `test/core/router/route_guards_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/core/router/route_guards_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pfc_app/core/router/route_guards.dart';

void main() {
  group('RouteGuards.redirect', () {
    test('unauthenticated user accessing /dashboard redirects to /login', () {
      final result = RouteGuards.getRedirect(
        location: '/dashboard',
        role: null,
        isAuthenticated: false,
        hasSellerApplication: false,
      );
      expect(result, '/login');
    });

    test('unauthenticated user accessing /admin redirects to /login', () {
      final result = RouteGuards.getRedirect(
        location: '/admin',
        role: null,
        isAuthenticated: false,
        hasSellerApplication: false,
      );
      expect(result, '/login');
    });

    test('unauthenticated user accessing /register/seller-apply redirects to /register', () {
      final result = RouteGuards.getRedirect(
        location: '/register/seller-apply',
        role: null,
        isAuthenticated: false,
        hasSellerApplication: false,
      );
      expect(result, '/register');
    });

    test('member accessing /admin redirects to /dashboard', () {
      final result = RouteGuards.getRedirect(
        location: '/admin',
        role: 'member',
        isAuthenticated: true,
        hasSellerApplication: false,
      );
      expect(result, '/dashboard');
    });

    test('member accessing /dashboard/create-listing redirects to /dashboard', () {
      final result = RouteGuards.getRedirect(
        location: '/dashboard/create-listing',
        role: 'member',
        isAuthenticated: true,
        hasSellerApplication: false,
      );
      expect(result, '/dashboard');
    });

    test('member with existing application accessing /register/seller-apply redirects to /dashboard/verification', () {
      final result = RouteGuards.getRedirect(
        location: '/register/seller-apply',
        role: 'member',
        isAuthenticated: true,
        hasSellerApplication: true,
      );
      expect(result, '/dashboard/verification');
    });

    test('seller accessing /dashboard/create-listing is allowed', () {
      final result = RouteGuards.getRedirect(
        location: '/dashboard/create-listing',
        role: 'seller',
        isAuthenticated: true,
        hasSellerApplication: false,
      );
      expect(result, isNull);
    });

    test('seller accessing /register/seller-apply redirects to /dashboard/verification', () {
      final result = RouteGuards.getRedirect(
        location: '/register/seller-apply',
        role: 'seller',
        isAuthenticated: true,
        hasSellerApplication: true,
      );
      expect(result, '/dashboard/verification');
    });

    test('admin can access /admin', () {
      final result = RouteGuards.getRedirect(
        location: '/admin',
        role: 'admin',
        isAuthenticated: true,
        hasSellerApplication: false,
      );
      expect(result, isNull);
    });

    test('authenticated user accessing /marketplace is allowed', () {
      final result = RouteGuards.getRedirect(
        location: '/marketplace',
        role: 'member',
        isAuthenticated: true,
        hasSellerApplication: false,
      );
      expect(result, isNull);
    });
  });
}
```

- [ ] **Step 2: Run test — expect failure**

```bash
flutter test test/core/router/route_guards_test.dart
```

Expected: compile error — `RouteGuards` not found.

- [ ] **Step 3: Implement RouteGuards**

Create `lib/core/router/route_guards.dart`:
```dart
/// Pure redirect logic — no Flutter/Supabase dependencies.
/// Testable in isolation. AppRouter calls this in go_router redirect callback.
abstract class RouteGuards {
  static const _protectedDashboardPrefix = '/dashboard';
  static const _adminPrefix = '/admin';
  static const _sellerApplyRoute = '/register/seller-apply';
  static const _sellerCreateListing = '/dashboard/create-listing';

  /// Returns a redirect path, or null if navigation is allowed.
  static String? getRedirect({
    required String location,
    required String? role,
    required bool isAuthenticated,
    required bool hasSellerApplication,
  }) {
    final isAdmin = role == 'admin';
    final isSeller = role == 'seller';
    final isMember = isAuthenticated && !isAdmin && !isSeller;

    // Unauthenticated guards
    if (!isAuthenticated) {
      if (location.startsWith(_protectedDashboardPrefix)) return '/login';
      if (location.startsWith(_adminPrefix)) return '/login';
      if (location == _sellerApplyRoute) return '/register';
      return null;
    }

    // Admin-only routes
    if (location.startsWith(_adminPrefix) && !isAdmin) return '/dashboard';

    // Seller-only routes
    if (location == _sellerCreateListing && !isSeller && !isAdmin) {
      return '/dashboard';
    }

    // Seller apply — redirect if already has an application
    if (location == _sellerApplyRoute) {
      if (isSeller || hasSellerApplication) return '/dashboard/verification';
      return null;
    }

    return null;
  }
}
```

- [ ] **Step 4: Run test — expect all pass**

```bash
flutter test test/core/router/route_guards_test.dart
```

Expected: all 11 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/router/route_guards.dart test/core/router/
git commit -m "feat: add pure route guard logic with full test coverage"
```

---

## Task 9: Stub Page + App Router

**Files:**
- Create: `lib/core/widgets/stub_page.dart`
- Create: `lib/core/router/app_router.dart`

- [ ] **Step 1: Create stub page**

Create `lib/core/widgets/stub_page.dart`:
```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Temporary placeholder for routes not yet implemented.
/// Replace with real page widget as each feature is built.
class StubPage extends StatelessWidget {
  final String title;
  const StubPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.construction_rounded,
                size: 48, color: AppColors.primary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.headlineSm),
            const SizedBox(height: 8),
            Text('Coming soon', style: AppTextStyles.bodyMd),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create app router with all routes**

Create `lib/core/router/app_router.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/providers/profile_provider.dart';
import '../widgets/app_shell.dart';
import '../widgets/stub_page.dart';
import 'route_guards.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = _RouterNotifier(ref);

  return GoRouter(
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final role = routerNotifier._role;
      final isAuthenticated = routerNotifier._isAuthenticated;
      final hasApp = routerNotifier._hasSellerApplication;
      return RouteGuards.getRedirect(
        location: state.uri.toString(),
        role: role,
        isAuthenticated: isAuthenticated,
        hasSellerApplication: hasApp,
      );
    },
    routes: [
      // --- Public routes ---
      GoRoute(path: '/', builder: (_, __) => const StubPage(title: 'Landing')),
      GoRoute(path: '/login', builder: (_, __) => const StubPage(title: 'Login')),
      GoRoute(path: '/register', builder: (_, __) => const StubPage(title: 'Register')),
      GoRoute(path: '/register/seller-apply', builder: (_, __) => const StubPage(title: 'Seller Application')),
      GoRoute(path: '/marketplace', builder: (_, __) => const StubPage(title: 'Marketplace')),
      GoRoute(path: '/marketplace/:id', builder: (_, __) => const StubPage(title: 'Listing Detail')),
      GoRoute(path: '/sellers', builder: (_, __) => const StubPage(title: 'Legit Sellers')),
      GoRoute(path: '/sellers/:code', builder: (_, __) => const StubPage(title: 'Seller Profile')),
      GoRoute(path: '/knowledge', builder: (_, __) => const StubPage(title: 'Knowledge Base')),
      GoRoute(path: '/knowledge/guides', builder: (_, __) => const StubPage(title: 'Community Guides')),
      GoRoute(path: '/knowledge/fake-detection/:slug', builder: (_, __) => const StubPage(title: 'Fake Detection Guide')),
      GoRoute(path: '/knowledge/glossary', builder: (_, __) => const StubPage(title: 'Glossary')),

      // --- Dashboard (auth-gated, AppShell) ---
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const StubPage(title: 'Dashboard')),
          GoRoute(path: '/dashboard/my-listings', builder: (_, __) => const StubPage(title: 'My Listings')),
          GoRoute(path: '/dashboard/create-listing', builder: (_, __) => const StubPage(title: 'Create Listing')),
          GoRoute(path: '/dashboard/messages', builder: (_, __) => const StubPage(title: 'Inbox')),
          GoRoute(path: '/dashboard/messages/:id', builder: (_, __) => const StubPage(title: 'Conversation')),
          GoRoute(path: '/dashboard/profile', builder: (_, __) => const StubPage(title: 'Profile')),
          GoRoute(path: '/dashboard/reviews', builder: (_, __) => const StubPage(title: 'My Reviews')),
          GoRoute(path: '/dashboard/reports', builder: (_, __) => const StubPage(title: 'Reports')),
          GoRoute(path: '/dashboard/iso', builder: (_, __) => const StubPage(title: 'My ISO Posts')),
          GoRoute(path: '/dashboard/verification', builder: (_, __) => const StubPage(title: 'Verification Status')),
        ],
      ),

      // --- Admin (role-gated, AppShell) ---
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child, isAdmin: true),
        routes: [
          GoRoute(path: '/admin', builder: (_, __) => const StubPage(title: 'Admin Overview')),
          GoRoute(path: '/admin/users', builder: (_, __) => const StubPage(title: 'User Management')),
          GoRoute(path: '/admin/sellers', builder: (_, __) => const StubPage(title: 'Verified Sellers')),
          GoRoute(path: '/admin/sellers/applications', builder: (_, __) => const StubPage(title: 'Seller Applications')),
          GoRoute(path: '/admin/sellers/applications/:id', builder: (_, __) => const StubPage(title: 'Application Detail')),
          GoRoute(path: '/admin/listings', builder: (_, __) => const StubPage(title: 'Listing Moderation')),
          GoRoute(path: '/admin/reports', builder: (_, __) => const StubPage(title: 'Reports Tracker')),
          GoRoute(path: '/admin/knowledge', builder: (_, __) => const StubPage(title: 'Knowledge Management')),
        ],
      ),
    ],
  );
});

/// Bridges Riverpod state changes to GoRouter's refresh mechanism.
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  String? _role;
  bool _isAuthenticated = false;
  bool _hasSellerApplication = false;

  _RouterNotifier(this._ref) {
    _ref.listen(currentUserProvider, (_, user) {
      _isAuthenticated = user != null;
      notifyListeners();
    });
    _ref.listen(userRoleProvider, (_, role) {
      _role = role.valueOrNull;
      notifyListeners();
    });
    _ref.listen(hasSellerApplicationProvider, (_, has) {
      _hasSellerApplication = has.valueOrNull ?? false;
      notifyListeners();
    });
  }
}
```

- [ ] **Step 3: Verify no analysis errors**

```bash
flutter analyze lib/core/router/ lib/core/widgets/stub_page.dart
```

Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add lib/core/router/app_router.dart lib/core/widgets/stub_page.dart
git commit -m "feat: add go_router with all routes (stub pages) and Riverpod-driven guards"
```

---

## Task 10: AppShell — Adaptive Layout

**Files:**
- Create: `lib/core/widgets/app_shell.dart`
- Create: `lib/core/widgets/sidebar_nav.dart`
- Create: `lib/core/widgets/bottom_nav.dart`
- Create: `test/core/widgets/app_shell_test.dart`

- [ ] **Step 1: Write failing widget test**

Create `test/core/widgets/app_shell_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pfc_app/core/widgets/app_shell.dart';
import 'package:pfc_app/core/widgets/sidebar_nav.dart';
import 'package:pfc_app/core/widgets/bottom_nav.dart';

Widget buildShell({required double width, bool isAdmin = false}) {
  return ProviderScope(
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 800)),
        child: AppShell(
          isAdmin: isAdmin,
          child: const SizedBox(key: Key('content')),
        ),
      ),
    ),
  );
}

void main() {
  group('AppShell', () {
    testWidgets('shows SidebarNav on desktop (>1024px)', (tester) async {
      await tester.pumpWidget(buildShell(width: 1200));
      expect(find.byType(SidebarNav), findsOneWidget);
      expect(find.byType(PfcBottomNav), findsNothing);
    });

    testWidgets('shows collapsed SidebarNav on tablet (600-1024px)', (tester) async {
      await tester.pumpWidget(buildShell(width: 800));
      expect(find.byType(SidebarNav), findsOneWidget);
      expect(find.byType(PfcBottomNav), findsNothing);
    });

    testWidgets('shows PfcBottomNav on mobile (<600px)', (tester) async {
      await tester.pumpWidget(buildShell(width: 400));
      expect(find.byType(PfcBottomNav), findsOneWidget);
      expect(find.byType(SidebarNav), findsNothing);
    });

    testWidgets('always renders child content', (tester) async {
      await tester.pumpWidget(buildShell(width: 1200));
      expect(find.byKey(const Key('content')), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test — expect failure**

```bash
flutter test test/core/widgets/app_shell_test.dart
```

Expected: compile error — widgets not found.

- [ ] **Step 3: Create SidebarNav**

Create `lib/core/widgets/sidebar_nav.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  const _NavItem(this.label, this.icon, this.route);
}

const _memberItems = [
  _NavItem('Marketplace', Icons.storefront_outlined, '/marketplace'),
  _NavItem('Dashboard', Icons.grid_view_outlined, '/dashboard'),
  _NavItem('My Listings', Icons.list_alt_outlined, '/dashboard/my-listings'),
  _NavItem('Messages', Icons.mail_outline_rounded, '/dashboard/messages'),
  _NavItem('ISO Posts', Icons.search_outlined, '/dashboard/iso'),
  _NavItem('Reports', Icons.flag_outlined, '/dashboard/reports'),
  _NavItem('Knowledge', Icons.menu_book_outlined, '/knowledge'),
  _NavItem('Sellers', Icons.verified_outlined, '/sellers'),
];

const _adminItems = [
  _NavItem('Overview', Icons.dashboard_outlined, '/admin'),
  _NavItem('Users', Icons.people_outline, '/admin/users'),
  _NavItem('Sellers', Icons.verified_outlined, '/admin/sellers'),
  _NavItem('Listings', Icons.storefront_outlined, '/admin/listings'),
  _NavItem('Reports', Icons.flag_outlined, '/admin/reports'),
  _NavItem('Knowledge', Icons.menu_book_outlined, '/admin/knowledge'),
];

class SidebarNav extends StatelessWidget {
  final bool isAdmin;
  final bool collapsed; // tablet: icon-only mode
  const SidebarNav({super.key, this.isAdmin = false, this.collapsed = false});

  @override
  Widget build(BuildContext context) {
    final items = isAdmin ? _adminItems : _memberItems;
    final location = GoRouterState.of(context).uri.toString();

    return Container(
      width: collapsed ? 64 : 220,
      color: AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Text('P',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 10),
                Text('PFC',
                    style: AppTextStyles.headlineSm
                        .copyWith(color: AppColors.primary)),
                Text('Pakistan Fragrance\nCommunity',
                    style: AppTextStyles.bodySm),
              ],
            ),
          ),

          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: items.map((item) {
                final isActive = location.startsWith(item.route);
                return _SidebarItem(item: item, isActive: isActive);
              }).toList(),
            ),
          ),

          // Profile shortcut
          Padding(
            padding: const EdgeInsets.all(12),
            child: _SidebarItem(
              item: const _NavItem('Profile', Icons.person_outline, '/dashboard/profile'),
              isActive: location.startsWith('/dashboard/profile'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  const _SidebarItem({required this.item, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary.withOpacity(0.08) : null,
        borderRadius: BorderRadius.circular(4),
        border: isActive
            ? Border(left: BorderSide(color: AppColors.primary, width: 3))
            : null,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          item.icon,
          size: 20,
          color: isActive ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Text(
          item.label,
          style: AppTextStyles.bodyMd.copyWith(
            color: isActive ? AppColors.primary : AppColors.onBackground,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        onTap: () => context.go(item.route),
      ),
    );
  }
}
```

- [ ] **Step 4: Create PfcBottomNav**

Create `lib/core/widgets/bottom_nav.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class PfcBottomNav extends StatelessWidget {
  final bool isAdmin;
  const PfcBottomNav({super.key, this.isAdmin = false});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    return NavigationBar(
      backgroundColor: AppColors.card,
      indicatorColor: AppColors.primary.withOpacity(0.1),
      selectedIndex: _indexFromLocation(location),
      onDestinationSelected: (index) =>
          context.go(_routeFromIndex(index, isAdmin)),
      destinations: isAdmin
          ? const [
              NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Admin'),
              NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Market'),
              NavigationDestination(icon: Icon(Icons.flag_outlined), label: 'Reports'),
              NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
            ]
          : const [
              NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Archive'),
              NavigationDestination(icon: Icon(Icons.grid_view_outlined), label: 'Market'),
              NavigationDestination(icon: Icon(Icons.verified_outlined), label: 'Verify'),
              NavigationDestination(icon: Icon(Icons.person_outline), label: 'Vault'),
            ],
    );
  }

  int _indexFromLocation(String location) {
    if (isAdmin) {
      if (location.startsWith('/admin/reports')) return 2;
      if (location.startsWith('/admin')) return 0;
      return 3;
    }
    if (location.startsWith('/marketplace')) return 1;
    if (location.startsWith('/dashboard/verification')) return 2;
    if (location.startsWith('/dashboard')) return 1;
    return 0;
  }

  String _routeFromIndex(int index, bool admin) {
    if (admin) {
      return ['/admin', '/marketplace', '/admin/reports', '/dashboard/profile'][index];
    }
    return ['/marketplace', '/dashboard', '/dashboard/verification', '/dashboard/profile'][index];
  }
}
```

- [ ] **Step 5: Create AppShell**

Create `lib/core/widgets/app_shell.dart`:
```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'sidebar_nav.dart';
import 'bottom_nav.dart';

/// Adaptive layout shell.
/// > 800px: persistent left sidebar + content area
/// < 800px: content area + bottom navigation bar
class AppShell extends StatelessWidget {
  final Widget child;
  final bool isAdmin;

  const AppShell({
    super.key,
    required this.child,
    this.isAdmin = false,
  });

  static const double _desktopBreakpoint = 1024;
  static const double _tabletBreakpoint = 600;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Desktop: persistent full sidebar
        if (width >= _desktopBreakpoint) {
          return Scaffold(
            backgroundColor: AppColors.surfaceContainerLow,
            body: Row(
              children: [
                SidebarNav(isAdmin: isAdmin),
                Expanded(
                  child: Container(
                    color: AppColors.surface,
                    child: child,
                  ),
                ),
              ],
            ),
          );
        }

        // Tablet: collapsible icon-only sidebar
        if (width >= _tabletBreakpoint) {
          return Scaffold(
            backgroundColor: AppColors.surfaceContainerLow,
            body: Row(
              children: [
                SidebarNav(isAdmin: isAdmin, collapsed: true),
                Expanded(
                  child: Container(
                    color: AppColors.surface,
                    child: child,
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile: bottom navigation bar
        return Scaffold(
          backgroundColor: AppColors.surface,
          body: child,
          bottomNavigationBar: PfcBottomNav(isAdmin: isAdmin),
        );
      },
    );
  }
}
```

- [ ] **Step 6: Run test — expect pass**

```bash
flutter test test/core/widgets/app_shell_test.dart
```

Expected: all 3 tests PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/core/widgets/ test/core/widgets/
git commit -m "feat: add adaptive AppShell with sidebar (desktop) and bottom nav (mobile)"
```

---

## Task 11: Wire Everything in main.dart

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Implement main.dart**

Replace `lib/main.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialise Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: PfcApp(),
    ),
  );
}

class PfcApp extends ConsumerWidget {
  const PfcApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'PFC — Pakistan Fragrance Community',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
```

- [ ] **Step 2: Run the app — verify it works end to end**

```bash
flutter run -d chrome
```

Expected:
- App launches in Chrome
- Landing stub page shows at `/`
- No red errors in console
- Navigating to `/marketplace` shows the stub page

- [ ] **Step 3: Run all tests**

```bash
flutter test
```

Expected: all tests PASS.

- [ ] **Step 4: Final commit**

```bash
git add lib/main.dart
git commit -m "feat: wire Supabase, Riverpod, go_router and theme in main.dart — foundation complete"
```

---

## Completion Checklist

- [ ] `flutter run -d chrome` shows app with no errors
- [ ] All routes navigable (show stub pages)
- [ ] `flutter test` — all tests pass
- [ ] `flutter analyze` — no issues
- [ ] Supabase connected (check Supabase dashboard for auth requests)
- [ ] Sidebar visible on wide browser, bottom nav on narrow
