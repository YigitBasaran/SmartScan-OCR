import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:smartscanocr/core/constants/app_constants.dart';
import 'package:smartscanocr/features/documents/data/mappers/scanned_document_mapper.dart';
import 'package:smartscanocr/features/documents/domain/entities/ocr_status.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_page.dart';
import 'package:smartscanocr/features/pdf_export/domain/entities/pdf_quality.dart';
import 'package:smartscanocr/features/settings/data/mappers/app_settings_mapper.dart';
import 'package:smartscanocr/features/settings/domain/entities/app_settings.dart';

import 'support/factories.dart';

void main() {
  group('document mapper', () {
    test('round-trips through a map with schemaVersion and ISO dates', () {
      final doc = makeDocument(
        id: '1',
        title: 'Title',
        text: 'hello world',
        status: OcrStatus.done,
        pages: [
          const ScannedPage(
            id: 'p1',
            imagePath: 'a.jpg',
            order: 0,
            ocrText: 'hello',
          ),
          const ScannedPage(id: 'p2', imagePath: 'b.jpg', order: 1),
        ],
      );

      final map = documentToMap(doc);
      expect(map['schemaVersion'], AppConstants.documentSchemaVersion);
      expect(map['createdAt'], isA<String>());
      expect(map['ocrStatus'], 'done');

      final restored = documentFromMap(map);
      expect(restored.id, '1');
      expect(restored.title, 'Title');
      expect(restored.combinedText, 'hello world');
      expect(restored.ocrStatus, OcrStatus.done);
      expect(restored.pages.length, 2);
      expect(restored.pages[0].ocrText, 'hello');
      expect(restored.pages[1].ocrText, isNull);
      expect(restored.createdAt, doc.createdAt);
    });

    test('sorts pages by order on read', () {
      final doc = makeDocument(
        id: 'x',
        pages: [
          const ScannedPage(id: 'p2', imagePath: 'b.jpg', order: 1),
          const ScannedPage(id: 'p1', imagePath: 'a.jpg', order: 0),
        ],
      );
      final restored = documentFromMap(documentToMap(doc));
      expect(restored.pages.map((p) => p.id), ['p1', 'p2']);
    });

    test('migrates a legacy map missing schemaVersion', () {
      final legacy = <String, dynamic>{
        'id': 'old',
        'title': 'Legacy',
        'createdAt': '2026-01-02T03:04:05.000',
        'updatedAt': '2026-01-02T03:04:05.000',
        'pages': <dynamic>[],
        'pdfPath': null,
        'combinedText': '',
        'ocrStatus': 'done',
      };
      final restored = documentFromMap(legacy);
      expect(restored.id, 'old');
      expect(restored.title, 'Legacy');
    });

    test('reads Hive-style dynamic maps with safe casts', () {
      // Hive returns Map<dynamic,dynamic> and List<dynamic>.
      final Map<dynamic, dynamic> hiveMap = <dynamic, dynamic>{
        'schemaVersion': 1,
        'id': 'h',
        'title': 'Hive',
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
        'pages': <dynamic>[
          <dynamic, dynamic>{
            'id': 'p',
            'imagePath': 'a.jpg',
            'order': 0,
            'rotationQuarterTurns': 0,
            'ocrText': 'text',
          },
        ],
        'combinedText': 'text',
        'ocrStatus': 'done',
        'pdfPath': null,
      };
      final restored = documentFromMap(hiveMap);
      expect(restored.pages.first.ocrText, 'text');
    });
  });

  group('settings mapper', () {
    test('round-trips settings', () {
      const settings = AppSettings(
        themeMode: ThemeMode.dark,
        pdfQuality: PdfQuality.high,
      );
      final restored = settingsFromMap(settingsToMap(settings));
      expect(restored, settings);
    });

    test('defaults on unknown values', () {
      final restored = settingsFromMap(<String, dynamic>{
        'schemaVersion': 1,
        'themeMode': 'bogus',
        'pdfQuality': 'bogus',
      });
      expect(restored.themeMode, ThemeMode.system);
      expect(restored.pdfQuality, PdfQuality.balanced);
    });
  });
}
