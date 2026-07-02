/// Represents an audio track for background playback.
final class AudioTrack {
  final String id;
  final String title;
  final String? artist;
  final String? album;
  final Uri source;
  final Duration? duration;
  final Map<String, String>? headers;

  const AudioTrack({
    required this.id,
    required this.title,
    this.artist,
    this.album,
    required this.source,
    this.duration,
    this.headers,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'source': source.toString(),
      'durationMillis': duration?.inMilliseconds,
      'headers': headers,
    };
  }

  static AudioTrack fromMap(Map<String, dynamic> map) {
    return AudioTrack(
      id: map['id'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String?,
      album: map['album'] as String?,
      source: Uri.parse(map['source'] as String),
      duration: map['durationMillis'] != null
          ? Duration(milliseconds: map['durationMillis'] as int)
          : null,
      headers: (map['headers'] as Map<String, dynamic>?)
          ?.cast<String, String>(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioTrack &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          artist == other.artist &&
          album == other.album &&
          source == other.source &&
          duration == other.duration &&
          headers == other.headers;

  @override
  int get hashCode =>
      Object.hash(id, title, artist, album, source, duration, headers);

  @override
  String toString() =>
      'AudioTrack(id: $id, title: $title, artist: $artist)';
}
