/// Configuration for initializing the background runtime.
final class BackgroundRuntimeConfig {
  final bool enableDownloads;
  final bool enableAudio;
  final bool enableForegroundService;
  final bool enableNotifications;
  final String? notificationChannelId;
  final String? notificationChannelName;

  const BackgroundRuntimeConfig({
    this.enableDownloads = true,
    this.enableAudio = true,
    this.enableForegroundService = true,
    this.enableNotifications = true,
    this.notificationChannelId,
    this.notificationChannelName,
  });

  Map<String, dynamic> toMap() {
    return {
      'enableDownloads': enableDownloads,
      'enableAudio': enableAudio,
      'enableForegroundService': enableForegroundService,
      'enableNotifications': enableNotifications,
      'notificationChannelId': notificationChannelId,
      'notificationChannelName': notificationChannelName,
    };
  }

  static BackgroundRuntimeConfig fromMap(Map<String, dynamic> map) {
    return BackgroundRuntimeConfig(
      enableDownloads: map['enableDownloads'] as bool? ?? true,
      enableAudio: map['enableAudio'] as bool? ?? true,
      enableForegroundService:
          map['enableForegroundService'] as bool? ?? true,
      enableNotifications: map['enableNotifications'] as bool? ?? true,
      notificationChannelId: map['notificationChannelId'] as String?,
      notificationChannelName: map['notificationChannelName'] as String?,
    );
  }

  BackgroundRuntimeConfig copyWith({
    bool? enableDownloads,
    bool? enableAudio,
    bool? enableForegroundService,
    bool? enableNotifications,
    String? notificationChannelId,
    String? notificationChannelName,
  }) {
    return BackgroundRuntimeConfig(
      enableDownloads: enableDownloads ?? this.enableDownloads,
      enableAudio: enableAudio ?? this.enableAudio,
      enableForegroundService:
          enableForegroundService ?? this.enableForegroundService,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      notificationChannelId:
          notificationChannelId ?? this.notificationChannelId,
      notificationChannelName:
          notificationChannelName ?? this.notificationChannelName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackgroundRuntimeConfig &&
          runtimeType == other.runtimeType &&
          enableDownloads == other.enableDownloads &&
          enableAudio == other.enableAudio &&
          enableForegroundService == other.enableForegroundService &&
          enableNotifications == other.enableNotifications &&
          notificationChannelId == other.notificationChannelId &&
          notificationChannelName == other.notificationChannelName;

  @override
  int get hashCode => Object.hash(
        enableDownloads,
        enableAudio,
        enableForegroundService,
        enableNotifications,
        notificationChannelId,
        notificationChannelName,
      );

  @override
  String toString() =>
      'BackgroundRuntimeConfig(enableDownloads: $enableDownloads, enableAudio: $enableAudio)';
}
