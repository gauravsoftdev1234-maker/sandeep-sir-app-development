import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

/// Single source of truth for the app's look and feel: one palette, one type
/// scale, and component defaults so screens stay declarative.
class AppTheme {
  const AppTheme._();

  static const String _fontFamily = 'Inter';

  static ThemeData light() => _build(_lightScheme);

  static ThemeData dark() => _build(_darkScheme);

  static final ColorScheme _lightScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.brand,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.brand,
        onPrimary: Colors.white,
        primaryContainer: AppColors.brandSoft,
        onPrimaryContainer: AppColors.brandDeep,
        secondary: AppColors.success,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.successSoft,
        onSecondaryContainer: const Color(0xFF03543F),
        tertiary: AppColors.warning,
        tertiaryContainer: AppColors.warningSoft,
        onTertiaryContainer: const Color(0xFF7C4A03),
        error: AppColors.danger,
        onError: Colors.white,
        errorContainer: const Color(0xFFFDE8E8),
        onErrorContainer: const Color(0xFF9B1C1C),
        surface: AppColors.canvasLight,
        onSurface: AppColors.textLight,
        surfaceContainerLowest: AppColors.surfaceLight,
        surfaceContainerLow: AppColors.surfaceLight,
        surfaceContainer: AppColors.fieldLight,
        surfaceContainerHigh: AppColors.fieldLight,
        onSurfaceVariant: AppColors.mutedLight,
        outline: const Color(0xFFC7CEDB),
        outlineVariant: AppColors.borderLight,
      );

  static final ColorScheme _darkScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.brand,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.brandLight,
        onPrimary: const Color(0xFF07203F),
        primaryContainer: const Color(0xFF1B3A66),
        onPrimaryContainer: const Color(0xFFD8E5F7),
        secondary: const Color(0xFF4ADE9B),
        onSecondary: const Color(0xFF00391F),
        secondaryContainer: const Color(0xFF14432E),
        onSecondaryContainer: const Color(0xFFBBF7D0),
        tertiary: const Color(0xFFFBBF24),
        tertiaryContainer: const Color(0xFF453110),
        onTertiaryContainer: const Color(0xFFFDE68A),
        error: const Color(0xFFF87171),
        onError: const Color(0xFF450A0A),
        errorContainer: const Color(0xFF451A1A),
        onErrorContainer: const Color(0xFFFECACA),
        surface: AppColors.canvasDark,
        onSurface: AppColors.textDark,
        surfaceContainerLowest: AppColors.surfaceDark,
        surfaceContainerLow: AppColors.surfaceDark,
        surfaceContainer: AppColors.fieldDark,
        surfaceContainerHigh: AppColors.fieldDark,
        onSurfaceVariant: AppColors.mutedDark,
        outline: const Color(0xFF3A4459),
        outlineVariant: AppColors.borderDark,
      );

  static ThemeData _build(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final text = _textTheme(scheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: _fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: AppSpacing.page,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        floatingLabelStyle: text.labelLarge?.copyWith(color: scheme.primary),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: _fieldBorder(Colors.transparent),
        enabledBorder: _fieldBorder(Colors.transparent),
        focusedBorder: _fieldBorder(scheme.primary, width: 1.6),
        errorBorder: _fieldBorder(scheme.error),
        focusedErrorBorder: _fieldBorder(scheme.error, width: 1.6),
        errorStyle: text.bodySmall?.copyWith(color: scheme.error),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: text.labelLarge,
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: text.labelLarge,
          foregroundColor: scheme.primary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.primaryContainer,
        checkmarkColor: scheme.onPrimaryContainer,
        side: BorderSide.none,
        labelStyle: text.labelMedium,
        secondaryLabelStyle: text.labelMedium?.copyWith(
          color: scheme.onPrimaryContainer,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: const StadiumBorder(),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        titleTextStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        subtitleTextStyle: text.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        iconColor: scheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sheet),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.textLight,
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainer,
      ),
      // Material 3's forward-fade transition on both platforms keeps screen
      // changes calm and consistent.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.field),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    final onSurface = scheme.onSurface;
    final muted = scheme.onSurfaceVariant;

    return TextTheme(
      displaySmall: TextStyle(
        fontSize: 34,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
        color: onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.7,
        color: onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 23,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 19,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: onSurface),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: onSurface),
      bodySmall: TextStyle(fontSize: 13, height: 1.45, color: muted),
      labelLarge: TextStyle(
        fontSize: 15,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        height: 1.2,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: muted,
      ),
    );
  }
}
