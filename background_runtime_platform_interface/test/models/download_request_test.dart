import 'package:flutter_test/flutter_test.dart';
import 'package:background_runtime_platform_interface/background_runtime_platform_interface.dart';

void main() {
  group('DownloadRequest', () {
    test('creates with required fields', () {
      final request = DownloadRequest(
        url: 'https://example.com/file.zip',
        destinationPath: '/tmp/file.zip',
      );
      expect(request.url, 'https://example.com/file.zip');
      expect(request.destinationPath, '/tmp/file.zip');
      expect(request.allowCellular, isTrue);
      expect(request.allowMetered, isTrue);
      expect(request.headers, isNull);
    });

    test('creates with optional fields', () {
      final request = DownloadRequest(
        url: 'https://example.com/file.zip',
        destinationPath: '/tmp/file.zip',
        headers: {'Authorization': 'Bearer token'},
        allowCellular: false,
        allowMetered: false,
      );
      expect(request.headers, {'Authorization': 'Bearer token'});
      expect(request.allowCellular, isFalse);
      expect(request.allowMetered, isFalse);
    });

    test('serializes to map and back', () {
      final original = DownloadRequest(
        url: 'https://example.com/file.zip',
        destinationPath: '/tmp/file.zip',
        headers: {'Authorization': 'Bearer token'},
        allowCellular: false,
        allowMetered: false,
      );
      final map = original.toMap();
      final restored = DownloadRequest.fromMap(map);
      expect(restored.url, original.url);
      expect(restored.destinationPath, original.destinationPath);
      expect(restored.headers, original.headers);
      expect(restored.allowCellular, original.allowCellular);
      expect(restored.allowMetered, original.allowMetered);
    });

    test('value equality', () {
      final a = DownloadRequest(
        url: 'https://example.com/a.zip',
        destinationPath: '/tmp/a.zip',
      );
      final b = DownloadRequest(
        url: 'https://example.com/a.zip',
        destinationPath: '/tmp/a.zip',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('value inequality', () {
      final a = DownloadRequest(
        url: 'https://example.com/a.zip',
        destinationPath: '/tmp/a.zip',
      );
      final b = DownloadRequest(
        url: 'https://example.com/b.zip',
        destinationPath: '/tmp/b.zip',
      );
      expect(a, isNot(equals(b)));
    });

    test('toString contains url', () {
      final request = DownloadRequest(
        url: 'https://example.com/file.zip',
        destinationPath: '/tmp/file.zip',
      );
      expect(request.toString(), contains('file.zip'));
    });
  });
}
