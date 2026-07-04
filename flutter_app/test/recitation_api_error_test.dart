import 'package:flutter_test/flutter_test.dart';
import 'package:qurany_app/services/recitation_api_service.dart';
import 'package:qurany_app/utils/user_facing_error.dart';

/// Category H — specs for user-safe recitation errors.
///
/// UI wiring should call [userMessageForRecitationError] instead of showing
/// [RecitationApiException.message] or [toString] directly.
String userMessageForRecitationError(Object error) {
  if (error is RecitationApiException) {
    return UserFacingError.fromRecitationFailure(statusCode: error.statusCode);
  }
  return UserFacingError.networkUnavailable;
}

void main() {
  group('recitation error user messages (category H)', () {
    test('500 response body must not reach the user', () {
      final raw = RecitationApiException(
        'Analyze failed: Internal Server Error trace',
        statusCode: 500,
      );
      final userMsg = userMessageForRecitationError(raw);
      expect(UserFacingError.isSafeForUser(userMsg), isTrue);
      expect(userMsg, isNot(contains('500')));
      expect(userMsg, isNot(contains('Analyze failed')));
    });

    test('404 must map to safe Arabic message', () {
      final raw = RecitationApiException('Analyze failed: not found', statusCode: 404);
      final userMsg = userMessageForRecitationError(raw);
      expect(UserFacingError.isSafeForUser(userMsg), isTrue);
    });

    test('network errors without status code stay safe', () {
      final raw = RecitationApiException('Network error during analyze: SocketException');
      final userMsg = userMessageForRecitationError(raw);
      expect(UserFacingError.isSafeForUser(userMsg), isTrue);
    });

    test('RecitationApiException.toString is NOT safe for UI (debug only)', () {
      final raw = RecitationApiException('Analyze failed: x', statusCode: 500);
      expect(UserFacingError.isSafeForUser(raw.toString()), isFalse);
    });
  });
}
