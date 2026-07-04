/// Maps HTTP / network failures to Arabic messages safe to show in the UI.
///
/// Never expose raw status codes, JSON bodies, or exception class names to users.
class UserFacingError {
  UserFacingError._();

  static const String networkUnavailable =
      'تعذر الاتصال بالخادم. تأكد من اتصالك بالشبكة ثم أعد المحاولة.';

  static const String invalidInput = 'تحقق من البيانات المدخلة.';

  static const String invalidCredentials =
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  static const String serviceUnavailable =
      'الخدمة غير متوفرة حالياً. حاول مرة أخرى لاحقاً.';

  static const String analysisFailed =
      'تعذر تحليل التلاوة. حاول مرة أخرى.';

  /// Returns a user-safe Arabic message for an HTTP status code.
  static String fromHttpStatus(int? statusCode) {
    switch (statusCode) {
      case 400:
      case 422:
        return invalidInput;
      case 401:
      case 403:
        return invalidCredentials;
      case 404:
        return serviceUnavailable;
      case 500:
      case 502:
      case 503:
      case 504:
        return serviceUnavailable;
      default:
        return networkUnavailable;
    }
  }

  /// Recitation analysis failures (never include response body or status text).
  static String fromRecitationFailure({int? statusCode}) {
    if (statusCode == null) return networkUnavailable;
    if (statusCode >= 500) return analysisFailed;
    if (statusCode == 400 || statusCode == 422) return invalidInput;
    return analysisFailed;
  }

  /// True when [message] is safe to display (no leaked status codes / stack traces).
  static bool isSafeForUser(String message) {
    if (message.trim().isEmpty) return false;
    final lower = message.toLowerCase();
    const forbidden = [
      '404',
      '500',
      '502',
      '503',
      'traceback',
      'exception',
      'socketexception',
      'failed host lookup',
      'analyze failed:',
      'analyze-text failed:',
      'recitationapiexception',
      'http/',
    ];
    for (final token in forbidden) {
      if (lower.contains(token)) return false;
    }
    return true;
  }
}
