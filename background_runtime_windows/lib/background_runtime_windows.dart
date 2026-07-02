import 'package:background_runtime_platform_interface/background_runtime_platform_interface.dart';
import 'src/background_runtime_windows_plugin.dart';

/// Registers the Windows implementation with the platform interface.
void registerBackgroundRuntimeWindows() {
  BackgroundRuntimePlatform.instance = BackgroundRuntimeWindowsPlugin();
}
