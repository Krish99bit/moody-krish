import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/playback_state.dart';

class ThemeProvider extends ChangeNotifier {
  AppColorTheme _currentTheme = AppColorTheme.spotifyGreen;

  AppColorTheme get currentTheme => _currentTheme;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = prefs.getInt('app_theme_index') ?? 0;
      _currentTheme = AppColorTheme.values[index.clamp(0, AppColorTheme.values.length - 1)];
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setTheme(AppColorTheme theme) async {
    _currentTheme = theme;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('app_theme_index', theme.index);
    } catch (_) {}
  }

  Color get primaryColor {
    switch (_currentTheme) {
      case AppColorTheme.spotifyGreen:
        return const Color(0xFF1DB954);
      case AppColorTheme.amoledBlack:
        return const Color(0xFFE0E0E0);
      case AppColorTheme.cyberpunkPurple:
        return const Color(0xFFB026FF);
      case AppColorTheme.oceanBlue:
        return const Color(0xFF00A8FF);
    }
  }

  Color get backgroundColor {
    switch (_currentTheme) {
      case AppColorTheme.spotifyGreen:
        return const Color(0xFF121212);
      case AppColorTheme.amoledBlack:
        return const Color(0xFF000000);
      case AppColorTheme.cyberpunkPurple:
        return const Color(0xFF0D0221);
      case AppColorTheme.oceanBlue:
        return const Color(0xFF0A192F);
    }
  }

  Color get surfaceColor {
    switch (_currentTheme) {
      case AppColorTheme.spotifyGreen:
        return const Color(0xFF181818);
      case AppColorTheme.amoledBlack:
        return const Color(0xFF0F0F0F);
      case AppColorTheme.cyberpunkPurple:
        return const Color(0xFF190033);
      case AppColorTheme.oceanBlue:
        return const Color(0xFF112240);
    }
  }

  Color get surfaceElevatedColor {
    switch (_currentTheme) {
      case AppColorTheme.spotifyGreen:
        return const Color(0xFF242424);
      case AppColorTheme.amoledBlack:
        return const Color(0xFF1A1A1A);
      case AppColorTheme.cyberpunkPurple:
        return const Color(0xFF2A0054);
      case AppColorTheme.oceanBlue:
        return const Color(0xFF1D3557);
    }
  }

  ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        onPrimary: Colors.black,
        onSurface: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }
}
