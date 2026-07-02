import 'package:background_runtime_platform_interface/background_runtime_platform_interface.dart';
import 'src/background_runtime_macos_plugin.dart';

/// Registers the macOS implementation with the platform interface.
void registerBackgroundRuntimeMacos() {
  BackgroundRuntimePlatform.instance = BackgroundRuntimeMacosPlugin();
}
