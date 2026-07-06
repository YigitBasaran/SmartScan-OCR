import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartscanocr/core/providers/app_providers.dart';
import 'package:smartscanocr/core/sharing/sharing_service.dart';
import 'package:smartscanocr/core/sharing/sharing_service_impl.dart';
import 'package:smartscanocr/core/storage/file_storage_service.dart';
import 'package:smartscanocr/core/storage/file_storage_service_impl.dart';
import 'package:smartscanocr/features/documents/data/repositories/hive_document_repository.dart';
import 'package:smartscanocr/features/documents/domain/repositories/document_repository.dart';
import 'package:smartscanocr/features/ocr/data/mlkit_ocr_service.dart';
import 'package:smartscanocr/features/ocr/domain/services/ocr_service.dart';
import 'package:smartscanocr/features/pdf_export/data/image_processor_impl.dart';
import 'package:smartscanocr/features/pdf_export/data/pdf_export_service_impl.dart';
import 'package:smartscanocr/features/pdf_export/domain/services/image_processor.dart';
import 'package:smartscanocr/features/pdf_export/domain/services/pdf_export_service.dart';
import 'package:smartscanocr/features/scanner/data/cunning_document_scanner_service.dart';
import 'package:smartscanocr/features/documents/data/document_exporter.dart';
import 'package:smartscanocr/features/documents/data/document_processing_service_impl.dart';
import 'package:smartscanocr/features/documents/domain/services/document_processing_service.dart';
import 'package:smartscanocr/features/monetization/data/simulated_rewarded_ad_service.dart';
import 'package:smartscanocr/features/monetization/domain/rewarded_ad_service.dart';
import 'package:smartscanocr/features/perspective/data/noop_perspective_correction_service.dart';
import 'package:smartscanocr/features/perspective/domain/services/perspective_correction_service.dart';
import 'package:smartscanocr/features/scanner/domain/services/document_scanner_service.dart';
import 'package:smartscanocr/features/settings/data/hive_settings_repository.dart';
import 'package:smartscanocr/features/settings/domain/repositories/settings_repository.dart';

/// Central DI seam. Every concrete service/repository is exposed here and can be
/// overridden with a fake in tests via `ProviderScope(overrides: [...])`.

final fileStorageServiceProvider = Provider<FileStorageService>(
  (ref) => FileStorageServiceImpl(),
);

final imageProcessorProvider = Provider<ImageProcessor>(
  (ref) => ImageProcessorImpl(),
);

/// Automatic perspective correction. Defaults to a no-op (manual crop in the
/// page editor handles correction); swap for an OpenCV/ML-Kit detector later.
final perspectiveCorrectionServiceProvider =
    Provider<PerspectiveCorrectionService>(
      (ref) => const NoOpPerspectiveCorrectionService(),
    );

final sharingServiceProvider = Provider<SharingService>(
  (ref) => SharingServiceImpl(),
);

/// Rewarded ads for watermark-free export. A simulated impl today; swap for a
/// real Google Mobile Ads impl once it's verified on this toolchain.
final rewardedAdServiceProvider = Provider<RewardedAdService>(
  (ref) => const SimulatedRewardedAdService(),
);

/// Shares a document's PDF (watermarked free, or watermark-free after an ad).
final documentExporterProvider = Provider<DocumentExporter>(
  (ref) => DocumentExporter(
    pdfService: ref.watch(pdfExportServiceProvider),
    storage: ref.watch(fileStorageServiceProvider),
    sharing: ref.watch(sharingServiceProvider),
  ),
);

final documentScannerServiceProvider = Provider<DocumentScannerService>(
  (ref) => CunningDocumentScannerService(),
);

final ocrServiceProvider = Provider<OcrService>((ref) => MlKitOcrService());

final pdfExportServiceProvider = Provider<PdfExportService>(
  (ref) => PdfExportServiceImpl(),
);

/// Shared save/regeneration pipeline used by both the new-scan review flow and
/// the post-save document editor.
final documentProcessingServiceProvider = Provider<DocumentProcessingService>(
  (ref) => DocumentProcessingServiceImpl(
    imageProcessor: ref.watch(imageProcessorProvider),
    ocrService: ref.watch(ocrServiceProvider),
    pdfService: ref.watch(pdfExportServiceProvider),
    storage: ref.watch(fileStorageServiceProvider),
    repository: ref.watch(documentRepositoryProvider),
    correctionService: ref.watch(perspectiveCorrectionServiceProvider),
    uuid: ref.watch(uuidProvider),
  ),
);

final documentRepositoryProvider = Provider<DocumentRepository>(
  (ref) => HiveDocumentRepository(
    ref.watch(documentsBoxProvider),
    ref.watch(fileStorageServiceProvider),
  ),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => HiveSettingsRepository(ref.watch(settingsBoxProvider)),
);
