/// The current state of a download task.
enum DownloadState {
  pending,
  downloading,
  paused,
  completed,
  failed,
  cancelled;

  static DownloadState fromString(String value) {
    return DownloadState.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DownloadState.failed,
    );
  }
}

/// An event emitted during the lifecycle of a download task.
final class DownloadEvent {
  final String taskId;
  final String? url;
  final DownloadState state;
  final double? progress;
  final int? bytesReceived;
  final int? totalBytes;
  final String? errorCode;
  final String? errorMessage;

  const DownloadEvent({
    required this.taskId,
    this.url,
    required this.state,
    this.progress,
    this.bytesReceived,
    this.totalBytes,
    this.errorCode,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      if (url != null) 'url': url,
      'state': state.name,
      if (progress != null) 'progress': progress,
      if (bytesReceived != null) 'bytesReceived': bytesReceived,
      if (totalBytes != null) 'totalBytes': totalBytes,
      if (errorCode != null) 'errorCode': errorCode,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  static DownloadEvent fromMap(Map<String, dynamic> map) {
    return DownloadEvent(
      taskId: map['taskId'] as String,
      url: map['url'] as String?,
      state: DownloadState.fromString(map['state'] as String),
      progress: (map['progress'] as num?)?.toDouble(),
      bytesReceived: map['bytesReceived'] as int?,
      totalBytes: map['totalBytes'] as int?,
      errorCode: map['errorCode'] as String?,
      errorMessage: map['errorMessage'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadEvent &&
          runtimeType == other.runtimeType &&
          taskId == other.taskId &&
          url == other.url &&
          state == other.state &&
          progress == other.progress &&
          bytesReceived == other.bytesReceived &&
          totalBytes == other.totalBytes &&
          errorCode == other.errorCode &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(
        taskId,
        url,
        state,
        progress,
        bytesReceived,
        totalBytes,
        errorCode,
        errorMessage,
      );

  @override
  String toString() =>
      'DownloadEvent(taskId: $taskId, url: $url, state: $state, progress: $progress)';
}
