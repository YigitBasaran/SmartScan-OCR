/// The OCR result for a single page.
class OcrPageResult {
  const OcrPageResult({
    required this.pageId,
    required this.text,
    this.blockCount = 0,
  });

  final String pageId;
  final String text;
  final int blockCount;

  bool get hasText => text.trim().isNotEmpty;
}
