import 'package:background_runtime_platform_interface/background_runtime_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlaybackState', () {
    test('fromString returns correct enum', () {
      expect(PlaybackState.fromString('idle'), PlaybackState.idle);
      expect(PlaybackState.fromString('loading'), PlaybackState.loading);
      expect(PlaybackState.fromString('playing'), PlaybackState.playing);
      expect(PlaybackState.fromString('paused'), PlaybackState.paused);
      expect(PlaybackState.fromString('stopped'), PlaybackState.stopped);
      expect(PlaybackState.fromString('completed'), PlaybackState.completed);
      expect(PlaybackState.fromString('failed'), PlaybackState.failed);
    });

    test('fromString defaults to idle for unknown', () {
      expect(PlaybackState.fromString('unknown'), PlaybackState.idle);
    });
  });

  group('PlayerState', () {
    test('creates with required fields', () {
      const state = PlayerState(state: PlaybackState.idle);
      expect(state.state, PlaybackState.idle);
      expect(state.trackId, isNull);
      expect(state.position, isNull);
    });

    test('creates with all fields', () {
      const state = PlayerState(
        state: PlaybackState.playing,
        trackId: 'track_1',
        position: Duration(seconds: 30),
        duration: Duration(seconds: 180),
      );
      expect(state.trackId, 'track_1');
      expect(state.position, const Duration(seconds: 30));
      expect(state.duration, const Duration(seconds: 180));
    });

    test('serializes to map and back', () {
      const original = PlayerState(
        state: PlaybackState.playing,
        trackId: 'track_1',
        position: Duration(seconds: 30),
        duration: Duration(seconds: 180),
      );
      final map = original.toMap();
      final restored = PlayerState.fromMap(map);
      expect(restored, equals(original));
    });

    test('value equality', () {
      const a = PlayerState(
        state: PlaybackState.playing,
        trackId: 'track_1',
      );
      const b = PlayerState(
        state: PlaybackState.playing,
        trackId: 'track_1',
      );
      expect(a, equals(b));
    });

    test('toString contains state and trackId', () {
      const state = PlayerState(
        state: PlaybackState.playing,
        trackId: 'track_1',
      );
      expect(state.toString(), contains('playing'));
      expect(state.toString(), contains('track_1'));
    });
  });
}
