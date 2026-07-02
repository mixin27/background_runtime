import 'package:background_runtime_platform_interface/background_runtime_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeBackgroundRuntime fake;

  setUp(() {
    fake = FakeBackgroundRuntime();
  });

  group('FakeBackgroundRuntime', () {
    test('initialized lifecycle event on initialize', () async {
      final events = <RuntimeLifecycle>[];
      final sub = fake.lifecycleEvents().listen(events.add);

      await fake.initialize(const BackgroundRuntimeConfig());
      await Future.delayed(Duration.zero);

      expect(events.length, greaterThanOrEqualTo(1));
      expect(events.first.event, RuntimeLifecycleEvent.initialized);

      await sub.cancel();
    });

    test('startDownload returns taskId and emits event', () async {
      final events = <DownloadEvent>[];
      final sub = fake.downloadEvents().listen(events.add);

      await fake.initialize(const BackgroundRuntimeConfig());
      final taskId = await fake.startDownload(
        const DownloadRequest(url: 'https://example.com/file.zip', destinationPath: '/tmp/file.zip'),
      );

      expect(taskId, startsWith('fake_'));
      expect(events.any((e) => e.state == DownloadState.downloading), isTrue);

      await sub.cancel();
    });

    test('pauseDownload pauses a running download', () async {
      await fake.initialize(const BackgroundRuntimeConfig());
      final taskId = await fake.startDownload(
        const DownloadRequest(url: 'https://example.com/file.zip', destinationPath: '/tmp/file.zip'),
      );

      final eventFuture = fake.downloadEvents()
          .firstWhere((e) => e.taskId == taskId && e.state == DownloadState.paused)
          .timeout(const Duration(seconds: 2));
      await fake.pauseDownload(taskId);

      final event = await eventFuture;
      expect(event.state, DownloadState.paused);
    });

    test('resumeDownload resumes a paused download', () async {
      await fake.initialize(const BackgroundRuntimeConfig());
      final taskId = await fake.startDownload(
        const DownloadRequest(url: 'https://example.com/file.zip', destinationPath: '/tmp/file.zip'),
      );
      await fake.pauseDownload(taskId);

      final eventFuture = fake.downloadEvents()
          .firstWhere((e) => e.taskId == taskId && e.state == DownloadState.downloading)
          .timeout(const Duration(seconds: 2));
      await fake.resumeDownload(taskId);

      final event = await eventFuture;
      expect(event.state, DownloadState.downloading);
    });

    test('cancelDownload cancels a download', () async {
      await fake.initialize(const BackgroundRuntimeConfig());
      final taskId = await fake.startDownload(
        const DownloadRequest(url: 'https://example.com/file.zip', destinationPath: '/tmp/file.zip'),
      );

      final eventFuture = fake.downloadEvents()
          .firstWhere((e) => e.taskId == taskId && e.state == DownloadState.cancelled)
          .timeout(const Duration(seconds: 2));
      await fake.cancelDownload(taskId);

      final event = await eventFuture;
      expect(event.state, DownloadState.cancelled);
    });

    test('cancelDownload on unknown task throws TaskNotFoundException', () async {
      await fake.initialize(const BackgroundRuntimeConfig());
      expect(
        () => fake.cancelDownload('nonexistent'),
        throwsA(isA<TaskNotFoundException>()),
      );
    });

    test('playAudio emits playing state', () async {
      await fake.initialize(const BackgroundRuntimeConfig());

      final stateFuture = fake.playerState()
          .firstWhere((s) => s.state == PlaybackState.playing)
          .timeout(const Duration(seconds: 2));
      await fake.playAudio(
        AudioTrack(id: 'track_1', title: 'Song', source: Uri.parse('https://example.com/s.mp3')),
      );

      final state = await stateFuture;
      expect(state.trackId, 'track_1');
    });

    test('pauseAudio emits paused state', () async {
      await fake.initialize(const BackgroundRuntimeConfig());
      await fake.playAudio(
        AudioTrack(id: 't', title: 'T', source: Uri.parse('https://example.com/t.mp3')),
      );

      final stateFuture = fake.playerState()
          .firstWhere((s) => s.state == PlaybackState.paused)
          .timeout(const Duration(seconds: 2));
      await fake.pauseAudio();

      final state = await stateFuture;
      expect(state.state, PlaybackState.paused);
    });

    test('stopAudio emits stopped state', () async {
      await fake.initialize(const BackgroundRuntimeConfig());
      await fake.playAudio(
        AudioTrack(id: 't', title: 'T', source: Uri.parse('https://example.com/t.mp3')),
      );

      final stateFuture = fake.playerState()
          .firstWhere((s) => s.state == PlaybackState.stopped)
          .timeout(const Duration(seconds: 2));
      await fake.stopAudio();

      final state = await stateFuture;
      expect(state.state, PlaybackState.stopped);
    });

    test('operations before initialize throw NotInitializedException', () async {
      expect(
        () => fake.startDownload(
          const DownloadRequest(url: 'https://example.com/f.zip', destinationPath: '/tmp/f.zip'),
        ),
        throwsA(isA<NotInitializedException>()),
      );
      expect(
        () => fake.playAudio(
          AudioTrack(id: 't', title: 'T', source: Uri.parse('https://example.com/t.mp3')),
        ),
        throwsA(isA<NotInitializedException>()),
      );
    });

    test('shutdown emits terminated event and clears state', () async {
      await fake.initialize(const BackgroundRuntimeConfig());
      final taskId = await fake.startDownload(
        const DownloadRequest(url: 'https://example.com/f.zip', destinationPath: '/tmp/f.zip'),
      );

      await fake.shutdown();

      expect(
        () => fake.cancelDownload(taskId),
        throwsA(isA<NotInitializedException>()),
      );
    });
  });
}
