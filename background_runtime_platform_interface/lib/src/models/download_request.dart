/// Parameters for starting a file download task.
final class DownloadRequest {
  final String url;
  final String destinationPath;
  final Map<String, String>? headers;
  final bool allowCellular;
  final bool allowMetered;

  const DownloadRequest({
    required this.url,
    required this.destinationPath,
    this.headers,
    this.allowCellular = true,
    this.allowMetered = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'destinationPath': destinationPath,
      'headers': headers,
      'allowCellular': allowCellular,
      'allowMetered': allowMetered,
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
          allowMetered == other.allowMetered;

  @override
  int get hashCode =>
      Object.hash(url, destinationPath, headers, allowCellular, allowMetered);

  @override
  String toString() =>
      'DownloadRequest(url: $url, destinationPath: $destinationPath)';
}
