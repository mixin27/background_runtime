#include "include/background_runtime_windows/background_runtime_windows_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "background_runtime_windows_plugin.h"

void BackgroundRuntimeWindowsCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  background_runtime_windows::BackgroundRuntimeWindowsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
