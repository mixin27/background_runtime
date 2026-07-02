import 'package:background_runtime_platform_interface/background_runtime_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelBackgroundRuntime', () {
    late MethodChannelBackgroundRuntime runtime;
    const methodChannel = MethodChannel('dev.mixin27.background_runtime/method');

    setUp(() {
      runtime = MethodChannelBackgroundRuntime();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
    });

    test('initialize sends method call', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (message) async {
        expect(message.method, 'initialize');
        return null;
      });
      await runtime.initialize(const BackgroundRuntimeConfig());
    });

    test('startDownload sends method call and returns taskId', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (message) async {
        return {'taskId': 'task_123'};
      });
      final taskId = await runtime.startDownload(
        const DownloadRequest(url: 'https://example.com/f.zip', destinationPath: '/tmp/f.zip'),
      );
      expect(taskId, 'task_123');
    });

    test('pauseDownload sends method call', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (message) async {
        expect(message.method, 'pauseDownload');
        expect(message.arguments, {'taskId': 'task_1'});
        return null;
      });
      await runtime.pauseDownload('task_1');
    });

    test('cancelDownload sends method call', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (message) async {
        expect(message.method, 'cancelDownload');
        return null;
      });
      await runtime.cancelDownload('task_1');
    });

    test('MissingPluginException throws ServiceUnavailableException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (message) async {
        throw MissingPluginException('not implemented');
      });
      expect(
        () => runtime.initialize(const BackgroundRuntimeConfig()),
        throwsA(isA<ServiceUnavailableException>()),
      );
    });

    test('PlatformException with DOWNLOAD_FAILED throws DownloadFailedException',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (message) async {
        throw PlatformException(code: 'DOWNLOAD_FAILED', message: 'Connection timeout');
      });
      expect(
        () => runtime.initialize(const BackgroundRuntimeConfig()),
        throwsA(isA<DownloadFailedException>()),
      );
    });

    test('PlatformException with TASK_NOT_FOUND throws TaskNotFoundException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (message) async {
        throw PlatformException(code: 'TASK_NOT_FOUND', message: 'Task not found');
      });
      expect(
        () => runtime.startDownload(
          const DownloadRequest(url: 'https://example.com/f.zip', destinationPath: '/tmp/f.zip'),
        ),
        throwsA(isA<TaskNotFoundException>()),
      );
    });

    test('downloadEvents returns stream', () {
      expect(runtime.downloadEvents(), isA<Stream<DownloadEvent>>());
    });

    test('playerState returns stream', () {
      expect(runtime.playerState(), isA<Stream<PlayerState>>());
    });

    test('lifecycleEvents returns stream', () {
      expect(runtime.lifecycleEvents(), isA<Stream<RuntimeLifecycle>>());
    });
  });
}
