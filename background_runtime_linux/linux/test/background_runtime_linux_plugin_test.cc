#include <flutter_linux/flutter_linux.h>
#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "background_runtime_linux_private.h"
#include "include/background_runtime_linux/background_runtime_linux_plugin.h"

namespace background_runtime_linux::test {

TEST(BackgroundRuntimeLinuxPlugin, InitializeSucceeds) {
  g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(
      fl_method_success_response_new(nullptr));
  ASSERT_NE(response, nullptr);
}

TEST(BackgroundRuntimeLinuxPlugin, PluginTypeIsRegistered) {
  GType type = background_runtime_linux_plugin_get_type();
  ASSERT_NE(type, G_TYPE_INVALID);
}

}  // namespace background_runtime_linux::test
