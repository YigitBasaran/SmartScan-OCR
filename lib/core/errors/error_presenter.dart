import 'package:smartscanocr/core/errors/app_exception.dart';

/// Severity of a piece of user feedback, used to style SnackBars/dialogs.
enum FeedbackSeverity { info, warning, error }

/// A user-facing description of an outcome, derived from an [AppException].
///
/// This is a pure value (no Flutter dependency) so it can be unit-tested.
class AppFeedback {
  const AppFeedback(
    this.message, {
    this.severity = FeedbackSeverity.error,
    this.silent = false,
  });

  /// A feedback that produces no UI (e.g. the user cancelled).
  const AppFeedback.silent()
    : message = '',
      severity = FeedbackSeverity.info,
      silent = true;

  final String message;
  final FeedbackSeverity severity;
  final bool silent;
}

/// Maps any error to a friendly, non-technical [AppFeedback].
///
/// The switch is exhaustive over the sealed [AppException] hierarchy, so adding
/// a new exception type is a compile error until it is handled here.
AppFeedback describeError(Object error) {
  final exception = toAppException(error);
  return switch (exception) {
    ScanCancelled() => const AppFeedback.silent(),
    ScannerUnavailable() => const AppFeedback(
      'The document scanner is unavailable on this device. You can import images instead.',
      severity: FeedbackSeverity.warning,
    ),
    PermissionDenied() => const AppFeedback(
      'Permission was denied. Please allow access in Settings to continue.',
      severity: FeedbackSeverity.warning,
    ),
    NoPagesSelected() => const AppFeedback(
      'Add at least one page first.',
      severity: FeedbackSeverity.warning,
    ),
    OcrNoText() => const AppFeedback(
      'No text was found. The PDF was still saved.',
      severity: FeedbackSeverity.info,
    ),
    OcrFailure() => const AppFeedback(
      'Text recognition was unavailable. The PDF was saved without searchable text.',
      severity: FeedbackSeverity.warning,
    ),
    PdfGenerationFailure() => const AppFeedback(
      'Could not create the PDF. Please try again.',
    ),
    FileWriteFailure() => const AppFeedback(
      'Could not save files. Check available storage and try again.',
    ),
    ShareFailure() => const AppFeedback(
      'Sharing failed. Please try again.',
      severity: FeedbackSeverity.warning,
    ),
    StorageFailure() => const AppFeedback(
      'Something went wrong while accessing local storage.',
    ),
    UnsupportedPlatformFailure() => const AppFeedback(
      'This feature is not supported on this platform.',
      severity: FeedbackSeverity.warning,
    ),
  };
}
