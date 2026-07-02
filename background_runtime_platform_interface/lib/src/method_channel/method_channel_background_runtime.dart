import 'dart:async';

import 'package:flutter/services.dart';

import '../exceptions/background_runtime_exception.dart';
import '../models/audio_track.dart';
import '../models/download_event.dart';
import '../models/download_request.dart';
import '../models/player_state.dart';
import '../models/runtime_config.dart';
import '../models/runtime_lifecycle.dart';
import '../platform/background_runtime_platform.dart';

/// Method channel names.
const _methodChannelName = 'dev.mixin27.background_runtime/method';
const _downloadEventChannelName = 'dev.mixin27.background_runtime/downloadEvents';
const _playerStateChannelName = 'dev.mixin27.background_runtime/playerState';
const _lifecycleEventChannelName =
    'dev.mixin27.background_runtime/lifecycleEvents';

/// The default [BackgroundRuntimePlatform] that communicates with native code
/// via Flutter's [MethodChannel] and [EventChannel].
final class MethodChannelBackgroundRuntime extends BackgroundRuntimePlatform {
  final MethodChannel _methodChannel;
  final EventChannel _downloadEventChannel;
  final EventChannel _playerStateChannel;
  final EventChannel _lifecycleEventChannel;

  MethodChannelBackgroundRuntime({
    MethodChannel? methodChannel,
    EventChannel? downloadEventChannel,
    EventChannel? playerStateChannel,
    EventChannel? lifecycleEventChannel,
  })  : _methodChannel =
            methodChannel ?? const MethodChannel(_methodChannelName),
        _downloadEventChannel =
            downloadEventChannel ?? const EventChannel(_downloadEventChannelName),
        _playerStateChannel =
            playerStateChannel ?? const EventChannel(_playerStateChannelName),
        _lifecycleEventChannel =
            lifecycleEventChannel ?? const EventChannel(_lifecycleEventChannelName);

  @override
  Future<void> initialize(BackgroundRuntimeConfig config) async {
    await _callMethod('initialize', {'config': config.toMap()});
  }

  @override
  Future<String> startDownload(DownloadRequest request) async {
    final result = await _callMethod(
      'startDownload',
      {'request': request.toMap()},
    );
    return result['taskId'] as String;
  }

  @override
  Future<void> pauseDownload(String taskId) async {
    await _callMethod('pauseDownload', {'taskId': taskId});
  }

  @override
  Future<void> resumeDownload(String taskId) async {
    await _callMethod('resumeDownload', {'taskId': taskId});
  }

  @override
  Future<void> cancelDownload(String taskId) async {
    await _callMethod('cancelDownload', {'taskId': taskId});
  }

  @override
  Future<void> playAudio(AudioTrack track) async {
    await _callMethod('playAudio', {'track': track.toMap()});
  }

  @override
  Future<void> pauseAudio() async {
    await _callMethod('pauseAudio', {});
  }

  @override
  Future<void> resumeAudio() async {
    await _callMethod('resumeAudio', {});
  }

  @override
  Future<void> stopAudio() async {
    await _callMethod('stopAudio', {});
  }

  @override
  Future<void> seekAudio(Duration position) async {
    await _callMethod(
      'seekAudio',
      {'positionMillis': position.inMilliseconds},
    );
  }

  @override
  Stream<DownloadEvent> downloadEvents() {
    return _downloadEventChannel
        .receiveBroadcastStream()
        .map((event) => DownloadEvent.fromMap((event as Map).cast<String, dynamic>()));
  }

  @override
  Stream<PlayerState> playerState() {
    return _playerStateChannel
        .receiveBroadcastStream()
        .map((event) => PlayerState.fromMap((event as Map).cast<String, dynamic>()));
  }

  @override
  Stream<RuntimeLifecycle> lifecycleEvents() {
    return _lifecycleEventChannel
        .receiveBroadcastStream()
        .map(
            (event) => RuntimeLifecycle.fromMap((event as Map).cast<String, dynamic>()));
  }

  @override
  Future<void> shutdown() async {
    await _callMethod('shutdown', {});
  }

  Future<Map<String, dynamic>> _callMethod(
    String method,
    Map<String, dynamic> arguments,
  ) async {
    try {
      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        method,
        arguments,
      );
      return result?.cast<String, dynamic>() ?? const {};
    } on PlatformException catch (e) {
      throw _decodeException(e);
    } on MissingPluginException {
      throw const ServiceUnavailableException(
        message: 'Background runtime is not implemented on this platform.',
      );
    }
  }

  BackgroundRuntimeException _decodeException(PlatformException e) {
    final code = e.code;
    final message = e.message ?? 'An unknown error occurred.';
    final details = e.details as Map<String, dynamic>?;
    final cause = details?['cause'];

    switch (code) {
      case 'DOWNLOAD_FAILED':
        return DownloadFailedException(message: message, cause: cause);
      case 'STORAGE_UNAVAILABLE':
        return StorageUnavailableException(message: message, cause: cause);
      case 'PERMISSION_DENIED':
        return PermissionDeniedException(message: message, cause: cause);
      case 'NETWORK_UNAVAILABLE':
        return NetworkUnavailableException(message: message, cause: cause);
      case 'SERVICE_UNAVAILABLE':
        return ServiceUnavailableException(message: message, cause: cause);
      case 'TASK_NOT_FOUND':
        return TaskNotFoundException(message: message, cause: cause);
      case 'NOT_INITIALIZED':
        return NotInitializedException(cause: cause);
      case 'UNSUPPORTED_PLATFORM':
        return UnsupportedPlatformException(message: message, cause: cause);
      default:
        return BackgroundRuntimeException(code: code, message: message, cause: cause);
    }
  }
}
