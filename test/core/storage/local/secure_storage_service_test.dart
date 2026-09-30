import 'package:flutter_clean_arch_template/core/errors/exceptions.dart';
import 'package:flutter_clean_arch_template/core/storage/local/secure_storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('SecureStorageService.read', () {
    late _MockFlutterSecureStorage storage;

    setUp(() {
      storage = _MockFlutterSecureStorage();
    });

    test('should return null once when key does not exist', () async {
      when(() => storage.read(key: 'token')).thenAnswer((_) async => null);
      final service = SecureStorageService(
        storage: storage,
        readRetryDelay: Duration.zero,
      );

      expect(await service.read('token'), isNull);
      verify(() => storage.read(key: 'token')).called(1);
    });

    test('should retry transient failure and return recovered value', () async {
      var attempts = 0;
      when(() => storage.read(key: 'token')).thenAnswer((_) async {
        attempts++;
        if (attempts == 1) {
          throw StateError('keychain unavailable');
        }
        return 'access-token';
      });
      final service = SecureStorageService(
        storage: storage,
        readRetryDelay: Duration.zero,
      );

      expect(await service.read('token'), 'access-token');
      verify(() => storage.read(key: 'token')).called(2);
    });

    test('should throw StorageException after all retries fail', () async {
      when(
        () => storage.read(key: 'token'),
      ).thenThrow(StateError('keychain unavailable'));
      final service = SecureStorageService(
        storage: storage,
        maxReadAttempts: 2,
        readRetryDelay: Duration.zero,
      );

      await expectLater(
        service.read('token'),
        throwsA(isA<StorageException>()),
      );
      verify(() => storage.read(key: 'token')).called(2);
    });
  });
}
