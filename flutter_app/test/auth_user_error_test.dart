import 'package:flutter_test/flutter_test.dart';
import 'package:qurany_app/models/auth_result.dart';
import 'package:qurany_app/utils/user_facing_error.dart';

/// Category H — auth failures must use [AuthResult.messageAr], never raw HTTP text.
void main() {
  group('auth user-facing messages (category H)', () {
    test('backend unavailable message is safe', () {
      const result = AuthResult.failure(AuthFailure.backendUnavailable);
      expect(UserFacingError.isSafeForUser(result.messageAr), isTrue);
      expect(result.messageAr.contains('500'), isFalse);
    });

    test('invalid credentials message is safe', () {
      const result = AuthResult.failure(AuthFailure.invalidCredentials);
      expect(UserFacingError.isSafeForUser(result.messageAr), isTrue);
    });

    test('invalid input message is safe', () {
      const result = AuthResult.failure(AuthFailure.invalidInput);
      expect(UserFacingError.isSafeForUser(result.messageAr), isTrue);
    });
  });
}
