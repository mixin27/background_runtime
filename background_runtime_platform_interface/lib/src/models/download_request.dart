/// Parameters for starting a file download task.
///
/// By default files are saved to the [destinationPath] in app-private storage.
/// Set [saveToPublic] to `true` to save to a user-visible public directory
/// (e.g., the Downloads folder on Android/iOS, ~/Downloads on desktop).
/// When [saveToPublic] is `true`, [destinationPath] is treated as a relative
/// filename and the platform resolves the appropriate public directory.
final class DownloadRequest {
  final String url;
  final String destinationPath;
  final Map<String, String>? headers;
  final bool allowCellular;
  final bool allowMetered;
  final bool saveToPublic;

  const DownloadRequest({
    required this.url,
    required this.destinationPath,
    this.headers,
    this.allowCellular = true,
    this.allowMetered = true,
    this.saveToPublic = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'destinationPath': destinationPath,
      'headers': headers,
      'allowCellular': allowCellular,
      'allowMetered': allowMetered,
      'saveToPublic': saveToPublic,
    };
  }

  static DownloadRequest fromMap(Map<String, dynamic> map) {
    return DownloadRequest(
      url: map['url'] as String,
      destinationPath: map['destinationPath'] as String,
      headers: (map['headers'] as Map<String, dynamic>?)
          ?.cast<String, String>(),
      allowCellular: map['allowCellular'] as bool? ?? true,
      allowMetered: map['allowMetered'] as bool? ?? true,
      saveToPublic: map['saveToPublic'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadRequest &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          destinationPath == other.destinationPath &&
          headers == other.headers &&
          allowCellular == other.allowCellular &&
          allowMetered == other.allowMetered &&
          saveToPublic == other.saveToPublic;

  @override
  int get hashCode =>
      Object.hash(url, destinationPath, headers, allowCellular, allowMetered,
          saveToPublic);

  @override
  String toString() =>
      'DownloadRequest(url: $url, destinationPath: $destinationPath)';
}
