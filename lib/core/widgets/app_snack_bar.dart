import 'package:flutter/material.dart';
import 'package:smartscanocr/core/errors/error_presenter.dart';

/// Shows an [AppFeedback] as a themed SnackBar (nothing for silent feedback).
void showAppFeedback(BuildContext context, AppFeedback feedback) {
  if (feedback.silent || feedback.message.isEmpty) return;
  final scheme = Theme.of(context).colorScheme;
  final (Color bg, Color fg) = switch (feedback.severity) {
    FeedbackSeverity.info => (scheme.inverseSurface, scheme.onInverseSurface),
    FeedbackSeverity.warning => (scheme.tertiary, scheme.onTertiary),
    FeedbackSeverity.error => (scheme.error, scheme.onError),
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(feedback.message, style: TextStyle(color: fg)),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
      ),
    );
}

/// Convenience: maps any error to feedback and shows it.
void showErrorFeedback(BuildContext context, Object error) =>
    showAppFeedback(context, describeError(error));

/// Shows a simple informational SnackBar with [message].
void showInfoSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
}
