import 'package:flutter/material.dart';

class AppTheme {
  static bool isDarkMode = true;

  static const Color primary = Color(0xFF1DB954); // Spotify Green
  static const Color primaryBright = Color(0xFF1ED760);

  static Color get background => isDarkMode ? const Color(0xFF121212) : const Color(0xFFF7F9FC);
  static Color get surface => isDarkMode ? const Color(0xFF181818) : Colors.white;
  static Color get surfaceElevated => isDarkMode ? const Color(0xFF242424) : const Color(0xFFEEF1F6);
  static Color get cardColor => isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;
  static Color get textPrimary => isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF121212);
  static Color get textSecondary => isDarkMode ? const Color(0xFFB3B3B3) : const Color(0xFF555555);
  static Color get textMuted => isDarkMode ? const Color(0xFF727272) : const Color(0xFF888888);
  static Color get dividerColor => isDarkMode ? const Color(0xFF282828) : const Color(0xFFE0E0E0);
  static const Color error = Color(0xFFE91429);

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    primaryColor: primary,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: primaryBright,
      surface: Color(0xFF181818),
      background: Color(0xFF121212),
      error: error,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Color(0xFFFFFFFF),
      onBackground: Color(0xFFFFFFFF),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: Color(0xFFFFFFFF)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xE6121212),
      selectedItemColor: primary,
      unselectedItemColor: Color(0xFFB3B3B3),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: Color(0xFFFFFFFF),
      inactiveTrackColor: Colors.white24,
      thumbColor: Color(0xFFFFFFFF),
      trackHeight: 3.5,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF1A1A1A),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: const Color(0xFF242424),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF181818),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    fontFamily: 'Roboto',
  );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF7F9FC),
    primaryColor: primary,
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: primaryBright,
      surface: Colors.white,
      background: Color(0xFFF7F9FC),
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF121212),
      onBackground: Color(0xFF121212),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF7F9FC),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Color(0xFF121212),
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: Color(0xFF121212)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primary,
      unselectedItemColor: Color(0xFF65676B),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: primary,
      inactiveTrackColor: Color(0xFFE4E6EB),
      thumbColor: primary,
      trackHeight: 3.5,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
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
