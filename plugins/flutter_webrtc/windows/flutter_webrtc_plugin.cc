#include "flutter_webrtc/flutter_web_r_t_c_plugin.h"

#include <windows.h>
#include <functional>
#include <flutter/plugin_registrar_windows.h>

#include "flutter_common.h"
#include "flutter_webrtc.h"

const char* kChannelName = "FlutterWebRTC.Method";

namespace flutter_webrtc_plugin {

UINT GetWebRTCDispatchMessage() {
  static UINT msg = RegisterWindowMessageA("FlutterWebRTCPluginDispatch");
  return msg;
}

// A webrtc plugin for windows/linux.
class FlutterWebRTCPluginImpl : public FlutterWebRTCPlugin {
 public:
  static void RegisterWithRegistrar(PluginRegistrar* registrar) {
    auto channel = std::make_unique<MethodChannel>(
        registrar->messenger(), kChannelName,
        &flutter::StandardMethodCodec::GetInstance());

    auto* channel_pointer = channel.get();

    // Uses new instead of make_unique due to private constructor.
    std::unique_ptr<FlutterWebRTCPluginImpl> plugin(
        new FlutterWebRTCPluginImpl(registrar, std::move(channel)));

    channel_pointer->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto& call, auto result) {
          plugin_pointer->HandleMethodCall(call, std::move(result));
        });

    registrar->AddPlugin(std::move(plugin));
  }

  virtual ~FlutterWebRTCPluginImpl() {}

  BinaryMessenger* messenger() override { return messenger_; }

  TextureRegistrar* textures() override { return textures_; }

  MainThreadDispatcher dispatcher() override { return dispatcher_; }

 private:
  // Creates a plugin that communicates on the given channel.
  FlutterWebRTCPluginImpl(PluginRegistrar* registrar,
                          std::unique_ptr<MethodChannel> channel)
      : channel_(std::move(channel)),
        messenger_(registrar->messenger()),
        textures_(registrar->texture_registrar()),
        hwnd_(nullptr) {
    auto* registrar_windows = dynamic_cast<flutter::PluginRegistrarWindows*>(registrar);
    auto* view = registrar_windows ? registrar_windows->GetView() : nullptr;
    if (view) {
      hwnd_ = view->GetNativeWindow();
    }

    dispatcher_ = [this](std::function<void()> task) {
      if (!hwnd_) {
        task();
        return;
      }
      auto* task_ptr = new std::function<void()>(std::move(task));
      if (!PostMessage(hwnd_, GetWebRTCDispatchMessage(),
                       reinterpret_cast<WPARAM>(task_ptr), 0)) {
        delete task_ptr;
      }
    };

    if (registrar_windows && view) {
      registrar_windows->RegisterTopLevelWindowProcDelegate(
          [this](HWND hwnd, UINT message, WPARAM wparam,
                 LPARAM lparam) -> std::optional<LRESULT> {
            if (message == GetWebRTCDispatchMessage()) {
              auto* task = reinterpret_cast<std::function<void()>*>(wparam);
              if (task) {
                (*task)();
                delete task;
              }
              return 0;
            }
            return std::nullopt;
          });
    }

    webrtc_ = std::make_unique<FlutterWebRTC>(this);
  }

  // Called when a method is called on |channel_|;
  void HandleMethodCall(const MethodCall& method_call,
                        std::unique_ptr<MethodResult> result) {
    // handle method call and forward to webrtc native sdk.
    auto method_call_proxy = MethodCallProxy::Create(method_call);
    webrtc_->HandleMethodCall(*method_call_proxy.get(),
                              MethodResultProxy::Create(std::move(result), dispatcher_));
  }

 private:
  std::unique_ptr<MethodChannel> channel_;
  std::unique_ptr<FlutterWebRTC> webrtc_;
  BinaryMessenger* messenger_;
  TextureRegistrar* textures_;
  HWND hwnd_;
  MainThreadDispatcher dispatcher_;
};

}  // namespace flutter_webrtc_plugin


void FlutterWebRTCPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  static auto* plugin_registrar = new flutter::PluginRegistrar(registrar);
  flutter_webrtc_plugin::FlutterWebRTCPluginImpl::RegisterWithRegistrar(
      plugin_registrar);
}