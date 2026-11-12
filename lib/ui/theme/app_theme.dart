import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF1DB954); // Spotify Green
  static const Color primaryBright = Color(0xFF1ED760);
  static const Color background = Color(0xFF121212); // Deep Spotify Black
  static const Color surface = Color(0xFF181818);
  static const Color surfaceElevated = Color(0xFF242424);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF727272);
  static const Color dividerColor = Color(0xFF282828);
  static const Color error = Color(0xFFE91429);

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: primaryBright,
      surface: surface,
      background: background,
      error: error,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: textPrimary,
      onBackground: textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: textPrimary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xE6121212),
      selectedItemColor: primary,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: textPrimary,
      inactiveTrackColor: Colors.white24,
      thumbColor: textPrimary,
      trackHeight: 3.5,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
    ),
    cardTheme: CardTheme(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    fontFamily: 'Roboto',
  );

  static LinearGradient primaryGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF282828), Color(0xFF121212)],
  );

  static LinearGradient albumGradient(String seed) {
    final hash = seed.hashCode.abs();
    final hues = [
      [const Color(0xFF3B1E54), const Color(0xFF121212)],
      [const Color(0xFF1E3E62), const Color(0xFF121212)],
      [const Color(0xFF004225), const Color(0xFF121212)],
      [const Color(0xFF5B1D28), const Color(0xFF121212)],
      [const Color(0xFF381442), const Color(0xFF121212)],
      [const Color(0xFF1B4965), const Color(0xFF121212)],
    ];
    final selected = hues[hash % hues.length];
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: selected,
    );
  }
}
