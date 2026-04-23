#include "flutter_common.h"

class MethodCallProxyImpl : public MethodCallProxy {
 public:
  explicit MethodCallProxyImpl(const MethodCall& method_call)
      : method_call_(method_call) {}

  ~MethodCallProxyImpl() {}

  // The name of the method being called.

  const std::string& method_name() const override {
    return method_call_.method_name();
  }

  // The arguments to the method call, or NULL if there are none.
  const EncodableValue* arguments() const override {
    return method_call_.arguments();
  }

 private:
  const MethodCall& method_call_;
};

std::unique_ptr<MethodCallProxy> MethodCallProxy::Create(
    const MethodCall& call) {
  return std::make_unique<MethodCallProxyImpl>(call);
}

class MethodResultProxyImpl : public MethodResultProxy {
 public:
  explicit MethodResultProxyImpl(std::unique_ptr<MethodResult> method_result,
                                 MainThreadDispatcher dispatcher)
      : method_result_(std::move(method_result)), dispatcher_(dispatcher) {}
  ~MethodResultProxyImpl() {}

  // Reports success with no result.
  void Success() override {
    if (dispatcher_) {
      dispatcher_([this]() { method_result_->Success(); });
    } else {
      method_result_->Success();
    }
  }

  // Reports success with a result.
  void Success(const EncodableValue& result) override {
    if (dispatcher_) {
      dispatcher_([this, result]() { method_result_->Success(result); });
    } else {
      method_result_->Success(result);
    }
  }

  // Reports an error.
  void Error(const std::string& error_code,
             const std::string& error_message,
             const EncodableValue& error_details) override {
    if (dispatcher_) {
      dispatcher_([this, error_code, error_message, error_details]() {
        method_result_->Error(error_code, error_message, error_details);
      });
    } else {
      method_result_->Error(error_code, error_message, error_details);
    }
  }

  // Reports an error with a default error code and no details.
  void Error(const std::string& error_code,
             const std::string& error_message = "") override {
    if (dispatcher_) {
      dispatcher_([this, error_code, error_message]() {
        method_result_->Error(error_code, error_message);
      });
    } else {
      method_result_->Error(error_code, error_message);
    }
  }

  void NotImplemented() override {
    if (dispatcher_) {
      dispatcher_([this]() { method_result_->NotImplemented(); });
    } else {
      method_result_->NotImplemented();
    }
  }

 private:
  std::unique_ptr<MethodResult> method_result_;
  MainThreadDispatcher dispatcher_;
};

std::unique_ptr<MethodResultProxy> MethodResultProxy::Create(
    std::unique_ptr<MethodResult> method_result,
    MainThreadDispatcher dispatcher) {
  return std::make_unique<MethodResultProxyImpl>(std::move(method_result),
                                                 dispatcher);
}

class EventChannelProxyImpl : public EventChannelProxy {
 public:
  EventChannelProxyImpl(BinaryMessenger* messenger,
                        const std::string& channelName,
                        MainThreadDispatcher dispatcher)
      : dispatcher_(dispatcher),
        channel_(std::make_unique<EventChannel>(
            messenger, channelName,
            &flutter::StandardMethodCodec::GetInstance())) {
    auto handler =
        std::make_unique<flutter::StreamHandlerFunctions<EncodableValue>>(
            [&](const EncodableValue* arguments,
                std::unique_ptr<flutter::EventSink<EncodableValue>>&& events)
                -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> {
              sink_ = std::move(events);
              for (auto& event : event_queue_) {
                sink_->Success(event);
              }
              event_queue_.clear();
              on_listen_called_ = true;
              return nullptr;
            },
            [&](const EncodableValue* arguments)
                -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> {
              on_listen_called_ = false;
              return nullptr;
            });

    channel_->SetStreamHandler(std::move(handler));
  }

  virtual ~EventChannelProxyImpl() {}

  void Success(const EncodableValue& event, bool cache_event = true) override {
    if (on_listen_called_) {
      if (dispatcher_) {
        dispatcher_([this, event]() {
          if (on_listen_called_) {
            sink_->Success(event);
          }
        });
      } else {
        sink_->Success(event);
      }
    } else {
      if (cache_event) {
        event_queue_.push_back(event);
      }
    }
  }

 private:
  MainThreadDispatcher dispatcher_;
  std::unique_ptr<EventChannel> channel_;
  std::unique_ptr<EventSink> sink_;
  std::list<EncodableValue> event_queue_;
  bool on_listen_called_ = false;
};

std::unique_ptr<EventChannelProxy> EventChannelProxy::Create(
    BinaryMessenger* messenger,
    const std::string& channelName,
    MainThreadDispatcher dispatcher) {
  return std::make_unique<EventChannelProxyImpl>(messenger, channelName,
                                                 dispatcher);
}
