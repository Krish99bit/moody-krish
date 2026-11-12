import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/library_provider.dart';
import 'providers/music_provider.dart';
import 'providers/playlist_provider.dart';
import 'providers/theme_provider.dart';
import 'services/audio_handler.dart';
import 'services/equalizer_service.dart';
import 'services/sleep_timer_service.dart';
import 'services/storage_service.dart';
import 'ui/screens/main_shell.dart';
import 'ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure Android status bar and navigation bar colors for dark look
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize background Audio Service
  final audioHandler = await initAudioService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => StorageService()),
        ChangeNotifierProvider(
          create: (_) => EqualizerService()..attachAudioHandler(audioHandler),
        ),
        ChangeNotifierProvider(create: (_) => SleepTimerService()),
        ChangeNotifierProvider(
          create: (context) => MusicProvider(
            audioHandler,
            context.read<SleepTimerService>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => PlaylistProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
      ],
      child: const MoodyKrishApp(),
    ),
  );
}

class MoodyKrishApp extends StatelessWidget {
  const MoodyKrishApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'Moody Krish',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      home: const MainShell(),
    );
  }
}
