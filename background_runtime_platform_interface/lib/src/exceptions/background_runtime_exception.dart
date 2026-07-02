/// Base exception for all background runtime errors.
class BackgroundRuntimeException implements Exception {
  final String code;
  final String message;
  final Object? cause;

  const BackgroundRuntimeException({
    required this.code,
    required this.message,
    this.cause,
  });

  @override
  String toString() => 'BackgroundRuntimeException($code): $message';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackgroundRuntimeException &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          message == other.message;

  @override
  int get hashCode => Object.hash(code, message);
}

/// Thrown when a download operation fails.
final class DownloadFailedException extends BackgroundRuntimeException {
  const DownloadFailedException({
    super.code = 'DOWNLOAD_FAILED',
    required super.message,
    super.cause,
  });
}

/// Thrown when storage is unavailable or full.
final class StorageUnavailableException extends BackgroundRuntimeException {
  const StorageUnavailableException({
    super.code = 'STORAGE_UNAVAILABLE',
    required super.message,
    super.cause,
  });
}

/// Thrown when the user denies a required permission.
final class PermissionDeniedException extends BackgroundRuntimeException {
  const PermissionDeniedException({
    super.code = 'PERMISSION_DENIED',
    required super.message,
    super.cause,
  });
}

/// Thrown when the network is unavailable.
final class NetworkUnavailableException extends BackgroundRuntimeException {
  const NetworkUnavailableException({
    super.code = 'NETWORK_UNAVAILABLE',
    required super.message,
    super.cause,
  });
}

/// Thrown when a required background service is not available.
final class ServiceUnavailableException extends BackgroundRuntimeException {
  const ServiceUnavailableException({
    super.code = 'SERVICE_UNAVAILABLE',
    required super.message,
    super.cause,
  });
}

/// Thrown when a task with the given ID is not found.
final class TaskNotFoundException extends BackgroundRuntimeException {
  const TaskNotFoundException({
    super.code = 'TASK_NOT_FOUND',
    required super.message,
    super.cause,
  });
}

/// Thrown when the runtime is not initialized.
final class NotInitializedException extends BackgroundRuntimeException {
  const NotInitializedException({
    super.code = 'NOT_INITIALIZED',
    super.message = 'BackgroundRuntime has not been initialized.',
    super.cause,
  });
}

/// Thrown when an operation is not supported on the current platform.
final class UnsupportedPlatformException extends BackgroundRuntimeException {
  const UnsupportedPlatformException({
    super.code = 'UNSUPPORTED_PLATFORM',
    required super.message,
    super.cause,
  });
}
