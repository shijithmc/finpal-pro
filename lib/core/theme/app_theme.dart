import 'package:flutter/material.dart';

/// FinPal Pro design system.
///
/// Single source of truth for color, typography, shape, and component
/// theming. Light and dark themes are built from the same token set so the
/// two modes never drift (FA-001).
abstract final class AppTheme {
  // ── Design tokens ──────────────────────────────────────────────────────

  /// Brand seed — deep emerald. Money, growth, trust.
  static const Color _seed = Color(0xFF146C43);

  /// Income / positive-delta accent (used by income chips and summaries).
  static const Color incomeGreen = Color(0xFF2E9E5B);

  /// Expense / negative-delta accent.
  static const Color expenseRed = Color(0xFFD64550);

  /// Corner radii — one scale, used everywhere.
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 20;

  /// Gradient for hero surfaces (net worth card, brand mark).
  static LinearGradient heroGradient(ColorScheme scheme) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [scheme.primary, scheme.tertiary],
  );

  // ── Typography ─────────────────────────────────────────────────────────

  static TextTheme _textTheme(TextTheme base) => base.copyWith(
    headlineLarge: base.headlineLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    headlineSmall: base.headlineSmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.25,
    ),
    titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    labelLarge: base.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.25,
    ),
  );

  // ── Theme builders ─────────────────────────────────────────────────────

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      scaffoldBackgroundColor: brightness == Brightness.light
          ? scheme.surfaceContainerLowest
          : scheme.surface,

      // App bar — flat, surface-toned, bold title.
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: brightness == Brightness.light
            ? scheme.surfaceContainerLowest
            : scheme.surface,
        titleTextStyle: _textTheme(
          base.textTheme,
        ).titleLarge?.copyWith(color: scheme.onSurface),
      ),

      // Cards — soft corners, hairline outline instead of shadow.
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .5)),
        ),
        margin: EdgeInsets.zero,
      ),

      // Navigation bar — pill indicator, label always visible.
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 68,
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      // Inputs — consistent radius, filled surface, both modes.
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),

      // Buttons — consistent pill-ish radius and weight.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),

      // Misc surfaces.
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: .5),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
