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

final sharingServiceProvider = Provider<SharingService>(
  (ref) => SharingServiceImpl(),
);

final documentScannerServiceProvider = Provider<DocumentScannerService>(
  (ref) => CunningDocumentScannerService(),
);

final ocrServiceProvider = Provider<OcrService>((ref) => MlKitOcrService());

final pdfExportServiceProvider = Provider<PdfExportService>(
  (ref) => PdfExportServiceImpl(ref.watch(fileStorageServiceProvider)),
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
