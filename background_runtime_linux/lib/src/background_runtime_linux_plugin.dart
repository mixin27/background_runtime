import 'dart:async';

import 'package:background_runtime_platform_interface/background_runtime_platform_interface.dart';
import 'package:flutter/services.dart';

/// Linux implementation of [BackgroundRuntimePlatform].
final class BackgroundRuntimeLinuxPlugin extends BackgroundRuntimePlatform {
  final MethodChannel _methodChannel;
  final EventChannel _downloadEventChannel;
  final EventChannel _playerStateChannel;
  final EventChannel _lifecycleEventChannel;

  BackgroundRuntimeLinuxPlugin({
    MethodChannel? methodChannel,
    EventChannel? downloadEventChannel,
    EventChannel? playerStateChannel,
    EventChannel? lifecycleEventChannel,
  })  : _methodChannel =
            methodChannel ??
            const MethodChannel('dev.mixin27.background_runtime/method'),
        _downloadEventChannel =
            downloadEventChannel ??
            const EventChannel(
                'dev.mixin27.background_runtime/downloadEvents'),
        _playerStateChannel =
            playerStateChannel ??
            const EventChannel(
                'dev.mixin27.background_runtime/playerState'),
        _lifecycleEventChannel =
            lifecycleEventChannel ??
            const EventChannel(
                'dev.mixin27.background_runtime/lifecycleEvents');

  @override
  Future<void> initialize(BackgroundRuntimeConfig config) async {
    await _methodChannel.invokeMethod<void>(
      'initialize',
      {'config': config.toMap()},
    );
  }

  @override
  Future<String> startDownload(DownloadRequest request) async {
    final result = await _methodChannel.invokeMethod<Map<String, dynamic>>(
      'startDownload',
      {'request': request.toMap()},
    );
    if (result == null || result['taskId'] == null) {
      throw const DownloadFailedException(message: 'Failed to start download.');
    }
    return result['taskId'] as String;
  }

  @override
  Future<void> pauseDownload(String taskId) async {
    await _methodChannel.invokeMethod<void>(
      'pauseDownload',
      {'taskId': taskId},
    );
  }

  @override
  Future<void> resumeDownload(String taskId) async {
    await _methodChannel.invokeMethod<void>(
      'resumeDownload',
      {'taskId': taskId},
    );
  }

  @override
  Future<void> cancelDownload(String taskId) async {
    await _methodChannel.invokeMethod<void>(
      'cancelDownload',
      {'taskId': taskId},
    );
  }

  @override
  Future<void> playAudio(AudioTrack track) async {
    await _methodChannel.invokeMethod<void>(
      'playAudio',
      {'track': track.toMap()},
    );
  }

  @override
  Future<void> pauseAudio() async {
    await _methodChannel.invokeMethod<void>('pauseAudio', {});
  }

  @override
  Future<void> resumeAudio() async {
    await _methodChannel.invokeMethod<void>('resumeAudio', {});
  }

  @override
  Future<void> stopAudio() async {
    await _methodChannel.invokeMethod<void>('stopAudio', {});
  }

  @override
  Future<void> seekAudio(Duration position) async {
    await _methodChannel.invokeMethod<void>(
      'seekAudio',
      {'positionMillis': position.inMilliseconds},
    );
  }

  @override
  Stream<DownloadEvent> downloadEvents() {
    return _downloadEventChannel
        .receiveBroadcastStream()
        .map((event) => DownloadEvent.fromMap(event as Map<String, dynamic>));
  }

  @override
  Stream<PlayerState> playerState() {
    return _playerStateChannel
        .receiveBroadcastStream()
        .map((event) => PlayerState.fromMap(event as Map<String, dynamic>));
  }

  @override
  Stream<RuntimeLifecycle> lifecycleEvents() {
    return _lifecycleEventChannel
        .receiveBroadcastStream()
        .map(
            (event) => RuntimeLifecycle.fromMap(event as Map<String, dynamic>));
  }

  @override
  Future<void> shutdown() async {
    await _methodChannel.invokeMethod<void>('shutdown', {});
  }
}
