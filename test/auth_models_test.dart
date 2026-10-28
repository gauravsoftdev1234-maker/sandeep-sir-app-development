import 'package:flutter_test/flutter_test.dart';
import 'package:partner_app/features/auth/auth_models.dart';

void main() {
  group('TokenStatus.fromJson', () {
    test('reads boolean flags', () {
      final status = TokenStatus.fromJson(const {
        'status': 'success',
        'IsValidToken': true,
        'IsServiceSelected': true,
      });

      expect(status.isValid, isTrue);
      expect(status.isServiceSelected, isTrue);
    });

    test('reads the numeric 0 the API returns for an invalid token', () {
      final status = TokenStatus.fromJson(const {
        'status': 'error',
        'IsValidToken': 0,
        'IsServiceSelected': 0,
      });

      expect(status.isValid, isFalse);
      expect(status.isServiceSelected, isFalse);
    });

    test('defaults to false on missing fields', () {
      final status = TokenStatus.fromJson(const {});

      expect(status.isValid, isFalse);
      expect(status.isServiceSelected, isFalse);
    });
  });

  group('AuthUser.fromJson', () {
    test('maps the login payload', () {
      final user = AuthUser.fromJson(const {
        'id': 2,
        'ProfileImage': null,
        'FullName': 'Test User',
        'AppToken': '1B62607F-5697-43BE-B12A-23E7229A8587',
      });

      expect(user.id, 2);
      expect(user.fullName, 'Test User');
      expect(user.appToken, '1B62607F-5697-43BE-B12A-23E7229A8587');
      expect(user.profileImage, isNull);
    });

    test('survives a round trip through storage', () {
      const user = AuthUser(id: 7, fullName: 'A B', appToken: 'tok');
      final restored = AuthUser.fromJson(user.toJson());

      expect(restored.id, user.id);
      expect(restored.fullName, user.fullName);
      expect(restored.appToken, user.appToken);
    });
  });
}
