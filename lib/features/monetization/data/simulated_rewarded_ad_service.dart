import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smartscanocr/features/monetization/domain/rewarded_ad_service.dart';

/// Placeholder [RewardedAdService] used while the real Google Mobile Ads plugin
/// is deferred (an open AGP-9 / Android-16 release-startup crash in
/// `google_mobile_ads` 9.0.0 makes it unsafe to ship yet).
///
/// It presents a visible demo "rewarded ad" dialog on **every** call — a short
/// countdown, then a Claim button; closing it early earns no reward — so the
/// per-export watermark-free flow is testable on-device. Replace with an
/// `AdMobRewardedAdService` (real `RewardedAd` load/show) once the plugin is
/// verified on this toolchain — no caller needs to change.
class SimulatedRewardedAdService implements RewardedAdService {
  const SimulatedRewardedAdService();

  @override
  Future<bool> isRewardedAdAvailable() async => true;

  @override
  Future<RewardResult> showWatermarkRemovalAd(BuildContext context) async {
    final claimed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _DemoAdDialog(),
    );
    return RewardResult(earnedReward: claimed ?? false);
  }
}

class _DemoAdDialog extends StatefulWidget {
  const _DemoAdDialog();

  @override
  State<_DemoAdDialog> createState() => _DemoAdDialogState();
}

class _DemoAdDialogState extends State<_DemoAdDialog> {
  static const _duration = 3;
  int _remaining = _duration;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= 1) {
        timer.cancel();
        setState(() => _remaining = 0);
      } else {
        setState(() => _remaining -= 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _remaining == 0;
    return AlertDialog(
      title: const Text('Rewarded ad'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_circle_outline,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            ready
                ? 'Thanks for watching. Claim your reward to export this PDF without the watermark.'
                : 'Demo ad playing… $_remaining',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '(Placeholder ad — real ads coming later.)',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: ready ? () => Navigator.pop(context, true) : null,
          child: const Text('Claim reward'),
        ),
      ],
    );
  }
}
