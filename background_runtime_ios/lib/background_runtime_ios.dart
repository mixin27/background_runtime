import 'package:background_runtime_platform_interface/background_runtime_platform_interface.dart';
import 'src/background_runtime_ios_plugin.dart';

/// Registers the iOS implementation with the platform interface.
///
/// Call this during app initialization if automatic registration does not
/// occur. Usually invoked from the native iOS plugin registration.
void registerBackgroundRuntimeIos() {
  BackgroundRuntimePlatform.instance = BackgroundRuntimeIosPlugin();
}
