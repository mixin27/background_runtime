import 'package:background_runtime_platform_interface/background_runtime_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackgroundRuntimeException', () {
    test('creates with code and message', () {
      const e = BackgroundRuntimeException(
        code: 'TEST_ERROR',
        message: 'Test message',
      );
      expect(e.code, 'TEST_ERROR');
      expect(e.message, 'Test message');
      expect(e.cause, isNull);
    });

    test('creates with cause', () {
      final cause = Exception('root cause');
      final e = BackgroundRuntimeException(
        code: 'TEST_ERROR',
        message: 'Test message',
        cause: cause,
      );
      expect(e.cause, cause);
    });

    test('toString contains code and message', () {
      const e = BackgroundRuntimeException(
        code: 'TEST_ERROR',
        message: 'Something went wrong',
      );
      expect(e.toString(), contains('TEST_ERROR'));
      expect(e.toString(), contains('Something went wrong'));
    });

    test('value equality', () {
      const a = BackgroundRuntimeException(code: 'ERR', message: 'msg');
      const b = BackgroundRuntimeException(code: 'ERR', message: 'msg');
      expect(a, equals(b));
    });
  });

  group('typed exceptions', () {
    test('DownloadFailedException', () {
      const e = DownloadFailedException(message: 'Download failed');
      expect(e.code, 'DOWNLOAD_FAILED');
    });

    test('StorageUnavailableException', () {
      const e = StorageUnavailableException(message: 'No space');
      expect(e.code, 'STORAGE_UNAVAILABLE');
    });

    test('PermissionDeniedException', () {
      const e = PermissionDeniedException(message: 'No permission');
      expect(e.code, 'PERMISSION_DENIED');
    });

    test('NetworkUnavailableException', () {
      const e = NetworkUnavailableException(message: 'No network');
      expect(e.code, 'NETWORK_UNAVAILABLE');
    });

    test('ServiceUnavailableException', () {
      const e = ServiceUnavailableException(message: 'Service down');
      expect(e.code, 'SERVICE_UNAVAILABLE');
    });

    test('TaskNotFoundException', () {
      const e = TaskNotFoundException(message: 'Task not found');
      expect(e.code, 'TASK_NOT_FOUND');
    });

    test('NotInitializedException', () {
      const e = NotInitializedException();
      expect(e.code, 'NOT_INITIALIZED');
      expect(e.message, 'BackgroundRuntime has not been initialized.');
    });

    test('UnsupportedPlatformException', () {
      const e = UnsupportedPlatformException(message: 'Unsupported');
      expect(e.code, 'UNSUPPORTED_PLATFORM');
    });

    test('all typed exceptions extend BackgroundRuntimeException', () {
      expect(
        const DownloadFailedException(message: ''),
        isA<BackgroundRuntimeException>(),
      );
      expect(
        const StorageUnavailableException(message: ''),
        isA<BackgroundRuntimeException>(),
      );
      expect(
        const PermissionDeniedException(message: ''),
        isA<BackgroundRuntimeException>(),
      );
      expect(
        const NetworkUnavailableException(message: ''),
        isA<BackgroundRuntimeException>(),
      );
      expect(
        const ServiceUnavailableException(message: ''),
        isA<BackgroundRuntimeException>(),
      );
      expect(
        const TaskNotFoundException(message: ''),
        isA<BackgroundRuntimeException>(),
      );
      expect(
        const NotInitializedException(),
        isA<BackgroundRuntimeException>(),
      );
      expect(
        const UnsupportedPlatformException(message: ''),
        isA<BackgroundRuntimeException>(),
      );
    });
  });
}
