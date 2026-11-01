import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // ★

import 'screens/home_screen.dart';
import 'services/app_storage.dart';
import 'services/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await AppStorage.init();
  final settings = SettingsController(storage);
  runApp(SudokuApp(storage: storage, settings: settings));
}

class SudokuApp extends StatelessWidget {
  const SudokuApp({super.key, required this.storage, required this.settings});

  final AppStorage storage;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        title: 'Судоку',
        debugShowCheckedModeBanner: false,

        // ★ Русский язык для системных текстов Flutter
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,

        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        themeMode: settings.themeMode,
        home: HomeScreen(storage: storage, settings: settings),
      ),
    );
  }

  static ThemeData _buildTheme(Brightness brightness) => ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: brightness,
        useMaterial3: true,
      );
}
