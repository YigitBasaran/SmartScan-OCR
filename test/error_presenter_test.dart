import 'package:flutter_test/flutter_test.dart';
import 'package:smartscanocr/core/errors/app_exception.dart';
import 'package:smartscanocr/core/errors/error_presenter.dart';

void main() {
  group('describeError', () {
    test('ScanCancelled is silent', () {
      expect(describeError(const ScanCancelled()).silent, isTrue);
    });

    test('OcrNoText is a non-silent info message', () {
      final feedback = describeError(const OcrNoText());
      expect(feedback.silent, isFalse);
      expect(feedback.severity, FeedbackSeverity.info);
    });

    test('OcrFailure is a warning', () {
      expect(
        describeError(const OcrFailure()).severity,
        FeedbackSeverity.warning,
      );
    });

    test('PdfGenerationFailure is an error', () {
      expect(
        describeError(const PdfGenerationFailure()).severity,
        FeedbackSeverity.error,
      );
    });

    test('unknown errors are wrapped as a storage failure', () {
      final feedback = describeError(Exception('boom'));
      expect(feedback.silent, isFalse);
      expect(feedback.severity, FeedbackSeverity.error);
      expect(feedback.message, isNotEmpty);
    });
  });
}
