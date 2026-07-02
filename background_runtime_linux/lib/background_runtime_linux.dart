import 'package:background_runtime_platform_interface/background_runtime_platform_interface.dart';
import 'src/background_runtime_linux_plugin.dart';

/// Registers the Linux implementation with the platform interface.
void registerBackgroundRuntimeLinux() {
  BackgroundRuntimePlatform.instance = BackgroundRuntimeLinuxPlugin();
}
