import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
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

    // Tray initialization - use absolute path for Windows
    await _setupTray();

    // Add listeners
    windowManager.addListener(this);
    trayManager.addListener(this);

    _isInitialized = true;
  }

  Future<void> _setupTray() async {
    // Get the executable path to locate assets
    final exePath = Platform.resolvedExecutable;
    final exeDir = File(exePath).parent.path;
    final iconPath =
        '$exeDir\\data\\flutter_assets\\assets\\images\\app_icon.ico';

    // Try to set tray icon - fallback to ICO format
    try {
      final iconFile = File(iconPath);
      if (await iconFile.exists()) {
        await trayManager.setIcon(iconPath);
      } else {
        // Fallback to the runner icon
        final runnerIcon = '$exeDir\\resources\\app_icon.ico';
        final runnerFile = File(runnerIcon);
        if (await runnerFile.exists()) {
          await trayManager.setIcon(runnerIcon);
        } else {
          debugPrint('DesktopWindowService: No tray icon found at $iconPath');
        }
      }
    } catch (e) {
      debugPrint('DesktopWindowService: Failed to set tray icon: $e');
    }

    // Create context menu with async-safe approach
    await _updateTrayMenu();
  }

  Future<void> _updateTrayMenu() async {
    try {
      final Menu menu = Menu(
        items: [
          MenuItem(key: 'show_window', label: 'Show Oasis'),
          MenuItem.separator(),
          MenuItem(key: 'exit_app', label: 'Exit'),
        ],
      );
      await trayManager.setContextMenu(menu);
    } catch (e) {
      debugPrint('DesktopWindowService: Failed to set context menu: $e');
    }
  }

  Future<void> setWindowEffect({
    required bool enabled,
    String effect = 'mica',
  }) async {
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
        await Window.setEffect(effect: WindowEffect.mica, dark: true);
        debugPrint('DesktopWindowService: Mica effect enabled');
      } catch (e) {
        // Fallback to Acrylic if Mica is unavailable (Win 10)
        await Window.setEffect(
          effect: WindowEffect.acrylic,
          color: const Color(0xCC000000),
        );
        debugPrint(
          'DesktopWindowService: Mica not supported, fell back to Acrylic',
        );
      }
    }
  }

  // Track double-click for tray icon
  DateTime? _lastTrayClickTime;
  static const _doubleClickDuration = Duration(milliseconds: 500);

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

  // TrayListener overrides - single left click to show window
  @override
  void onTrayIconMouseDown() {
    // Single click shows window - double click detection handled in mouse up
    // This is handled in onTrayIconMouseUp for better double-click detection
  }

  @override
  void onTrayIconMouseUp() {
    final now = DateTime.now();
    if (_lastTrayClickTime != null &&
        now.difference(_lastTrayClickTime!) < _doubleClickDuration) {
      // Double click - restore and focus window
      windowManager.show();
      windowManager.focus();
      windowManager.setSkipTaskbar(false);
      _lastTrayClickTime = null;
    } else {
      // Single click - show window
      windowManager.show();
      windowManager.setSkipTaskbar(false);
      _lastTrayClickTime = now;
    }
  }

  // Right click - show context menu (with error handling to prevent freezes)
  @override
  void onTrayIconRightMouseDown() {
    // Use try-catch to prevent freezes
    try {
      trayManager.popUpContextMenu();
    } catch (e) {
      debugPrint('DesktopWindowService: Right-click menu failed: $e');
    }
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      windowManager.show();
      windowManager.focus();
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
