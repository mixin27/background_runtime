#include <flutter/encodable_map.h>
#include <flutter/method_call.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>
#include <gtest/gtest.h>
#include <windows.h>

#include <memory>
#include <string>
#include <variant>

#include "background_runtime_windows_plugin.h"

namespace background_runtime_windows::test {

using flutter::EncodableMap;
using flutter::EncodableValue;

TEST(BackgroundRuntimeWindowsPlugin, InitializeSucceeds) {
  BackgroundRuntimeWindowsPlugin plugin;
  bool success = false;
  EncodableMap args;
  args[EncodableValue("config")] = EncodableValue(EncodableMap{});
  plugin.HandleMethodCall(
      flutter::MethodCall<EncodableValue>("initialize",
                                          std::make_unique<EncodableValue>(args)),
      std::make_unique<flutter::MethodResultFunctions<EncodableValue>>(
          [&success](const EncodableValue *result) { success = true; },
          nullptr, nullptr));
  EXPECT_TRUE(success);
}

TEST(BackgroundRuntimeWindowsPlugin, UnknownMethodReturnsNotImplemented) {
  BackgroundRuntimeWindowsPlugin plugin;
  bool not_implemented = false;
  plugin.HandleMethodCall(
      flutter::MethodCall<EncodableValue>("unknown_method",
                                          std::make_unique<EncodableValue>()),
      std::make_unique<flutter::MethodResultFunctions<EncodableValue>>(
          nullptr, nullptr,
          [&not_implemented](const std::string &code,
                             const std::string &message,
                             const EncodableValue *details) {
            not_implemented = true;
          }));
  EXPECT_TRUE(not_implemented);
}

TEST(BackgroundRuntimeWindowsPlugin, StartDownloadReturnsTaskId) {
  BackgroundRuntimeWindowsPlugin plugin;
  std::string task_id;
  EncodableMap inner;
  inner[EncodableValue("url")] = EncodableValue("https://example.com/file.zip");
  inner[EncodableValue("destinationPath")] = EncodableValue("C:\\temp\\file.zip");
  EncodableMap args;
  args[EncodableValue("request")] = EncodableValue(inner);
  plugin.HandleMethodCall(
      flutter::MethodCall<EncodableValue>("startDownload",
                                          std::make_unique<EncodableValue>(args)),
      std::make_unique<flutter::MethodResultFunctions<EncodableValue>>(
          [&task_id](const EncodableValue *result) {
            if (result && std::holds_alternative<EncodableMap>(*result)) {
              const auto &map = std::get<EncodableMap>(*result);
              auto it = map.find(EncodableValue("taskId"));
              if (it != map.end() &&
                  std::holds_alternative<std::string>(it->second)) {
                task_id = std::get<std::string>(it->second);
              }
            }
          },
          nullptr, nullptr));
  EXPECT_FALSE(task_id.empty());
}

}  // namespace background_runtime_windows::test
