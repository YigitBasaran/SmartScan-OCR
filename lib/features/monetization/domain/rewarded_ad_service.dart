import 'package:flutter/widgets.dart';

/// Result of attempting to show a rewarded ad.
class RewardResult {
  const RewardResult({required this.earnedReward, this.errorMessage});

  final bool earnedReward;
  final String? errorMessage;
}

/// Shows a user-initiated rewarded ad that, when the reward is earned, unlocks a
/// watermark-free export for the current document only.
///
/// Kept behind an interface so the concrete ad SDK (Google Mobile Ads) can be
/// swapped in later without touching the export flow, and faked in tests. Ads
/// are always user-initiated — never auto-shown, and never gate scanning,
/// editing, saving, or viewing.
abstract class RewardedAdService {
  /// Whether a rewarded ad can currently be shown.
  Future<bool> isRewardedAdAvailable();

  /// Presents the rewarded ad and resolves once it is dismissed/completed.
  /// [RewardResult.earnedReward] is true only if the user earned the reward.
  ///
  /// Takes a [BuildContext] because the current (simulated) implementation
  /// presents a Flutter dialog; a real Google Mobile Ads implementation shows a
  /// native ad and ignores it.
  Future<RewardResult> showWatermarkRemovalAd(BuildContext context);
}
