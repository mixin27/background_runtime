import 'package:background_runtime_platform_interface/background_runtime_platform_interface.dart';
import 'src/background_runtime_android_plugin.dart';

/// Registers the Android implementation with the platform interface.
///
/// Call this during app initialization if automatic registration does not
/// occur. Usually invoked from the native Android plugin registration.
void registerBackgroundRuntimeAndroid() {
  BackgroundRuntimePlatform.instance = BackgroundRuntimeAndroidPlugin();
}
