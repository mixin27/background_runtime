import 'dart:async';
import 'dart:html' as html;

import 'package:background_runtime_platform_interface/background_runtime_platform_interface.dart';

/// Web implementation of [BackgroundRuntimePlatform].
///
/// Web support is best-effort. Background execution is limited by browser
/// capabilities. Downloads use the Fetch API and Streams API where available.
/// Audio playback uses the HTMLAudioElement API.
///
/// Known limitations:
/// - No true background execution (browsers do not support it)
/// - No foreground service concept
/// - No persistent notifications
/// - Downloads may not survive page navigation
/// - Audio playback stops when the page is hidden on mobile
final class BackgroundRuntimeWebPlugin extends BackgroundRuntimePlatform {
  final _downloadController = StreamController<DownloadEvent>.broadcast();
  final _playerStateController = StreamController<PlayerState>.broadcast();
  final _lifecycleController = StreamController<RuntimeLifecycle>.broadcast();

  bool _initialized = false;

  @override
  Future<void> initialize(BackgroundRuntimeConfig config) async {
    _initialized = true;
    _lifecycleController.add(
      RuntimeLifecycle(
        event: RuntimeLifecycleEvent.initialized,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  Future<String> startDownload(DownloadRequest request) async {
    _ensureInitialized();

    final taskId = _generateTaskId();
    _downloadController.add(
      DownloadEvent(
        taskId: taskId,
        url: request.url,
        state: DownloadState.pending,
      ),
    );

    try {
      final response = await html.HttpRequest.request(
        request.url,
        method: 'GET',
        responseType: 'blob',
      );

      _downloadController.add(
        DownloadEvent(
          taskId: taskId,
          url: request.url,
          state: DownloadState.downloading,
          progress: 50.0,
          bytesReceived: response.response?.toString().length,
        ),
      );

      final blob = response.response as html.Blob;
      final objectUrl = html.Url.createObjectUrl(blob);
      html.AnchorElement(href: objectUrl)
        ..download = request.destinationPath.split('/').last
        ..click();
      html.Url.revokeObjectUrl(objectUrl);

      _downloadController.add(
        DownloadEvent(
          taskId: taskId,
          url: request.url,
          state: DownloadState.completed,
          progress: 100.0,
        ),
      );

      return taskId;
    } catch (e) {
      _downloadController.add(
        DownloadEvent(
          taskId: taskId,
          url: request.url,
          state: DownloadState.failed,
          errorCode: 'DOWNLOAD_FAILED',
          errorMessage: e.toString(),
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> pauseDownload(String taskId) async {
    _ensureInitialized();
      throw const UnsupportedPlatformException(
      message: 'Pause/resume is not supported on the web platform.',
    );
  }

  @override
  Future<void> resumeDownload(String taskId) async {
    _ensureInitialized();
    throw const UnsupportedPlatformException(
      message: 'Pause/resume is not supported on the web platform.',
    );
  }

  @override
  Future<void> cancelDownload(String taskId) async {
    _ensureInitialized();
    _downloadController.add(
      DownloadEvent(
        taskId: taskId,
        url: '',
        state: DownloadState.cancelled,
      ),
    );
  }

  @override
  Future<void> playAudio(AudioTrack track) async {
    _ensureInitialized();
    final audioElement = html.AudioElement()
      ..src = track.source.toString()
      ..autoplay = true;
    html.document.body?.append(audioElement);

    _playerStateController.add(
      PlayerState(state: PlaybackState.playing, trackId: track.id),
    );
  }

  @override
  Future<void> pauseAudio() async {
    final elements = html.document.querySelectorAll('audio');
    for (final element in elements) {
      (element as html.AudioElement).pause();
    }
    _playerStateController.add(
      const PlayerState(state: PlaybackState.paused),
    );
  }

  @override
  Future<void> resumeAudio() async {
    final elements = html.document.querySelectorAll('audio');
    for (final element in elements) {
      (element as html.AudioElement).play();
    }
    _playerStateController.add(
      const PlayerState(state: PlaybackState.playing),
    );
  }

  @override
  Future<void> stopAudio() async {
    final elements = html.document.querySelectorAll('audio');
    for (final element in elements) {
      final audio = element as html.AudioElement;
      audio.pause();
      audio.remove();
    }
    _playerStateController.add(
      const PlayerState(state: PlaybackState.stopped),
    );
  }

  @override
  Future<void> seekAudio(Duration position) async {
    final elements = html.document.querySelectorAll('audio');
    for (final element in elements) {
      (element as html.AudioElement).currentTime =
          position.inMilliseconds / 1000;
    }
    _playerStateController.add(
      PlayerState(state: PlaybackState.playing, position: position),
    );
  }

  @override
  Stream<DownloadEvent> downloadEvents() {
    return _downloadController.stream;
  }

  @override
  Stream<PlayerState> playerState() {
    return _playerStateController.stream;
  }

  @override
  Stream<RuntimeLifecycle> lifecycleEvents() {
    return _lifecycleController.stream;
  }

  @override
  Future<void> shutdown() async {
    _initialized = false;
    _lifecycleController.add(
      RuntimeLifecycle(
        event: RuntimeLifecycleEvent.terminated,
        timestamp: DateTime.now(),
      ),
    );
    await _downloadController.close();
    await _playerStateController.close();
    await _lifecycleController.close();
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw const NotInitializedException();
    }
  }

  static int _nextTaskId = 0;

  static String _generateTaskId() {
    _nextTaskId++;
    return 'web_${DateTime.now().millisecondsSinceEpoch}_$_nextTaskId';
  }
}
