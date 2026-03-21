#ifndef FLUTTER_PLUGIN_FLUTTER_LOCAL_NOTIFICATIONS_WINDOWS_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_LOCAL_NOTIFICATIONS_WINDOWS_PLUGIN_H_

#include <flutter/plugin_registrar_windows.h>
#include <flutter_plugin_registrar.h>

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

#if defined(__cplusplus)
extern "C" {
#endif

FLUTTER_PLUGIN_EXPORT void FlutterLocalNotificationsWindowsPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

#if defined(__cplusplus)
}  // extern "C"
#endif

class FlutterLocalNotificationsWindowsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlutterLocalNotificationsWindowsPlugin();

  virtual ~FlutterLocalNotificationsWindowsPlugin();
};

#endif  // FLUTTER_PLUGIN_FLUTTER_LOCAL_NOTIFICATIONS_WINDOWS_PLUGIN_H_
