/// Base type for all recoverable, user-facing errors in the app.
///
/// Services throw these typed exceptions; controllers catch them and map them
/// to friendly messages via `describeError` in `error_presenter.dart`.
sealed class AppException implements Exception {
  const AppException([this.cause]);

  /// The underlying error/exception, if any (kept for logging, never shown raw).
  final Object? cause;

  @override
  String toString() => '$runtimeType(cause: $cause)';
}

/// The user cancelled scanning/importing. Handled silently (no error UI).
class ScanCancelled extends AppException {
  const ScanCancelled();
}

/// The scanner (or camera) is not available on this device.
class ScannerUnavailable extends AppException {
  const ScannerUnavailable([super.cause]);
}

/// A required runtime permission was denied.
class PermissionDenied extends AppException {
  const PermissionDenied([super.cause]);
}

/// An action needs at least one page but none were provided.
class NoPagesSelected extends AppException {
  const NoPagesSelected();
}

/// OCR ran successfully but found no text.
class OcrNoText extends AppException {
  const OcrNoText();
}

/// OCR could not run (e.g. Google Play Services unavailable).
class OcrFailure extends AppException {
  const OcrFailure([super.cause]);
}

/// The PDF could not be generated.
class PdfGenerationFailure extends AppException {
  const PdfGenerationFailure([super.cause]);
}

/// Writing files to local storage failed.
class FileWriteFailure extends AppException {
  const FileWriteFailure([super.cause]);
}

/// Sharing failed.
class ShareFailure extends AppException {
  const ShareFailure([super.cause]);
}

/// A local database (Hive) operation failed.
class StorageFailure extends AppException {
  const StorageFailure([super.cause]);
}

/// The requested feature is not supported on the current platform.
class UnsupportedPlatformFailure extends AppException {
  const UnsupportedPlatformFailure([super.cause]);
}

/// Wraps any error into an [AppException], preserving already-typed ones.
AppException toAppException(Object error) =>
    error is AppException ? error : StorageFailure(error);
