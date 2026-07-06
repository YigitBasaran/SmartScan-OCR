import 'package:flutter/foundation.dart';

/// Debug-only diagnostic logger (compiled out of release). Used to compare the
/// raw scanner/import image, the app-processed image, and the PDF-embedded
/// image while investigating scan quality.
void devLog(String message) {
  if (kDebugMode) {
    debugPrint('[SmartScan] $message');
  }
}
