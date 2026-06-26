import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'controllers/music_controller.dart';
import 'controllers/player_controller.dart';
import 'controllers/playlist_controller.dart';
import 'controllers/settings_controller.dart';
import 'controllers/auth_controller.dart';
import 'views/screens/splash/splash_screen.dart';
import 'services/audio_service.dart';
import 'package:audio_service/audio_service.dart' as auds;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  AudioService.handler = await auds.AudioService.init(
    builder: () => MyAudioHandler(),
    config: const auds.AudioServiceConfig(
      androidNotificationChannelId: 'com.example.music_player.channel.audio',
      androidNotificationChannelName: 'Nupe Songs Playback',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsController()..loadSettings(),
          lazy: false,
        ),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(
          create: (_) => MusicController()..loadMusic(),
          lazy: false,
        ),
        ChangeNotifierProvider(
          create: (context) {
            final music = Provider.of<MusicController>(context, listen: false);
            final settings = Provider.of<SettingsController>(context, listen: false);
            final player = PlayerController(musicController: music, settingsController: settings);
            settings.onSleepTimerExpired = () async {
              player.pause();
              try {
                await SystemNavigator.pop();
              } catch (_) {}
              exit(0);
            };
            return player;
          },
        ),
        ChangeNotifierProvider(create: (_) => PlaylistController()..loadPlaylists()),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settingsController, _) {
          return MaterialApp(
            title: 'Nupe Songs',
            debugShowCheckedModeBanner: false,
            themeMode: settingsController.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: const Color(0xFF001199),
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: const Color(0xFF001199),
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF08080A),
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
