import 'package:flutter_test/flutter_test.dart';
import 'package:qurany_app/utils/user_facing_error.dart';

void main() {
  group('UserFacingError.fromHttpStatus', () {
    test('maps 401 to credentials message without status code', () {
      final msg = UserFacingError.fromHttpStatus(401);
      expect(msg, UserFacingError.invalidCredentials);
      expect(msg.contains('401'), isFalse);
    });

    test('maps 500 to service unavailable without status code', () {
      final msg = UserFacingError.fromHttpStatus(500);
      expect(msg, UserFacingError.serviceUnavailable);
      expect(msg.contains('500'), isFalse);
    });

    test('maps unknown status to network message', () {
      expect(UserFacingError.fromHttpStatus(null), UserFacingError.networkUnavailable);
    });
  });

  group('UserFacingError.fromRecitationFailure', () {
    test('never embeds status code in message', () {
      for (final code in [400, 404, 500, 503]) {
        final msg = UserFacingError.fromRecitationFailure(statusCode: code);
        expect(UserFacingError.isSafeForUser(msg), isTrue);
      }
    });
  });

  group('UserFacingError.isSafeForUser', () {
    test('rejects raw HTTP error strings', () {
      expect(
        UserFacingError.isSafeForUser('Analyze failed: {"detail":"Not Found"}'),
        isFalse,
      );
      expect(UserFacingError.isSafeForUser('Error 500 Internal Server Error'), isFalse);
      expect(UserFacingError.isSafeForUser('RecitationApiException(404): body'), isFalse);
    });

    test('accepts Arabic user messages', () {
      expect(UserFacingError.isSafeForUser(UserFacingError.networkUnavailable), isTrue);
      expect(UserFacingError.isSafeForUser(UserFacingError.invalidInput), isTrue);
    });
  });
}
