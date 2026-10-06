import 'package:flutter_test/flutter_test.dart';

import 'package:bilbax/features/auth/data/repositories/auth_repository.dart';

void main() {
  group('AuthRepository.normalizeBdPhone', () {
    test('017XXXXXXXX → +8801XXXXXXXXX', () {
      expect(
        AuthRepository.normalizeBdPhone('01712345678'),
        '+8801712345678',
      );
    });

    test('171XXXXXXX → +8801XXXXXXXXX', () {
      expect(
        AuthRepository.normalizeBdPhone('1712345678'),
        '+8801712345678',
      );
    });

    test('already E.164 stays', () {
      expect(
        AuthRepository.normalizeBdPhone('+8801712345678'),
        '+8801712345678',
      );
    });

    test('strips spaces and dashes', () {
      expect(
        AuthRepository.normalizeBdPhone('01712-345 678'),
        '+8801712345678',
      );
    });
  });
}
