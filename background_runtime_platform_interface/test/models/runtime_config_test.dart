import 'package:flutter_test/flutter_test.dart';
import 'package:background_runtime_platform_interface/background_runtime_platform_interface.dart';

void main() {
  group('BackgroundRuntimeConfig', () {
    test('creates with default values', () {
      final config = BackgroundRuntimeConfig();
      expect(config.enableDownloads, isTrue);
      expect(config.enableAudio, isTrue);
      expect(config.enableForegroundService, isTrue);
      expect(config.enableNotifications, isTrue);
      expect(config.notificationChannelId, isNull);
      expect(config.notificationChannelName, isNull);
    });

    test('creates with custom values', () {
      final config = BackgroundRuntimeConfig(
        enableDownloads: false,
        enableAudio: false,
        enableForegroundService: false,
        enableNotifications: false,
        notificationChannelId: 'custom_channel',
        notificationChannelName: 'Custom Channel',
      );
      expect(config.enableDownloads, isFalse);
      expect(config.notificationChannelId, 'custom_channel');
    });

    test('serializes to map and back', () {
      final original = BackgroundRuntimeConfig(
        enableDownloads: false,
        enableAudio: true,
        notificationChannelId: 'channel_id',
      );
      final map = original.toMap();
      final restored = BackgroundRuntimeConfig.fromMap(map);
      expect(restored, equals(original));
    });

    test('value equality', () {
      final a = BackgroundRuntimeConfig(enableDownloads: false);
      final b = BackgroundRuntimeConfig(enableDownloads: false);
      expect(a, equals(b));
    });

    test('toString contains enable fields', () {
      final config = BackgroundRuntimeConfig(enableDownloads: false);
      expect(config.toString(), contains('false'));
    });
  });
}
