import 'package:flutter_clean_arch_template/core/network/token/token_storage_impl.dart';
import 'package:flutter_clean_arch_template/core/storage/local/hive_service.dart';
import 'package:flutter_clean_arch_template/core/storage/local/secure_storage_service.dart';
import 'package:flutter_clean_arch_template/core/storage/local/shared_prefs_service.dart';
import 'package:flutter_clean_arch_template/core/storage/storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('TokenStorageImpl', () {
    late _MockFlutterSecureStorage secureStorage;
    late TokenStorageImpl tokenStorage;

    setUp(() {
      secureStorage = _MockFlutterSecureStorage();
      final storageService = StorageService(
        hiveService: HiveService(),
        sharedPrefsService: SharedPrefsService(),
        secureStorageService: SecureStorageService(
          storage: secureStorage,
          readRetryDelay: Duration.zero,
        ),
      );
      tokenStorage = TokenStorageImpl(storageService);
    });

    test('should cache confirmed missing access token', () async {
      when(
        () => secureStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);

      expect(await tokenStorage.getAccessToken(), isNull);
      expect(await tokenStorage.getAccessToken(), isNull);

      verify(
        () => secureStorage.read(key: any(named: 'key')),
      ).called(1);
    });

    test('should not cache access token read failure', () async {
      var attempts = 0;
      when(
        () => secureStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async {
        attempts++;
        if (attempts <= 3) {
          throw StateError('keychain unavailable');
        }
        return 'recovered-token';
      });

      await expectLater(
        tokenStorage.getAccessToken(),
        throwsA(isA<Exception>()),
      );
      expect(await tokenStorage.getAccessToken(), 'recovered-token');
      verify(
        () => secureStorage.read(key: any(named: 'key')),
      ).called(4);
    });
  });
}
