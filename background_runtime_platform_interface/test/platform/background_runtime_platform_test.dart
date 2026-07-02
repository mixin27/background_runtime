import 'package:flutter_test/flutter_test.dart';
import 'package:background_runtime_platform_interface/background_runtime_platform_interface.dart';

void main() {
  group('BackgroundRuntimePlatform', () {
    test('default instance is MethodChannelBackgroundRuntime', () {
      final instance = BackgroundRuntimePlatform.instance;
      expect(instance, isA<MethodChannelBackgroundRuntime>());
    });

    test('set instance accepts valid implementation', () {
      final fake = FakeBackgroundRuntime();
      BackgroundRuntimePlatform.instance = fake;
      expect(BackgroundRuntimePlatform.instance, fake);
      BackgroundRuntimePlatform.instance = MethodChannelBackgroundRuntime();
    });

    test('set instance rejects invalid type', () {
      expect(
        () => BackgroundRuntimePlatform.instance = _InvalidPlatform() as dynamic,
        throwsA(isA<TypeError>()),
      );
    });
  });
}

class _InvalidPlatform {
  // Does not extend BackgroundRuntimePlatform — should fail verification.
}
