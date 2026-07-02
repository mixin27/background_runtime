/// The current state of the audio player.
enum PlaybackState {
  idle,
  loading,
  playing,
  paused,
  stopped,
  completed,
  failed;

  static PlaybackState fromString(String value) {
    return PlaybackState.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PlaybackState.idle,
    );
  }
}

/// Represents the current state of audio playback.
final class PlayerState {
  final PlaybackState state;
  final String? trackId;
  final Duration? position;
  final Duration? duration;
  final String? errorCode;
  final String? errorMessage;

  const PlayerState({
    required this.state,
    this.trackId,
    this.position,
    this.duration,
    this.errorCode,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'state': state.name,
      'trackId': trackId,
      'positionMillis': position?.inMilliseconds,
      'durationMillis': duration?.inMilliseconds,
      'errorCode': errorCode,
      'errorMessage': errorMessage,
    };
  }

  static PlayerState fromMap(Map<String, dynamic> map) {
    return PlayerState(
      state: PlaybackState.fromString(map['state'] as String),
      trackId: map['trackId'] as String?,
      position: map['positionMillis'] != null
          ? Duration(milliseconds: map['positionMillis'] as int)
          : null,
      duration: map['durationMillis'] != null
          ? Duration(milliseconds: map['durationMillis'] as int)
          : null,
      errorCode: map['errorCode'] as String?,
      errorMessage: map['errorMessage'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerState &&
          runtimeType == other.runtimeType &&
          state == other.state &&
          trackId == other.trackId &&
          position == other.position &&
          duration == other.duration &&
          errorCode == other.errorCode &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      Object.hash(state, trackId, position, duration, errorCode, errorMessage);

  @override
  String toString() =>
      'PlayerState(state: $state, trackId: $trackId, position: $position)';
}
