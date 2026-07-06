# SmartScan OCR

An offline-first document scanner for Android (and iOS-ready) built with Flutter. Scan or import document pages, run
**on-device OCR**, generate a compressed **PDF**, save everything **locally**, and search past documents by title or
recognized text — then share the PDF or the extracted text.

- **OCR runs entirely on your device.**
- **No cloud OCR API is used.**
- **Documents are stored locally on your device by default.** There is no backend and no account.
- **The Android scanner and OCR may require Google Play Services** (see [Limitations](#known-limitations)).
- **iOS is structurally supported but was not built or tested** — building/running iOS requires macOS + Xcode.

> Package name: `com.aliyigit.smartscanocr` · Flutter stable (3.44+) · Material 3 · Dart null-safety.

---

## Features

- **Scan** documents with a native scanner UI (auto edge detection, multi-page). Camera scans are perspective-corrected
  by ML Kit.
- **Import image(s)** as document pages — routed through ML Kit's gallery correction when available (best-effort), with
  a raw offline picker as fallback. Imports are treated like scans, not plain photos.
- **Review** before saving: reorder, rotate, delete pages, and name the document.
- **Per-page editing** (before *and* after saving): rotate, choose a **filter** (grayscale / black & white / enhance),
  and **manually crop/straighten** with a draggable four-corner overlay. Originals are never overwritten.
- **Edit saved documents**: reopen to reorder / add / delete / edit pages and rename. Saving **regenerates the PDF** and
  re-runs OCR only for new or changed pages (unchanged pages keep their text). Saves are transaction-like — a failure
  never corrupts the existing document or its PDF.
- **On-device OCR** per page, with progress ("Preparing / Recognizing text / Creating PDF / Saving", page _x_ of _N_).
- **PDF export** generated from the reviewed pages, with a selectable quality/size trade-off.
- **Local library** with a responsive grid, per-document thumbnail, page count, date and OCR-status chip.
- **Search** across document titles **and** recognized text.
- **Document detail**: metadata, page previews, per-page OCR text, and actions to **copy text**, **share PDF**,
  **share text**, **print**, **rename**, **edit** and **delete** (destructive actions are confirmed).
  Shared PDFs are named from the document title (e.g. `March_Invoice.pdf`), and shared/copied text includes the title
  and per-page `Page N` sections.
- **Settings**: theme mode (system/light/dark), default PDF quality, and best-effort **auto perspective correction**,
  stored locally.
- Polished empty / loading / error states and typed, user-friendly error handling throughout.

---

## Screens

| Screen | What it does |
|---|---|
| **Library** (`/`) | Searchable grid of saved documents; entry points to Scan and Import; empty/loading/error states. |
| **Review** (`/review`) | Reorder / rotate / delete / edit pages, rename the document, then "Run OCR & Save PDF" with a progress overlay. |
| **Page editor** | Rotate, pick a filter, and manually crop/straighten a page with a draggable four-corner overlay. |
| **Document detail** (`/document/:id`) | Metadata, page previews, per-page OCR text, and share/copy/print/rename/edit/delete. |
| **Edit document** (`/document/:id/edit`) | Reorder / add / delete / edit pages and rename; saving regenerates the PDF and OCR. |
| **Settings** (`/settings`) | Theme mode, default PDF quality, auto perspective correction, on-device OCR note, and About. |

---

## Architecture

Clean, feature-first structure. **The UI depends only on controllers/providers and abstract service interfaces — never
on a plugin API directly.** Plugin-specific code lives only inside each feature's `data/` layer, so a scanner/OCR/PDF
implementation can be swapped without touching the UI.

```text
lib/
  main.dart                       # init Hive, open boxes, runApp(ProviderScope)
  app/                            # app widget, GoRouter routes, Material 3 theme
  core/
    constants/  errors/           # app constants; sealed AppException + error→message mapping
    storage/    sharing/          # FileStorageService, SharingService (interfaces + impls)
    utils/      providers/        # filename/date, safe Hive casts, schema migration; DI providers
    widgets/                      # small shared widgets (thumbnail, snackbars)
  features/
    documents/                    # entities, Hive repository + mappers, library/detail UI, controllers
    scanner/                      # DocumentScannerService (+ cunning impl), review flow controller + UI
    ocr/                          # OcrService (+ ML Kit impl), OCR result entities
    pdf_export/                   # PdfExportService + ImageProcessor (compression), PdfQuality
    settings/                     # AppSettings, Hive settings repo, settings UI
test/                             # unit + widget tests with fake services
```

- **State management:** Riverpod 3. Services/repositories are exposed via overridable providers (the DI + test seam);
  screen logic lives in `Notifier`/`AsyncNotifier` controllers.
- **Persistence:** documents are stored as JSON-compatible maps in a Hive box, keyed by id; each map carries a
  `schemaVersion` so the stored shape can be migrated forward. Files live under the app documents directory:

  ```text
  /documents/{documentId}/pages/page_1.jpg
  /documents/{documentId}/export.pdf
  ```

  Deleting a document removes both its Hive entry and its folder; orphaned folders are swept on launch.
- **Search:** case-insensitive substring match over title + combined OCR text (instant at a personal-library scale).
- **Errors:** a sealed `AppException` hierarchy (cancelled, scanner unavailable, permission denied, no pages, no text,
  OCR/PDF/file/share/storage failures, unsupported platform) is mapped to friendly SnackBar/dialog messages.

---

## Dependencies & why

| Package | Role | Why this one |
|---|---|---|
| `flutter_riverpod` | State management + DI | Testable providers; clean override seam for fakes. Riverpod 3 (stable). |
| `go_router` | Navigation | Declarative, Flutter-team maintained. |
| `hive_ce` + `hive_ce_flutter` | Local persistence | Pure-Dart key/value store — **no native build, no code generation**, ideal for this data scale. Uses the actively-maintained Community Edition (the original `hive` is stale). |
| `cunning_document_scanner` | Native scanner | See [scanner selection](#scanner-package-selection). Returns page **images**; the app builds its own PDF. |
| `google_mlkit_text_recognition` | OCR | On-device, offline text recognition (Latin script). No cloud. |
| `pdf` + `printing` | PDF generate / print | Build the PDF (`pdf`) and print/preview it (`printing`); same maintainer. |
| `image` | Image processing | Decode, apply EXIF orientation, resize and JPEG-encode pages for compression. |
| `image_picker` | Image import | Gallery multi-select; on Android 13+ uses the system Photo Picker (no storage permission). |
| `path_provider` + `path` | Files | App documents directory and path joining. |
| `share_plus` | Sharing | Share the PDF and extracted text via the system share sheet. |
| `intl` + `uuid` | Utilities | Timestamped filenames; unique document/page ids. |

### Scanner package selection

The scanner sits behind `DocumentScannerService`, so the concrete plugin can be swapped freely. Candidates were evaluated
for reliability on the current toolchain (Flutter 3.44 / Android Gradle Plugin 9 / Gradle 9), where AGP 9 no longer
supports plugins that apply the Kotlin Gradle Plugin directly:

- **`cunning_document_scanner` (chosen)** — cross-platform (ML Kit on Android, VisionKit on iOS), verified publisher,
  actively maintained, and already AGP-9-correct.
- **`google_mlkit_document_scanner` (documented fallback, not installed)** — Java-only and therefore
  compile-bulletproof, but **Android-only**. It is intentionally **not** in `pubspec.yaml`; add it only if
  `cunning_document_scanner` ever fails to build/behave — a one-file change thanks to the interface.
- `flutter_doc_scanner` and `doc_scanner_kit` were rejected (pre-1.0/stale with open AGP-9 build issues).

**Note on permissions (verified against the built debug APK).** The app declares **no** runtime permissions of its own.
`permission_handler` is pulled in **transitively by `cunning_document_scanner`** (the scanner uses it to request camera
access for its UI), but the merged Android manifest contains **no `CAMERA`, media or storage permission** — the ML Kit
Document Scanner runs out-of-process in Google Play Services, and `image_picker` uses the Android Photo Picker. The only
permissions the merge adds are **`INTERNET`** and **`ACCESS_NETWORK_STATE`**, contributed by ML Kit / Google Play
Services so the on-device OCR model can be provisioned. Document images and recognized text are never uploaded, and OCR
itself runs on-device.

### Persistence choice (Hive CE vs. Drift)

Hive CE was chosen over a SQL option (e.g. Drift + FTS5) deliberately: at a realistic scale (tens–hundreds of documents),
in-memory substring search is instant and is arguably a better match for partial-word queries, while avoiding native
database setup and code generation. The `DocumentRepository` interface keeps a future move to Drift/FTS5 a drop-in change
(see [Roadmap](#roadmap)).

---

## Android setup

No manual setup is required beyond a standard Flutter/Android toolchain:

- **minSdk 24, compileSdk 36, targetSdk 36**, Java 17 (all set by the project).
- The Android manifest sets the app label and pre-fetches the ML Kit OCR model at install time
  (`com.google.mlkit.vision.DEPENDENCIES = ocr`). No app-declared runtime permissions.
- Real scanning/OCR use ML Kit via **Google Play Services**; use a Play-enabled device or emulator image.

## iOS note

The `ios/` project is generated and pre-wired (camera + photo-library usage strings; Podfile deployment target 15.5 for
ML Kit OCR), **but iOS was not built, run, or tested** — that requires **macOS + Xcode**. When on a Mac:

```bash
flutter pub get
cd ios && pod install
# open ios/Runner.xcworkspace, set a signing team + iOS 15.5 deployment target, then:
flutter run
```

---

## How to run

```bash
flutter pub get
flutter run            # requires a connected Android device or a running emulator
```

To exercise the full pipeline (scan → OCR → PDF → save → search → share), OCR needs Google Play Services, so use a
physical device or a **Google Play** emulator image. If a camera/scanner is unavailable, use **Import image(s)** — the
OCR/PDF/save/search/share flow works the same way.

## How to test

```bash
flutter test
```

Unit and widget tests run entirely with **fake services** (no camera, OCR, or real plugins): filename generation,
`PdfQuality` mapping, search/filter, mapper round-trip + schema migration, error mapping, the scan→OCR→PDF→save
controller pipeline (including the "OCR failed but PDF still saved" path), the Hive repository (against a temp directory),
and widget tests for the empty library, library search filtering, and settings changes.

## How to build a debug APK

```bash
flutter build apk --debug
# output: build/app/outputs/flutter-apk/app-debug.apk
```

---

## Known limitations

- **Perspective correction is best-effort.** Camera scans are corrected by ML Kit; imports are corrected via ML Kit's
  gallery flow when Google Play Services is available. Extreme angles, curled pages, low contrast, shadows, or edges out
  of frame may still need the **manual crop/straighten** tool in the page editor. A fully automatic detector
  (`PerspectiveCorrectionService`) is stubbed as a no-op extension point — see the OpenCV note in the roadmap.
- **Google Play Services required for scanning/OCR.** On devices/emulators without Play Services, the native scanner and
  ML Kit OCR (and ML Kit gallery correction) are unavailable; the app degrades gracefully — raw import still works,
  manual crop still works, and a PDF is still produced without recognized text.
- **OCR language:** Latin script only in this version.
- **Imported image formats:** the image pipeline supports common formats (JPEG/PNG/etc.); formats it can't decode (e.g.
  HEIC) are reported as an error rather than crashing.
- **Generated PDFs are image-based** (no invisible searchable text layer yet — see roadmap). Search works in-app against
  the stored OCR text.
- **iOS is unverified** on this machine (Windows). It is structurally prepared only.

---

## Watermark & monetization

- **Free exported PDFs carry a "Scanned with SmartScan OCR" watermark**, drawn as a PDF overlay on top of each page.
  It is **never baked into the stored/clean images or the OCR input**, so OCR, `combinedText`, and shared text stay
  clean and the original + processed image files remain unwatermarked. The watermark is also shown (visual-only) on the
  in-app document previews and library thumbnails, so you can see what a free export looks like.
- **Watermark-free export is user-initiated and gated per export**: on **Share PDF**, choose *Export with watermark*
  (free) or *Remove watermark* → watch a rewarded ad → the current PDF is exported watermark-free (a temp file; the
  stored `export.pdf` is not changed and OCR is not re-run). The ad is required for **every** watermark-free export —
  there is no permanent unlock. Ads never auto-show and never gate scanning/editing/saving/viewing.
- **Live edit preview:** filter (grayscale / B&W / enhance) and rotation update on-screen immediately in the page editor
  and thumbnails; the crop is shown as a corner box and its straightened result appears after you Save.
- **Rewarded ads are currently stubbed** behind a `RewardedAdService` interface (a simulated service that grants the
  reward, so the flow is fully testable). The real **`google_mobile_ads`** plugin is **deferred**: version 9.0.0 compiles
  on this toolchain but has an open, unresolved **release-mode startup crash on Flutter 3.44 + AGP 9 + Android 16**
  ([googleads-mobile-flutter #1444](https://github.com/googleads/googleads-mobile-flutter/issues/1444)). Swapping in the
  real service is a one-line provider change once that is fixed/verified.
- **Before a Play Store release with real ads:** add the plugin + AdMob App ID meta-data, then update the Privacy
  Policy, the Play Console Data Safety form, and the ads disclosure, and inspect the **merged AndroidManifest** for the
  `com.google.android.gms.permission.AD_ID` permission (the ads SDK auto-merges it into the currently permission-free
  manifest). Use Google's test ad unit IDs during development.

---

## Roadmap

- **Real Google Mobile Ads rewarded implementation** behind the existing `RewardedAdService`, once the AGP-9 /
  Android-16 release-startup crash ([#1444]) is resolved — plus a localized (e.g. Turkish) watermark string, which needs
  an embedded Unicode font for the `ı` glyph.
- **Automatic OpenCV dewarp** behind the existing `PerspectiveCorrectionService` interface. Deferred deliberately: the
  current OpenCV Dart bindings (`opencv_dart`/`dartcv4`) pin `hooks: ^1.0.0` while this toolchain resolves `hooks 2.0.2`,
  which breaks `flutter pub get`, and their from-source NDK-28 native build is unvalidated. The manual four-corner crop
  covers the same need today with zero native-build risk.
- Searchable PDFs with an invisible OCR text layer.
- OCR bounding-box overlay on page previews.
- Batch export; PDF merge/split.
- Document tags/folders.
- Password-protected PDFs.
- Signatures and annotations.
- Optional cloud backup (kept optional; no mandatory backend).
- Drift + FTS5 search backend if libraries grow into the thousands (a drop-in behind `DocumentRepository`).

---

## Project status

Android-first MVP, developed and validated on Windows: `flutter analyze` (0 issues), `flutter test` (all passing), and
`flutter build apk --debug` succeed. Runtime behavior that needs a device or Play Services (real scanner UI, real OCR,
native share/print) is isolated behind service interfaces and verified with fakes in tests — validate it on a real
Android device or a Play-enabled emulator.
