import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  // Production AdMob unit IDs (publisher ca-app-pub-1512419225626475).
  // Dashboard banner.
  static const bannerAdUnitId         = 'ca-app-pub-1512419225626475/9820594431';
  // Budget Planner banner (banner 2).
  static const budgetBannerAdUnitId   = 'ca-app-pub-1512419225626475/5350220557';
  static const _interstitialAdUnitId  = 'ca-app-pub-1512419225626475/4376696065';

  static InterstitialAd? _interstitial;
  static DateTime? _lastInterstitialShown;
  static const _interstitialCooldown = Duration(minutes: 3);
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    final initStatus = await MobileAds.instance.initialize();
    _initialized = true;
    debugPrint('[AdService] MobileAds initialized. Adapter statuses:');
    for (final entry in initStatus.adapterStatuses.entries) {
      debugPrint('[AdService]   ${entry.key}: ${entry.value.state} — ${entry.value.description}');
    }
    _loadInterstitial();
  }

  // ── Interstitial ──────────────────────────────────────────────────────────

  static void _loadInterstitial() {
    debugPrint('[AdService] Loading interstitial...');
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdService] Interstitial loaded ✓');
          _interstitial = ad;
          _interstitial!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitial = null;
              _loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('[AdService] Interstitial failed to show: ${error.code} ${error.message}');
              ad.dispose();
              _interstitial = null;
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdService] Interstitial failed to load: ${error.code} — ${error.message} — retrying in 30s');
          _interstitial = null;
          Future.delayed(const Duration(seconds: 30), _loadInterstitial);
        },
      ),
    );
  }

  /// Show the interstitial if ready and cooldown has passed.
  /// Always calls [onComplete] — either after the ad closes or immediately.
  static void showInterstitial({required void Function() onComplete}) {
    final now = DateTime.now();
    final cooledDown = _lastInterstitialShown == null ||
        now.difference(_lastInterstitialShown!) >= _interstitialCooldown;

    debugPrint('[AdService] showInterstitial — ready: ${_interstitial != null}, cooledDown: $cooledDown');
    if (_interstitial != null && cooledDown) {
      _lastInterstitialShown = now;
      _interstitial!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitial = null;
          _loadInterstitial();
          onComplete();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('[AdService] Interstitial failed to show: ${error.code} ${error.message}');
          ad.dispose();
          _interstitial = null;
          _loadInterstitial();
          onComplete();
        },
      );
      _interstitial!.show();
    } else {
      onComplete(); // cooldown active or ad not ready — skip
    }
  }
}
