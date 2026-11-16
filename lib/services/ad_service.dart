/// Offline-safe ad facade for the Android testing build.
///
/// The ID below is Google's official rewarded test unit ID. No ad SDK is
/// loaded in this project yet, so calls safely report that an ad is unavailable.
class AdService {
  static const String rewardedTestAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String androidApplicationTestId =
      'ca-app-pub-3940256099942544~3347511713';

  bool _isRewardedAdReady = false;
  bool get isRewardedAdReady => _isRewardedAdReady;
  bool get isSimulationOnly => true;

  Future<bool> loadRewardedAd() async {
    try {
      _isRewardedAdReady = false;
      return false;
    } catch (_) {
      _isRewardedAdReady = false;
      return false;
    }
  }

  Future<bool> showRewardedAd({
    required void Function() onReward,
  }) async {
    try {
      if (!_isRewardedAdReady) return false;
      _isRewardedAdReady = false;
      onReward();
      return true;
    } catch (_) {
      _isRewardedAdReady = false;
      return false;
    }
  }

  void dispose() {
    _isRewardedAdReady = false;
  }
}
