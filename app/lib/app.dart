import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:system_theme/system_theme.dart';
import 'package:window_manager/window_manager.dart';

import 'home.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (event) {
        windowManager.startDragging();
      },
      child: MaterialApp(
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorSchemeSeed: SystemTheme.accentColor.accent,
          useMaterial3: true,
          cardTheme: const CardTheme(
            elevation: 1,
            clipBehavior: Clip.antiAlias,
          ),
        ),
        theme: ThemeData(
          brightness: Brightness.light,
          colorSchemeSeed: SystemTheme.accentColor.accent,
          useMaterial3: true,
          cardTheme: const CardTheme(
            elevation: 1,
            clipBehavior: Clip.antiAlias,
          ),
        ),
        themeMode: kDebugMode ? ThemeMode.light : ThemeMode.system,
        home: const Home(),
      ),
    );
  }
}
