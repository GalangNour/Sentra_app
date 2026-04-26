import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Preset Definitions ───────────────────────────────────────

class ThemePreset {
  final String id;
  final String name;
  final IconData icon;
  final Color background;
  final Color surface;
  final Color surfaceCard;
  final Color surfaceElevated;
  final Color surfaceBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color defaultAccent;

  const ThemePreset({
    required this.id,
    required this.name,
    required this.icon,
    required this.background,
    required this.surface,
    required this.surfaceCard,
    required this.surfaceElevated,
    required this.surfaceBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.defaultAccent,
  });

  static const List<ThemePreset> all = [
    ThemePreset(
      id: 'navy',
      name: 'Navy',
      icon: Icons.water_rounded,
      background: Color(0xFF0E1117),
      surface: Color(0xFF161B27),
      surfaceCard: Color(0xFF1E2535),
      surfaceElevated: Color(0xFF252D42),
      surfaceBorder: Color(0xFF2E3850),
      textPrimary: Color(0xFFF0F4FF),
      textSecondary: Color(0xFF8892B0),
      textMuted: Color(0xFF4A5578),
      defaultAccent: Color(0xFF6C63FF),
    ),
    ThemePreset(
      id: 'amoled',
      name: 'AMOLED',
      icon: Icons.brightness_1_rounded,
      background: Color(0xFF000000),
      surface: Color(0xFF080808),
      surfaceCard: Color(0xFF111111),
      surfaceElevated: Color(0xFF1A1A1A),
      surfaceBorder: Color(0xFF242424),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFF9E9E9E),
      textMuted: Color(0xFF555555),
      defaultAccent: Color(0xFF6C63FF),
    ),
    ThemePreset(
      id: 'midnight',
      name: 'Midnight',
      icon: Icons.nights_stay_rounded,
      background: Color(0xFF0D0B1A),
      surface: Color(0xFF130F26),
      surfaceCard: Color(0xFF1A1535),
      surfaceElevated: Color(0xFF211C40),
      surfaceBorder: Color(0xFF2D2750),
      textPrimary: Color(0xFFF3F0FF),
      textSecondary: Color(0xFF9B92C0),
      textMuted: Color(0xFF4E4870),
      defaultAccent: Color(0xFF9B3FF4),
    ),
    ThemePreset(
      id: 'forest',
      name: 'Forest',
      icon: Icons.park_rounded,
      background: Color(0xFF0A110E),
      surface: Color(0xFF0F1A13),
      surfaceCard: Color(0xFF152019),
      surfaceElevated: Color(0xFF1A2720),
      surfaceBorder: Color(0xFF233328),
      textPrimary: Color(0xFFF0FFF4),
      textSecondary: Color(0xFF86A890),
      textMuted: Color(0xFF3F5445),
      defaultAccent: Color(0xFF00C896),
    ),
    ThemePreset(
      id: 'slate',
      name: 'Slate',
      icon: Icons.layers_rounded,
      background: Color(0xFF0F1117),
      surface: Color(0xFF161A1E),
      surfaceCard: Color(0xFF1E2328),
      surfaceElevated: Color(0xFF252B32),
      surfaceBorder: Color(0xFF2F3640),
      textPrimary: Color(0xFFF0F4FF),
      textSecondary: Color(0xFF8896A8),
      textMuted: Color(0xFF485566),
      defaultAccent: Color(0xFF38BDF8),
    ),
  ];

  static ThemePreset fromId(String id) =>
      all.firstWhere((p) => p.id == id, orElse: () => all[0]);
}

// ─── Accent Choices ───────────────────────────────────────────

class AccentColor {
  final String name;
  final Color color;
  const AccentColor(this.name, this.color);

  static const List<AccentColor> all = [
    AccentColor('Ungu', Color(0xFF6C63FF)),
    AccentColor('Biru', Color(0xFF38BDF8)),
    AccentColor('Cyan', Color(0xFF00E5FF)),
    AccentColor('Hijau', Color(0xFF00C896)),
    AccentColor('Teal', Color(0xFF14B8A6)),
    AccentColor('Oranye', Color(0xFFFF8C42)),
    AccentColor('Pink', Color(0xFFFF6B9D)),
    AccentColor('Merah', Color(0xFFFF6B6B)),
    AccentColor('Indigo', Color(0xFF818CF8)),
    AccentColor('Amber', Color(0xFFFFB547)),
  ];
}

// ─── ThemeConfig singleton ────────────────────────────────────

class ThemeConfig {
  final ThemePreset preset;
  final Color accent;

  const ThemeConfig({required this.preset, required this.accent});

  Color get accentDark => Color.lerp(accent, Colors.black, 0.25)!;
  Color get accentLight => Color.lerp(accent, Colors.white, 0.3)!;

  static ThemeConfig _current = ThemeConfig(
    preset: ThemePreset.all[0],
    accent: ThemePreset.all[0].defaultAccent,
  );

  static ThemeConfig get current => _current;

  static void apply(ThemePreset preset, Color accent) {
    _current = ThemeConfig(preset: preset, accent: accent);
  }
}

// ─── AppColors (dynamic) ──────────────────────────────────────

class AppColors {
  // Accent — changes with user selection
  static Color get primary => ThemeConfig.current.accent;
  static Color get primaryDark => ThemeConfig.current.accentDark;
  static Color get primaryLight => ThemeConfig.current.accentLight;

  // Semantic — fixed
  static const Color income = Color(0xFF00C896);
  static const Color incomeLight = Color(0xFF00F5B4);
  static const Color expense = Color(0xFFFF6B6B);
  static const Color expenseLight = Color(0xFFFF9B9B);
  static const Color warning = Color(0xFFFFB547);
  static const Color info = Color(0xFF38BDF8);

  // Background layers — change with preset
  static Color get background => ThemeConfig.current.preset.background;
  static Color get surface => ThemeConfig.current.preset.surface;
  static Color get surfaceCard => ThemeConfig.current.preset.surfaceCard;
  static Color get surfaceElevated => ThemeConfig.current.preset.surfaceElevated;
  static Color get surfaceBorder => ThemeConfig.current.preset.surfaceBorder;

  // Text — change with preset
  static Color get textPrimary => ThemeConfig.current.preset.textPrimary;
  static Color get textSecondary => ThemeConfig.current.preset.textSecondary;
  static Color get textMuted => ThemeConfig.current.preset.textMuted;

  // Gradients
  static LinearGradient get primaryGradient => LinearGradient(
        colors: [AppColors.primary, AppColors.primaryDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF00C896), Color(0xFF00A878)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFCC4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get balanceGradient => LinearGradient(
        colors: [
          ThemeConfig.current.preset.surfaceCard,
          ThemeConfig.current.preset.surfaceElevated,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

// ─── AppTheme ─────────────────────────────────────────────────

class AppTheme {
  static ThemeData get current {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.income,
        surface: AppColors.surface,
        error: AppColors.expense,
      ),
      textTheme: GoogleFonts.interTextTheme(
        TextTheme(
          headlineLarge: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 28),
          headlineMedium: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 22),
          headlineSmall: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 18),
          titleLarge: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16),
          titleMedium: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 14),
          bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 16),
          bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          bodySmall: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle: TextStyle(color: AppColors.textSecondary),
        hintStyle: TextStyle(color: AppColors.textMuted),
      ),
      useMaterial3: true,
    );
  }

  // alias kept for any remaining references
  static ThemeData get darkTheme => current;
}
