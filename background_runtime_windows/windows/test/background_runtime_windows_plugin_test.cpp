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

TEST(BackgroundRuntimeWindowsPlugin, InitializeSucceeds) {
  BackgroundRuntimeWindowsPlugin plugin;
  plugin.HandleMethodCall(
      MethodCall("initialize", std::make_unique<EncodableValue>()),
      std::make_unique<MethodResultFunctions<>>(
          [](const EncodableValue *result) { SUCCEED(); },
          nullptr, nullptr));
}

TEST(BackgroundRuntimeWindowsPlugin, UnknownMethodReturnsNotImplemented) {
  BackgroundRuntimeWindowsPlugin plugin;
  bool not_implemented = false;
  plugin.HandleMethodCall(
      MethodCall("unknown_method", std::make_unique<EncodableValue>()),
      std::make_unique<MethodResultFunctions<>>(
          nullptr, nullptr,
          [&not_implemented](const std::string &code,
                              const std::string &message,
                              const EncodableValue *details) {
            not_implemented = true;
          }));
  EXPECT_TRUE(not_implemented);
}

}  // namespace background_runtime_windows::test
