import 'package:background_runtime_platform_interface/background_runtime_platform_interface.dart';
import 'src/background_runtime_web_plugin.dart';

/// Registers the web implementation with the platform interface.
void registerBackgroundRuntimeWeb() {
  BackgroundRuntimePlatform.instance = BackgroundRuntimeWebPlugin();
}
