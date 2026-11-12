import 'package:flutter/foundation.dart';

/// Single choke point for error reporting.
///
/// Wire Sentry / Firebase Crashlytics here once, e.g.
/// `Sentry.captureException(error, stackTrace: stack)`.
/// Until then errors are logged in debug builds only, and never include
/// request bodies, tokens or personal data.
class CrashReporter {
  const CrashReporter._();

  static void record(Object error, StackTrace? stack, {String? reason}) {
    if (kDebugMode) {
      debugPrint('[error] ${reason ?? ''} $error');
      if (stack != null) debugPrintStack(stackTrace: stack, maxFrames: 8);
    }
  }
}
