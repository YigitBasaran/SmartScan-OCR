import 'dart:io';

import 'package:flutter/material.dart';
import 'package:smartscanocr/features/documents/domain/entities/page_filter.dart';
import 'package:smartscanocr/features/documents/domain/entities/scanned_page.dart';
import 'package:smartscanocr/features/documents/presentation/widgets/crop_corner_overlay.dart';
import 'package:smartscanocr/features/documents/presentation/widgets/page_filter_preview.dart';
import 'package:smartscanocr/features/documents/presentation/widgets/page_filter_selector.dart';
import 'package:smartscanocr/features/perspective/domain/entities/document_corner.dart';
import 'package:smartscanocr/features/perspective/presentation/crop_geometry.dart';

/// Edits a single page (rotate, filter, manual crop). Returns the edited
/// [ScannedPage] via `Navigator.pop`, or null if cancelled. Filters/crop are
/// applied to the original when the document is saved (best-effort); the crop
/// overlay works on the un-rotated source, matching the processing order.
class PageEditorScreen extends StatefulWidget {
  const PageEditorScreen({super.key, required this.page});

  final ScannedPage page;

  @override
  State<PageEditorScreen> createState() => _PageEditorScreenState();
}

class _PageEditorScreenState extends State<PageEditorScreen> {
  late int _rotation = widget.page.rotationQuarterTurns;
  late PageFilter _filter = widget.page.filterMode;
  late bool _cropEnabled = widget.page.cropCorners != null;
  late List<DocumentCorner> _corners =
      widget.page.cropCorners ?? fullFrameCorners();
  double? _aspect;

  @override
  void initState() {
    super.initState();
    _resolveAspect();
  }

  void _resolveAspect() {
    final stream = FileImage(
      File(widget.page.originalImagePath),
    ).resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (mounted) {
          setState(() => _aspect = info.image.width / info.image.height);
        }
        stream.removeListener(listener);
      },
      onError: (_, _) {
        if (mounted) setState(() => _aspect = 0.75);
      },
    );
    stream.addListener(listener);
  }

  void _rotate() => setState(() => _rotation = (_rotation + 1) % 4);

  void _reset() => setState(() {
    _rotation = 0;
    _filter = PageFilter.none;
    _cropEnabled = false;
    _corners = fullFrameCorners();
  });

  void _apply() {
    final edited = widget.page.copyWith(
      rotationQuarterTurns: _rotation,
      filterMode: _filter,
      cropCorners: _cropEnabled ? _corners : null,
      clearCorners: !_cropEnabled,
      clearProcessed: true, // force reprocessing on save
    );
    Navigator.of(context).pop(edited);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit page'),
        actions: [TextButton(onPressed: _apply, child: const Text('Apply'))],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: theme.colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.all(16),
              child: Center(child: _buildPreview()),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _rotate,
                      icon: const Icon(Icons.rotate_right),
                      label: Text('Rotate (${_rotation * 90}°)'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _reset,
                      child: const Text('Reset to original'),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Crop & straighten'),
                  subtitle: const Text(
                    'Drag the corners to the document edges. Applied on save.',
                  ),
                  value: _cropEnabled,
                  onChanged: (v) => setState(() {
                    _cropEnabled = v;
                    if (v && _corners.isEmpty) _corners = fullFrameCorners();
                  }),
                ),
                const SizedBox(height: 8),
                Text('Filter', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                PageFilterSelector(
                  selected: _filter,
                  onSelected: (f) => setState(() => _filter = f),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final aspect = _aspect;
    if (aspect == null) return const CircularProgressIndicator();

    // Live filter preview (matches the saved output closely).
    final filtered = applyFilterPreview(
      _filter,
      Image.file(File(widget.page.originalImagePath), fit: BoxFit.contain),
    );

    if (_cropEnabled) {
      // Show the UN-rotated image so the crop overlay coordinates stay in the
      // processor's crop space; rotation is shown as the "Rotate (N°)" badge.
      return AspectRatio(
        aspectRatio: aspect,
        child: Stack(
          fit: StackFit.expand,
          children: [
            filtered,
            CropCornerOverlay(
              imageAspect: aspect,
              corners: _corners,
              onChanged: (c) => setState(() => _corners = c),
            ),
          ],
        ),
      );
    }

    // Full live preview: filter + rotation.
    final preview = AspectRatio(aspectRatio: aspect, child: filtered);
    return _rotation % 4 == 0
        ? preview
        : RotatedBox(quarterTurns: _rotation, child: preview);
  }
}
