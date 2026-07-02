#include "background_runtime_windows_plugin.h"

#include <flutter/encodable_map.h>
#include <flutter/encodable_value.h>
#include <flutter/event_channel.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>
#include <string>

namespace background_runtime_windows {

using flutter::EncodableMap;
using flutter::EncodableValue;

void BackgroundRuntimeWindowsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      registrar->messenger(), "dev.mixin27.background_runtime/method",
      &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<BackgroundRuntimeWindowsPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

BackgroundRuntimeWindowsPlugin::BackgroundRuntimeWindowsPlugin() {}

BackgroundRuntimeWindowsPlugin::~BackgroundRuntimeWindowsPlugin() {}

void BackgroundRuntimeWindowsPlugin::HandleMethodCall(
    const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  const auto &method_name = method_call.method_name();

  if (method_name == "initialize") {
    result->Success();
  } else if (method_name == "startDownload") {
    const auto *arguments = std::get_if<EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Error("DOWNLOAD_FAILED", "Invalid arguments");
      return;
    }
    EncodableMap response;
    response[EncodableValue("taskId")] = EncodableValue("placeholder_task_id");
    result->Success(EncodableValue(response));
  } else if (method_name == "pauseDownload" ||
             method_name == "resumeDownload" ||
             method_name == "cancelDownload") {
    result->Success();
  } else if (method_name == "playAudio" ||
             method_name == "pauseAudio" ||
             method_name == "resumeAudio" ||
             method_name == "stopAudio" ||
             method_name == "seekAudio") {
    result->Success();
  } else if (method_name == "shutdown") {
    result->Success();
  } else {
    result->NotImplemented();
  }
}

}  // namespace background_runtime_windows
