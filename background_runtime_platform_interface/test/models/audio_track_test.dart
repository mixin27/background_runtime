import 'package:flutter_test/flutter_test.dart';
import 'package:background_runtime_platform_interface/background_runtime_platform_interface.dart';

void main() {
  group('AudioTrack', () {
    test('creates with required fields', () {
      final track = AudioTrack(
        id: 'track_1',
        title: 'Song Title',
        source: Uri.parse('https://example.com/song.mp3'),
      );
      expect(track.id, 'track_1');
      expect(track.title, 'Song Title');
      expect(track.artist, isNull);
      expect(track.duration, isNull);
    });

    test('creates with optional fields', () {
      final track = AudioTrack(
        id: 'track_1',
        title: 'Song Title',
        artist: 'Artist Name',
        album: 'Album Name',
        source: Uri.parse('https://example.com/song.mp3'),
        duration: const Duration(seconds: 180),
        headers: {'Authorization': 'Bearer token'},
      );
      expect(track.artist, 'Artist Name');
      expect(track.album, 'Album Name');
      expect(track.duration, const Duration(seconds: 180));
    });

    test('serializes to map and back', () {
      final original = AudioTrack(
        id: 'track_1',
        title: 'Song Title',
        artist: 'Artist',
        album: 'Album',
        source: Uri.parse('https://example.com/song.mp3'),
        duration: const Duration(seconds: 180),
        headers: {'Authorization': 'Bearer token'},
      );
      final map = original.toMap();
      final restored = AudioTrack.fromMap(map);
      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.artist, original.artist);
      expect(restored.album, original.album);
      expect(restored.source, original.source);
      expect(restored.duration, original.duration);
      expect(restored.headers, original.headers);
    });

    test('value equality', () {
      final a = AudioTrack(
        id: 'track_1',
        title: 'Song',
        source: Uri.parse('https://example.com/song.mp3'),
      );
      final b = AudioTrack(
        id: 'track_1',
        title: 'Song',
        source: Uri.parse('https://example.com/song.mp3'),
      );
      expect(a, equals(b));
    });

    test('toString contains id and title', () {
      final track = AudioTrack(
        id: 'track_1',
        title: 'My Song',
        source: Uri.parse('https://example.com/song.mp3'),
      );
      expect(track.toString(), contains('track_1'));
      expect(track.toString(), contains('My Song'));
    });
  });
}
