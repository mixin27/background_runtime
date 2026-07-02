import 'package:flutter_test/flutter_test.dart';
import 'package:background_runtime_platform_interface/background_runtime_platform_interface.dart';
import 'package:background_runtime/background_runtime.dart';

void main() {
  late FakeBackgroundRuntime fake;

  setUp(() {
    fake = FakeBackgroundRuntime();
    BackgroundRuntimePlatform.instance = fake;
  });

  tearDown(() {
    BackgroundRuntimePlatform.instance = MethodChannelBackgroundRuntime();
  });

  group('BackgroundRuntime', () {
    test('initialize delegates to platform', () async {
      await BackgroundRuntime.initialize();
      // No exception means success
    });

    test('initialize passes config', () async {
      await BackgroundRuntime.initialize(
        config: const BackgroundRuntimeConfig(enableDownloads: false),
      );
      // Fake stores config internally, no exception means success
    });

    test('download returns taskId', () async {
      await BackgroundRuntime.initialize();
      final taskId = await BackgroundRuntime.download(
        DownloadRequest(url: 'https://example.com/file.zip', destinationPath: '/tmp/file.zip'),
      );
      expect(taskId, startsWith('fake_'));
    });

    test('pause delegates to platform', () async {
      await BackgroundRuntime.initialize();
      final taskId = await BackgroundRuntime.download(
        DownloadRequest(url: 'https://example.com/file.zip', destinationPath: '/tmp/file.zip'),
      );
      final pauseEvent = BackgroundRuntime.observeDownloads().firstWhere(
        (e) => e.taskId == taskId && e.state == DownloadState.paused,
      );
      await BackgroundRuntime.pause(taskId);
      expect((await pauseEvent).state, DownloadState.paused);
    });

    test('resume delegates to platform', () async {
      await BackgroundRuntime.initialize();
      final taskId = await BackgroundRuntime.download(
        DownloadRequest(url: 'https://example.com/file.zip', destinationPath: '/tmp/file.zip'),
      );
      await BackgroundRuntime.pause(taskId);
      final resumeEvent = BackgroundRuntime.observeDownloads().firstWhere(
        (e) => e.taskId == taskId && e.state == DownloadState.downloading,
      );
      await BackgroundRuntime.resume(taskId);
      expect((await resumeEvent).state, DownloadState.downloading);
    });

    test('cancel delegates to platform', () async {
      await BackgroundRuntime.initialize();
      final taskId = await BackgroundRuntime.download(
        DownloadRequest(url: 'https://example.com/file.zip', destinationPath: '/tmp/file.zip'),
      );
      final cancelEvent = BackgroundRuntime.observeDownloads().firstWhere(
        (e) => e.taskId == taskId && e.state == DownloadState.cancelled,
      );
      await BackgroundRuntime.cancel(taskId);
      expect((await cancelEvent).state, DownloadState.cancelled);
    });

    test('play delegates to platform', () async {
      await BackgroundRuntime.initialize();
      final playState = BackgroundRuntime.observePlayer().firstWhere(
        (s) => s.state == PlaybackState.playing,
      );
      await BackgroundRuntime.play(
        AudioTrack(
          id: 'track_1',
          title: 'Song',
          source: Uri.parse('https://example.com/song.mp3'),
        ),
      );
      expect((await playState).trackId, 'track_1');
    });

    test('pauseAudio delegates to platform', () async {
      await BackgroundRuntime.initialize();
      final playState = BackgroundRuntime.observePlayer().firstWhere(
        (s) => s.state == PlaybackState.playing,
      );
      await BackgroundRuntime.play(
        AudioTrack(id: 't', title: 'T', source: Uri.parse('https://example.com/t.mp3')),
      );
      await playState;
      final pauseState = BackgroundRuntime.observePlayer().firstWhere(
        (s) => s.state == PlaybackState.paused,
      );
      await BackgroundRuntime.pauseAudio();
      expect((await pauseState).state, PlaybackState.paused);
    });

    test('resumeAudio delegates to platform', () async {
      await BackgroundRuntime.initialize();
      final playState = BackgroundRuntime.observePlayer().firstWhere(
        (s) => s.state == PlaybackState.playing,
      );
      await BackgroundRuntime.play(
        AudioTrack(id: 't', title: 'T', source: Uri.parse('https://example.com/t.mp3')),
      );
      await playState;
      final pauseState = BackgroundRuntime.observePlayer().firstWhere(
        (s) => s.state == PlaybackState.paused,
      );
      await BackgroundRuntime.pauseAudio();
      await pauseState;
      final resumeState = BackgroundRuntime.observePlayer().firstWhere(
        (s) => s.state == PlaybackState.playing,
      );
      await BackgroundRuntime.resumeAudio();
      expect((await resumeState).state, PlaybackState.playing);
    });

    test('stop delegates to platform', () async {
      await BackgroundRuntime.initialize();
      final playState = BackgroundRuntime.observePlayer().firstWhere(
        (s) => s.state == PlaybackState.playing,
      );
      await BackgroundRuntime.play(
        AudioTrack(id: 't', title: 'T', source: Uri.parse('https://example.com/t.mp3')),
      );
      await playState;
      final stopState = BackgroundRuntime.observePlayer().firstWhere(
        (s) => s.state == PlaybackState.stopped,
      );
      await BackgroundRuntime.stop();
      expect((await stopState).state, PlaybackState.stopped);
    });

    test('seek delegates to platform', () async {
      await BackgroundRuntime.initialize();
      await BackgroundRuntime.play(
        AudioTrack(id: 't', title: 'T', source: Uri.parse('https://example.com/t.mp3')),
      );
      await BackgroundRuntime.seek(const Duration(seconds: 30));
      // Seek triggers a player state update, but we just verify no error
    });

    test('observeDownloads returns stream', () async {
      await BackgroundRuntime.initialize();
      expect(BackgroundRuntime.observeDownloads(), isA<Stream<DownloadEvent>>());
    });

    test('observePlayer returns stream', () async {
      await BackgroundRuntime.initialize();
      expect(BackgroundRuntime.observePlayer(), isA<Stream<PlayerState>>());
    });

    test('observeLifecycle returns stream', () async {
      await BackgroundRuntime.initialize();
      expect(BackgroundRuntime.observeLifecycle(), isA<Stream<RuntimeLifecycle>>());
    });

    test('shutdown delegates to platform', () async {
      await BackgroundRuntime.initialize();
      await BackgroundRuntime.shutdown();
      // No exception means success
    });
  });
}
