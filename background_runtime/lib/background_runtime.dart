import 'dart:async';

import 'package:background_runtime_platform_interface/background_runtime_platform_interface.dart';

export 'package:background_runtime_platform_interface/background_runtime_platform_interface.dart'
    show
        DownloadRequest,
        DownloadEvent,
        DownloadState,
        AudioTrack,
        PlayerState,
        PlaybackState,
        BackgroundRuntimeConfig,
        RuntimeLifecycle,
        RuntimeLifecycleEvent;
export 'package:background_runtime_platform_interface/background_runtime_platform_interface.dart'
    show
        BackgroundRuntimeException,
        DownloadFailedException,
        StorageUnavailableException,
        PermissionDeniedException,
        NetworkUnavailableException,
        ServiceUnavailableException,
        TaskNotFoundException,
        NotInitializedException,
        UnsupportedPlatformException;

/// The public API for the background_runtime plugin.
///
/// All methods are static and delegate to the current
/// [BackgroundRuntimePlatform] implementation.
///
/// Example usage:
/// ```dart
/// import 'package:background_runtime/background_runtime.dart';
///
/// void main() async {
///   await BackgroundRuntime.initialize();
///
///   final taskId = await BackgroundRuntime.download(
///     DownloadRequest(
///       url: 'https://example.com/file.zip',
///       destinationPath: '/path/to/file.zip',
///     ),
///   );
///
///   BackgroundRuntime.observeDownloads().listen((event) {
///     print('Download $taskId: ${event.state} ${event.progress}%');
///   });
/// }
/// ```
abstract final class BackgroundRuntime {
  BackgroundRuntime._();

  static BackgroundRuntimePlatform get _platform =>
      BackgroundRuntimePlatform.instance;

  /// Initialize the background runtime.
  ///
  /// Call this once before using any other API. If [config] is not provided,
  /// default values are used.
  static Future<void> initialize({BackgroundRuntimeConfig? config}) {
    return _platform.initialize(config ?? const BackgroundRuntimeConfig());
  }

  /// Start a file download.
  ///
  /// Returns a unique [taskId] that can be used to track or control the
  /// download. Monitor progress via [observeDownloads].
  static Future<String> download(DownloadRequest request) {
    return _platform.startDownload(request);
  }

  /// Pause the download identified by [taskId].
  ///
  /// Does nothing if the download is already paused or not running.
  static Future<void> pause(String taskId) {
    return _platform.pauseDownload(taskId);
  }

  /// Resume the paused download identified by [taskId].
  static Future<void> resume(String taskId) {
    return _platform.resumeDownload(taskId);
  }

  /// Cancel the download identified by [taskId].
  ///
  /// Cancelled downloads cannot be resumed. Downloaded partial content may be
  /// deleted based on platform behavior.
  static Future<void> cancel(String taskId) {
    return _platform.cancelDownload(taskId);
  }

  /// Begin audio playback of [track] in the background.
  static Future<void> play(AudioTrack track) {
    return _platform.playAudio(track);
  }

  /// Pause the current audio playback.
  static Future<void> pauseAudio() {
    return _platform.pauseAudio();
  }

  /// Resume the current audio playback.
  static Future<void> resumeAudio() {
    return _platform.resumeAudio();
  }

  /// Stop the current audio playback.
  static Future<void> stop() {
    return _platform.stopAudio();
  }

  /// Seek to [position] in the current audio track.
  static Future<void> seek(Duration position) {
    return _platform.seekAudio(position);
  }

  /// A broadcast stream of download events.
  ///
  /// Emits [DownloadEvent] for every download lifecycle change including
  /// progress updates, pauses, completions, and failures.
  static Stream<DownloadEvent> observeDownloads() {
    return _platform.downloadEvents();
  }

  /// A broadcast stream of player state changes.
  ///
  /// Emits [PlayerState] whenever the audio player's state transitions.
  static Stream<PlayerState> observePlayer() {
    return _platform.playerState();
  }

  /// A broadcast stream of runtime lifecycle events.
  ///
  /// Emits [RuntimeLifecycle] when the runtime is initialized, started,
  /// paused, resumed, stopped, or terminated.
  static Stream<RuntimeLifecycle> observeLifecycle() {
    return _platform.lifecycleEvents();
  }

  /// Shut down the background runtime and release all native resources.
  ///
  /// After calling this, a new call to [initialize] is required to use the
  /// runtime again.
  static Future<void> shutdown() {
    return _platform.shutdown();
  }
}
