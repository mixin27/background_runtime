//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <background_runtime_linux/background_runtime_linux_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) background_runtime_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "BackgroundRuntimeLinuxPlugin");
  background_runtime_linux_plugin_register_with_registrar(background_runtime_linux_registrar);
}
