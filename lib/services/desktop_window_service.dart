import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';

class DesktopWindowService extends WindowListener with TrayListener {
  static final DesktopWindowService _instance = DesktopWindowService._();
  static DesktopWindowService get instance => _instance;

  DesktopWindowService._();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (!Platform.isWindows) return;

    await windowManager.ensureInitialized();
    await Window.initialize();
    
    // Set title
    await windowManager.setTitle('   Oasis');

    // Tray initialization
    await trayManager.setIcon(
      Platform.isWindows ? 'assets/images/logo.png' : 'assets/images/logo.png',
    );
    
    final Menu menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: 'Show Oasis',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: 'Exit',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
    
    // Add listeners
    windowManager.addListener(this);
    trayManager.addListener(this);

    _isInitialized = true;
  }

  Future<void> setWindowEffect({required bool enabled, String effect = 'mica'}) async {
    if (!Platform.isWindows) return;

    if (!enabled) {
      await Window.setEffect(effect: WindowEffect.disabled);
      debugPrint('DesktopWindowService: Effects disabled');
      return;
    }

    if (effect == 'acrylic') {
      await Window.setEffect(
        effect: WindowEffect.acrylic,
        color: const Color(0xCC000000), // Semi-transparent black for Acrylic
      );
      debugPrint('DesktopWindowService: Acrylic effect enabled');
    } else {
      // Default to Mica
      try {
        await Window.setEffect(
          effect: WindowEffect.mica,
          dark: true,
        );
        debugPrint('DesktopWindowService: Mica effect enabled');
      } catch (e) {
        // Fallback to Acrylic if Mica is unavailable (Win 10)
        await Window.setEffect(
          effect: WindowEffect.acrylic,
          color: const Color(0xCC000000),
        );
        debugPrint('DesktopWindowService: Mica not supported, fell back to Acrylic');
      }
    }
  }

  // WindowManager overrides
  @override
  void onWindowClose() async {
    final bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await windowManager.hide();
      await windowManager.setSkipTaskbar(true);
    }
  }

  @override
  void onWindowMinimize() async {
    // Optionally hide to tray on minimize
    // await windowManager.hide();
    // await windowManager.setSkipTaskbar(true);
  }

  // TrayListener overrides
  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.setSkipTaskbar(false);
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      windowManager.show();
      windowManager.setSkipTaskbar(false);
    } else if (menuItem.key == 'exit_app') {
      windowManager.destroy();
    }
  }

  Future<void> enableCloseToTray() async {
    if (!Platform.isWindows) return;
    await windowManager.setPreventClose(true);
  }
}
