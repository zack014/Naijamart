
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

/// NaijaMart brand colours shared across the entire application.
class Brand {
  const Brand._();

  static const navy = Color(0xFF071B3B);
  static const navyLight = Color(0xFF102D5B);
  static const navyDark = Color(0xFF041229);

  static const gold = Color(0xFFE6A83A);
  static const goldSoft = Color(0xFFF4C66B);

  // Compatibility aliases for existing screens using the old names.
  static const orange = gold;
  static const orangeDeep = navy;
  static const orangeSoft = goldSoft;

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navyLight, navy],
  );

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, navyDark],
  );

  static const success = Color(0xFF168653);
  static const warning = Color(0xFFE6A83A);
}

class Space {
  const Space._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 28.0;
}

class Radii {
  const Radii._();

  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 22.0;
  static const pill = 999.0;
}

/// Maximum content width for tablets, desktop and web.
const double kMaxContentWidth = 720;

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    const ivory = Color(0xFFFFF9F4);
    const darkBackground = Color(0xFF081426);
    const darkSurface = Color(0xFF11213A);

    final base = ColorScheme.fromSeed(
      seedColor: Brand.navy,
      brightness: brightness,
    );

    final scheme = base.copyWith(
      primary: isDark ? Brand.gold : Brand.navy,
      onPrimary: isDark ? Brand.navyDark : Colors.white,
      secondary: Brand.gold,
      onSecondary: Brand.navyDark,
      tertiary: Brand.navyLight,
      surface: isDark ? darkSurface : Colors.white,
      onSurface: isDark ? const Color(0xFFF7F2EA) : Brand.navyDark,
      surfaceContainerHighest:
          isDark ? const Color(0xFF1B2D47) : const Color(0xFFF3EDE6),
      error: isDark
          ? const Color(0xFFFFB4AB)
          : const Color(0xFFB3261E),
    );

    final background = isDark ? darkBackground : ivory;

    final fieldFill = isDark
        ? const Color(0xFF1B2D47)
        : const Color(0xFFF3EDE6);

    final textTheme = GoogleFonts.dmSansTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: color == Colors.transparent
            ? BorderSide.none
            : BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,

      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
      ),

      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: .6),
          ),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: .6),
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: border(Colors.transparent),
        enabledBorder: border(Colors.transparent),
        focusedBorder: border(scheme.secondary, 1.6),
        errorBorder: border(scheme.error, 1.2),
        focusedErrorBorder: border(scheme.error, 1.6),
        hintStyle: TextStyle(
          color: scheme.onSurfaceVariant,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(64, 48),
          side: BorderSide(
            color: scheme.outline.withValues(alpha: .6),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.secondary.withValues(alpha: .18),
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);

          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected
                ? scheme.primary
                : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);

          return IconThemeData(
            color: selected
                ? scheme.primary
                : scheme.onSurfaceVariant,
          );
        }),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Radii.lg),
          ),
        ),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
