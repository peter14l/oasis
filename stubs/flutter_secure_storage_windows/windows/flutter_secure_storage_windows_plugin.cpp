#include "include/flutter_secure_storage_windows/flutter_secure_storage_windows_plugin.h"
#include <flutter/plugin_registrar_windows.h>
#include <memory>

void FlutterSecureStorageWindowsPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  FlutterSecureStorageWindowsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

void FlutterSecureStorageWindowsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto plugin = std::make_unique<FlutterSecureStorageWindowsPlugin>();
  registrar->AddPlugin(std::move(plugin));
}

FlutterSecureStorageWindowsPlugin::FlutterSecureStorageWindowsPlugin() {}
FlutterSecureStorageWindowsPlugin::~FlutterSecureStorageWindowsPlugin() {}
