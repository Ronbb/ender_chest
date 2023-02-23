import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:system_theme/system_theme.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await trayManager.setIcon(
    Platform.isWindows ? 'images/app_icon.ico' : 'images/app_icon_32.png',
  );
  await trayManager.setContextMenu(
    Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: 'Show Window',
          onClick: (menuItem) {
            windowManager.restore();
          },
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: 'Exit App',
          onClick: (menuItem) {
            windowManager.close();
          },
        ),
      ],
    ),
  );

  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(360, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    if (kDebugMode) {
      await windowManager.setAlwaysOnTop(true);
    }
    await windowManager.setResizable(false);
  });

  await hotKeyManager.unregisterAll();
  await hotKeyManager.register(
    HotKey(
      KeyCode.keyQ,
      modifiers: [KeyModifier.alt],
      scope: HotKeyScope.system,
    ),
    keyDownHandler: (hotKey) async {
      debugPrint('onKeyDown ${hotKey.toJson()}');
      await windowManager.show();
      await windowManager.focus();
      await windowManager.restore();
    },
  );

  await SystemTheme.accentColor.load();

  runApp(const App());
}
