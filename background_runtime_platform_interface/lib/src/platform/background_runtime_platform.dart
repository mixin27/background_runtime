import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../method_channel/method_channel_background_runtime.dart';
import '../models/audio_track.dart';
import '../models/download_event.dart';
import '../models/download_request.dart';
import '../models/player_state.dart';
import '../models/runtime_config.dart';
import '../models/runtime_lifecycle.dart';

/// The platform interface that all platform implementations must conform to.
///
/// Platform implementations should extend this class and register themselves
/// by setting [instance] to their implementation during app initialization.
abstract class BackgroundRuntimePlatform extends PlatformInterface {
  BackgroundRuntimePlatform() : super(token: _token);

  static final Object _token = Object();

  static BackgroundRuntimePlatform _instance =
      MethodChannelBackgroundRuntime();

  /// The current platform implementation.
  ///
  /// Defaults to [MethodChannelBackgroundRuntime] which communicates with
  /// native platform code via Flutter's method and event channels.
  static BackgroundRuntimePlatform get instance => _instance;

  /// Sets the platform implementation.
  ///
  /// Throws [AssertionError] if [instance] does not extend
  /// [BackgroundRuntimePlatform].
  static set instance(BackgroundRuntimePlatform instance) {
    PlatformInterface.verify(instance, BackgroundRuntimePlatform);
    _instance = instance;
  }

  /// Initialize the background runtime with [config].
  Future<void> initialize(BackgroundRuntimeConfig config);

  /// Start a file download described by [request].
  /// Returns a unique task identifier.
  Future<String> startDownload(DownloadRequest request);

  /// Pause the download identified by [taskId].
  Future<void> pauseDownload(String taskId);

  /// Resume the download identified by [taskId].
  Future<void> resumeDownload(String taskId);

  /// Cancel the download identified by [taskId].
  Future<void> cancelDownload(String taskId);

  /// Begin audio playback of the given [track].
  Future<void> playAudio(AudioTrack track);

  /// Pause the current audio playback.
  Future<void> pauseAudio();

  /// Resume the current audio playback.
  Future<void> resumeAudio();

  /// Stop the current audio playback.
  Future<void> stopAudio();

  /// Seek to [position] in the current audio track.
  Future<void> seekAudio(Duration position);

  /// A broadcast stream of download progress and state events.
  Stream<DownloadEvent> downloadEvents();

  /// A broadcast stream of player state changes.
  Stream<PlayerState> playerState();

  /// A broadcast stream of runtime lifecycle events.
  Stream<RuntimeLifecycle> lifecycleEvents();

  /// Shut down the background runtime and release all resources.
  Future<void> shutdown();
}
