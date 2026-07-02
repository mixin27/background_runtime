import 'package:background_runtime_platform_interface/background_runtime_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DownloadState', () {
    test('fromString returns correct enum', () {
      expect(DownloadState.fromString('pending'), DownloadState.pending);
      expect(DownloadState.fromString('downloading'), DownloadState.downloading);
      expect(DownloadState.fromString('paused'), DownloadState.paused);
      expect(DownloadState.fromString('completed'), DownloadState.completed);
      expect(DownloadState.fromString('failed'), DownloadState.failed);
      expect(DownloadState.fromString('cancelled'), DownloadState.cancelled);
    });

    test('fromString defaults to failed for unknown', () {
      expect(DownloadState.fromString('unknown'), DownloadState.failed);
    });
  });

  group('DownloadEvent', () {
    test('creates with required fields', () {
      const event = DownloadEvent(
        taskId: 'task_1',
        url: 'https://example.com/file.zip',
        state: DownloadState.downloading,
      );
      expect(event.taskId, 'task_1');
      expect(event.state, DownloadState.downloading);
      expect(event.progress, isNull);
    });

    test('creates with all fields', () {
      const event = DownloadEvent(
        taskId: 'task_1',
        url: 'https://example.com/file.zip',
        state: DownloadState.completed,
        progress: 100.0,
        bytesReceived: 1000,
        totalBytes: 1000,
      );
      expect(event.progress, 100.0);
      expect(event.bytesReceived, 1000);
      expect(event.totalBytes, 1000);
    });

    test('serializes to map and back', () {
      const original = DownloadEvent(
        taskId: 'task_1',
        url: 'https://example.com/file.zip',
        state: DownloadState.downloading,
        progress: 45.5,
        bytesReceived: 455,
        totalBytes: 1000,
      );
      final map = original.toMap();
      final restored = DownloadEvent.fromMap(map);
      expect(restored, equals(original));
    });

    test('value equality', () {
      const a = DownloadEvent(
        taskId: 'task_1',
        url: 'https://example.com/file.zip',
        state: DownloadState.completed,
        progress: 100.0,
      );
      const b = DownloadEvent(
        taskId: 'task_1',
        url: 'https://example.com/file.zip',
        state: DownloadState.completed,
        progress: 100.0,
      );
      expect(a, equals(b));
    });

    test('toString contains taskId and state', () {
      const event = DownloadEvent(
        taskId: 'task_1',
        url: 'https://example.com/file.zip',
        state: DownloadState.downloading,
      );
      expect(event.toString(), contains('task_1'));
      expect(event.toString(), contains('downloading'));
    });
  });
}
