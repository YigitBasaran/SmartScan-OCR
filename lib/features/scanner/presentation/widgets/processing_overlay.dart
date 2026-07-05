import 'package:flutter/material.dart';

/// Full-screen scrim shown while the OCR + PDF + save pipeline runs.
class ProcessingOverlay extends StatelessWidget {
  const ProcessingOverlay({
    super.key,
    required this.phaseLabel,
    required this.current,
    required this.total,
    this.progress,
  });

  final String phaseLabel;
  final int current;
  final int total;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: AbsorbPointer(
        child: ColoredBox(
          color: Colors.black54,
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: CircularProgressIndicator(value: progress),
                    ),
                    const SizedBox(height: 16),
                    Text(phaseLabel, style: theme.textTheme.titleMedium),
                    if (total > 0 && current > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Page $current of $total',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
