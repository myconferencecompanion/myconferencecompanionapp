import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Official NSE Maiduguri 2026 palette (from planning hub).
class AppColors {
  const AppColors._();

  static const ink = Color(0xFF18201A);
  static const inkSoft = Color(0xFF566057);
  static const navy = Color(0xFF123E73);
  static const navyDark = Color(0xFF0C2A4F);
  static const navySoft = Color(0xFFE6EEF7);
  static const green = Color(0xFF123F2A);
  static const greenSoft = Color(0xFFDFEEE4);
  static const gold = Color(0xFFFFA000);
  static const goldSoft = Color(0xFFFFF4DC);
  static const cream = Color(0xFFFBF7EF);
  static const paper = Color(0xFFF3F4F6);
  static const surface = Color(0xFFFFFFFF);
  static const line = Color(0x24123F2A);
  static const destructive = Color(0xFFC93D2E);
  static const destructiveSoft = Color(0xFFFCECEA);

  // Semantic aliases used across the app
  static const background = paper;
  static const foreground = ink;
  static const primary = navy;
  static const primarySoft = navySoft;
  static const accent = gold;
  static const accentSoft = goldSoft;
  static const muted = Color(0xFFEDEEF1);
  static const mutedForeground = inkSoft;
  static const border = Color(0xFFE7E9EE);
}

class AppSpacing {
  const AppSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const radiusSm = 12.0;
  static const radius = 20.0;
  static const radiusLg = 28.0;
  static const maxContentWidth = 640.0;

  // Standard touch/interaction sizing (Material + HIG).
  static const minTouch = 48.0;
  static const buttonHeight = 54.0;
}

class AppShadows {
  /// Soft, diffuse card shadow (borderless surfaces float on the light bg).
  static List<BoxShadow> get card => [
        BoxShadow(
          color: const Color(0xFF1B2A44).withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: const Color(0xFF1B2A44).withValues(alpha: 0.03),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: const Color(0xFF0C2A4F).withValues(alpha: 0.14),
          blurRadius: 36,
          offset: const Offset(0, 16),
        ),
      ];

  /// Lift for the detached floating navigation pill.
  static List<BoxShadow> get nav => [
        BoxShadow(
          color: const Color(0xFF0C2A4F).withValues(alpha: 0.10),
          blurRadius: 20,
          offset: const Offset(0, -6),
        ),
      ];
}

class AppTheme {
  const AppTheme._();

  /// Bundled font — no network fetch, reliable on weak conference Wi-Fi.
  static const fontFamily = 'PlusJakartaSans';

  static TextTheme _buildTextTheme(TextTheme base) {
    return base
        .apply(fontFamily: fontFamily, bodyColor: AppColors.ink, displayColor: AppColors.ink)
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 40,
            letterSpacing: -1.2,
            height: 1.05,
            color: AppColors.ink,
          ),
          displayMedium: base.displayMedium?.copyWith(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 34,
            letterSpacing: -0.8,
            height: 1.08,
            color: AppColors.ink,
          ),
          displaySmall: base.displaySmall?.copyWith(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 28,
            letterSpacing: -0.5,
            height: 1.12,
            color: AppColors.ink,
          ),
          headlineLarge: base.headlineLarge?.copyWith(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 26,
            letterSpacing: -0.5,
            height: 1.15,
            color: AppColors.ink,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.3,
            height: 1.18,
            color: AppColors.ink,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.2,
            height: 1.2,
            color: AppColors.ink,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.15,
            color: AppColors.ink,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppColors.ink,
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.ink,
          ),
          bodyLarge: base.bodyLarge?.copyWith(
            fontFamily: fontFamily,
            fontSize: 16,
            color: AppColors.ink,
            height: 1.45,
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            fontFamily: fontFamily,
            fontSize: 14,
            color: AppColors.inkSoft,
            height: 1.5,
          ),
          bodySmall: base.bodySmall?.copyWith(
            fontFamily: fontFamily,
            fontSize: 13,
            color: AppColors.inkSoft,
            height: 1.4,
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.1,
          ),
          labelMedium: base.labelMedium?.copyWith(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          labelSmall: base.labelSmall?.copyWith(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 0.9,
            color: AppColors.inkSoft,
          ),
        );
  }

  static ThemeData get light {
    const radius = AppSpacing.radius;
    final textTheme = _buildTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: AppColors.paper,
      textTheme: textTheme,
      colorScheme: const ColorScheme.light(
        primary: AppColors.navy,
        onPrimary: Colors.white,
        secondary: AppColors.gold,
        onSecondary: AppColors.ink,
        tertiary: AppColors.green,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        error: AppColors.destructive,
        outline: AppColors.border,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        hintStyle: textTheme.bodyMedium,
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.navy, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.destructive),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.destructive, width: 1.8),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge?.copyWith(color: Colors.white, fontSize: 15.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          side: const BorderSide(color: AppColors.border),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.navy,
          textStyle: textTheme.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.navySoft,
        selectedColor: AppColors.navy,
        checkmarkColor: Colors.white,
        labelStyle: textTheme.labelLarge!.copyWith(fontSize: 13, color: AppColors.ink),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        elevation: 0,
        backgroundColor: AppColors.surface.withValues(alpha: 0.92),
        indicatorColor: AppColors.navySoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.navy : AppColors.inkSoft,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.navy : AppColors.inkSoft,
            size: 24,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.ink,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.navy,
        unselectedLabelColor: AppColors.inkSoft,
        indicatorColor: AppColors.gold,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600, fontSize: 14),
        dividerColor: AppColors.border,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: AppColors.inkSoft,
      ),
    );
  }

  static LinearGradient get brandGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.navy, AppColors.navyDark, Color(0xFF0A1F38)],
      );

  static LinearGradient get heroSheen => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.gold.withValues(alpha: 0.18),
          Colors.transparent,
          AppColors.green.withValues(alpha: 0.12),
        ],
      );
}
