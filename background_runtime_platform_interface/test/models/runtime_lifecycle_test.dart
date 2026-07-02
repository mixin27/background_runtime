import 'package:background_runtime_platform_interface/background_runtime_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RuntimeLifecycleEvent', () {
    test('fromString returns correct enum', () {
      expect(RuntimeLifecycleEvent.fromString('initialized'), RuntimeLifecycleEvent.initialized);
      expect(RuntimeLifecycleEvent.fromString('started'), RuntimeLifecycleEvent.started);
      expect(RuntimeLifecycleEvent.fromString('paused'), RuntimeLifecycleEvent.paused);
      expect(RuntimeLifecycleEvent.fromString('resumed'), RuntimeLifecycleEvent.resumed);
      expect(RuntimeLifecycleEvent.fromString('stopped'), RuntimeLifecycleEvent.stopped);
      expect(RuntimeLifecycleEvent.fromString('terminated'), RuntimeLifecycleEvent.terminated);
    });

    test('fromString defaults to terminated for unknown', () {
      expect(RuntimeLifecycleEvent.fromString('unknown'), RuntimeLifecycleEvent.terminated);
    });
  });

  group('RuntimeLifecycle', () {
    test('creates with required fields', () {
      final now = DateTime.now();
      final lifecycle = RuntimeLifecycle(
        event: RuntimeLifecycleEvent.initialized,
        timestamp: now,
      );
      expect(lifecycle.event, RuntimeLifecycleEvent.initialized);
      expect(lifecycle.timestamp, now);
      expect(lifecycle.data, isNull);
    });

    test('creates with data', () {
      final lifecycle = RuntimeLifecycle(
        event: RuntimeLifecycleEvent.initialized,
        timestamp: DateTime.now(),
        data: {'key': 'value'},
      );
      expect(lifecycle.data, {'key': 'value'});
    });

    test('serializes to map and back', () {
      final original = RuntimeLifecycle(
        event: RuntimeLifecycleEvent.initialized,
        timestamp: DateTime.utc(2026),
      );
      final map = original.toMap();
      final restored = RuntimeLifecycle.fromMap(map);
      expect(restored, equals(original));
    });

    test('value equality', () {
      final now = DateTime.now();
      final a = RuntimeLifecycle(event: RuntimeLifecycleEvent.initialized, timestamp: now);
      final b = RuntimeLifecycle(event: RuntimeLifecycleEvent.initialized, timestamp: now);
      expect(a, equals(b));
    });

    test('toString contains event and timestamp', () {
      final lifecycle = RuntimeLifecycle(
        event: RuntimeLifecycleEvent.initialized,
        timestamp: DateTime.now(),
      );
      expect(lifecycle.toString(), contains('initialized'));
    });
  });
}
