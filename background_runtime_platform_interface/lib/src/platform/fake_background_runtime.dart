import 'dart:async';

import '../exceptions/background_runtime_exception.dart';
import '../models/download_request.dart';
import '../models/download_event.dart';
import '../models/audio_track.dart';
import '../models/player_state.dart';
import '../models/runtime_config.dart';
import '../models/runtime_lifecycle.dart';
import 'background_runtime_platform.dart';

/// An in-memory fake implementation of [BackgroundRuntimePlatform] for
/// unit testing.
///
/// All operations are simulated and emit events through the standard stream
/// APIs. No native code is invoked.
final class FakeBackgroundRuntime extends BackgroundRuntimePlatform {
  final _downloadController = StreamController<DownloadEvent>.broadcast();
  final _playerController = StreamController<PlayerState>.broadcast();
  final _lifecycleController = StreamController<RuntimeLifecycle>.broadcast();

  bool _initialized = false;
  final _downloads = <String, _FakeDownload>{};
  final _config = _FakeConfig();

  @override
  Future<void> initialize(BackgroundRuntimeConfig config) async {
    _initialized = true;
    _config.enableDownloads = config.enableDownloads;
    _config.enableAudio = config.enableAudio;
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
    final taskId = 'fake_${_downloads.length + 1}';
    _downloads[taskId] = _FakeDownload(
      request: request,
      state: DownloadState.downloading,
    );
    _downloadController.add(
      DownloadEvent(
        taskId: taskId,
        url: request.url,
        state: DownloadState.downloading,
        progress: 0.0,
      ),
    );
    _simulateDownload(taskId, request);
    return taskId;
  }

  Future<void> _simulateDownload(String taskId, DownloadRequest request) async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (_downloads[taskId]?.state == DownloadState.cancelled) return;
    _downloads[taskId] = _FakeDownload(
      request: request,
      state: DownloadState.completed,
    );
    _downloadController.add(
      DownloadEvent(
        taskId: taskId,
        url: request.url,
        state: DownloadState.completed,
        progress: 100.0,
      ),
    );
  }

  @override
  Future<void> pauseDownload(String taskId) async {
    _ensureInitialized();
    final download = _downloads[taskId];
    if (download == null) throw TaskNotFoundException(message: 'Task $taskId not found');
    _downloads[taskId] = _FakeDownload(
      request: download.request,
      state: DownloadState.paused,
    );
    _downloadController.add(
      DownloadEvent(
        taskId: taskId,
        url: download.request.url,
        state: DownloadState.paused,
        progress: 50.0,
      ),
    );
  }

  @override
  Future<void> resumeDownload(String taskId) async {
    _ensureInitialized();
    final download = _downloads[taskId];
    if (download == null) throw TaskNotFoundException(message: 'Task $taskId not found');
    if (download.state != DownloadState.paused) return;
    _downloads[taskId] = _FakeDownload(
      request: download.request,
      state: DownloadState.downloading,
    );
    _downloadController.add(
      DownloadEvent(
        taskId: taskId,
        url: download.request.url,
        state: DownloadState.downloading,
        progress: 50.0,
      ),
    );
    _simulateDownload(taskId, download.request);
  }

  @override
  Future<void> cancelDownload(String taskId) async {
    _ensureInitialized();
    final download = _downloads[taskId];
    if (download == null) throw TaskNotFoundException(message: 'Task $taskId not found');
    _downloads[taskId] = _FakeDownload(
      request: download.request,
      state: DownloadState.cancelled,
    );
    _downloadController.add(
      DownloadEvent(
        taskId: taskId,
        url: download.request.url,
        state: DownloadState.cancelled,
      ),
    );
  }

  @override
  Future<void> playAudio(AudioTrack track) async {
    _ensureInitialized();
    _config.currentTrack = track;
    _playerController.add(
      PlayerState(
        state: PlaybackState.playing,
        trackId: track.id,
        duration: track.duration,
      ),
    );
  }

  @override
  Future<void> pauseAudio() async {
    _ensureInitialized();
    _playerController.add(
      PlayerState(state: PlaybackState.paused, trackId: _config.currentTrack?.id),
    );
  }

  @override
  Future<void> resumeAudio() async {
    _ensureInitialized();
    _playerController.add(
      PlayerState(state: PlaybackState.playing, trackId: _config.currentTrack?.id),
    );
  }

  @override
  Future<void> stopAudio() async {
    _ensureInitialized();
    _playerController.add(const PlayerState(state: PlaybackState.stopped));
    _config.currentTrack = null;
  }

  @override
  Future<void> seekAudio(Duration position) async {
    _ensureInitialized();
    _playerController.add(
      PlayerState(
        state: PlaybackState.playing,
        trackId: _config.currentTrack?.id,
        position: position,
      ),
    );
  }

  @override
  Stream<DownloadEvent> downloadEvents() => _downloadController.stream;

  @override
  Stream<PlayerState> playerState() => _playerController.stream;

  @override
  Stream<RuntimeLifecycle> lifecycleEvents() => _lifecycleController.stream;

  @override
  Future<void> shutdown() async {
    _initialized = false;
    _downloads.clear();
    _config.currentTrack = null;
    _lifecycleController.add(
      RuntimeLifecycle(
        event: RuntimeLifecycleEvent.terminated,
        timestamp: DateTime.now(),
      ),
    );
    await Future.wait([
      _downloadController.close(),
      _playerController.close(),
      _lifecycleController.close(),
    ]);
  }

  void _ensureInitialized() {
    if (!_initialized) throw NotInitializedException();
  }
}

class _FakeDownload {
  final DownloadRequest request;
  final DownloadState state;

  const _FakeDownload({required this.request, required this.state});
}

class _FakeConfig {
  bool enableDownloads = true;
  bool enableAudio = true;
  AudioTrack? currentTrack;
}
