/// The OCR processing state of a document.
enum OcrStatus { none, pending, running, done, partial, failed }

/// Parses an [OcrStatus] from its persisted `name`, defaulting to [OcrStatus.none].
OcrStatus parseOcrStatus(String? name) => OcrStatus.values.firstWhere(
  (s) => s.name == name,
  orElse: () => OcrStatus.none,
);

extension OcrStatusLabel on OcrStatus {
  /// A short, user-facing label for the status chip.
  String get label => switch (this) {
    OcrStatus.none => 'Not processed',
    OcrStatus.pending => 'Pending',
    OcrStatus.running => 'Processing',
    OcrStatus.done => 'Text recognized',
    OcrStatus.partial => 'Partly recognized',
    OcrStatus.failed => 'No text',
  };
}
