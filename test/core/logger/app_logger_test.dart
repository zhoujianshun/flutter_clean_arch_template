import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLogger sensitive data handling', () {
    test('should sanitize early and initialized exception logs', () async {
      const earlyPassword = 'EarlyPassword123!';
      const authorizationToken = 'eyJ-early-secret-token';
      const runtimeToken = 'runtime-secret-token';

      AppLogger.error(
        'bootstrap password=$earlyPassword',
        error: Exception(
          'Authorization: Bearer $authorizationToken',
        ),
      );

      await AppLogger.initialize(
        environment: 'development',
        logLevel: 'debug',
      );
      AppLogger.exception(
        Exception('token=$runtimeToken'),
        StackTrace.current,
        message: 'request failed',
      );

      final serializedHistory = AppLogger.history
          .map(
            (entry) =>
                '${entry.message ?? ''} ${entry.error?.toString() ?? ''}',
          )
          .join('\n');

      expect(serializedHistory, isNot(contains(earlyPassword)));
      expect(serializedHistory, isNot(contains(authorizationToken)));
      expect(serializedHistory, isNot(contains(runtimeToken)));
      expect(serializedHistory, contains('***HIDDEN***'));
    });
  });
}
