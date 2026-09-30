import 'package:flutter_clean_arch_template/shared/models/page_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PageResult', () {
    test('should expose an unmodifiable item list', () {
      final source = [1, 2];
      final result = PageResult<int>(
        items: source,
        total: 2,
        hasNext: false,
        hasPrevious: false,
        currentPage: 1,
        pageSize: 20,
      );

      source.add(3);

      expect(result.items, [1, 2]);
      expect(() => result.items.add(4), throwsUnsupportedError);
    });
  });
}
