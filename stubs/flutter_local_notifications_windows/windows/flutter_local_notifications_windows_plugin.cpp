#include "include/flutter_local_notifications_windows/flutter_local_notifications_windows_plugin.h"
#include <flutter/plugin_registrar_windows.h>
#include <memory>

void FlutterLocalNotificationsWindowsPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  FlutterLocalNotificationsWindowsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

void FlutterLocalNotificationsWindowsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto plugin = std::make_unique<FlutterLocalNotificationsWindowsPlugin>();
  registrar->AddPlugin(std::move(plugin));
}

FlutterLocalNotificationsWindowsPlugin::FlutterLocalNotificationsWindowsPlugin() {}
FlutterLocalNotificationsWindowsPlugin::~FlutterLocalNotificationsWindowsPlugin() {}
