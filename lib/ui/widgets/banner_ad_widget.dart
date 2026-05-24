import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../services/ad_service.dart';

/// Anchored adaptive banner — sizes itself to the parent width and the
/// device's preferred banner height. Higher fill rate than the legacy
/// fixed 320x50 banner. Falls back to nothing while loading so the
/// surrounding layout doesn't reserve dead space.
class BannerAdWidget extends StatefulWidget {
  /// The AdMob ad unit ID to load. Defaults to [AdService.bannerAdUnitId]
  /// (the dashboard banner). Pass a different unit (e.g.
  /// [AdService.budgetBannerAdUnitId]) for other placements so AdMob can
  /// optimize fill per surface.
  final String? adUnitId;
  const BannerAdWidget({super.key, this.adUnitId});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  AnchoredAdaptiveBannerAdSize? _adSize;
  bool _loaded = false;
  bool _loading = false;
  int _retryCount = 0;
  Timer? _retryTimer;

  // Exponential backoff (capped at 1h) — prevents thrashing AdMob when no
  // fill is available, which can otherwise get the account flagged for
  // excessive request volume.
  static const _backoffSchedule = <int>[30, 60, 120, 300, 900, 1800, 3600];

  @override
  void dispose() {
    _retryTimer?.cancel();
    _ad?.dispose();
    super.dispose();
  }

  Future<void> _loadAd(int parentWidth) async {
    if (_loading) return;
    _loading = true;

    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(parentWidth);
    if (!mounted || size == null) {
      _loading = false;
      return;
    }

    _adSize = size;
    _ad?.dispose();
    _ad = BannerAd(
      adUnitId: widget.adUnitId ?? AdService.bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          debugPrint('[BannerAd] loaded (${size.width}x${size.height})');
          _retryCount = 0;
          _loading = false;
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _loading = false;
          _scheduleRetry(error, parentWidth);
        },
        onAdImpression: (_) => debugPrint('[BannerAd] impression'),
      ),
    );
    _ad!.load();
  }

  void _scheduleRetry(LoadAdError error, int parentWidth) {
    final delaySeconds =
        _backoffSchedule[_retryCount.clamp(0, _backoffSchedule.length - 1)];
    debugPrint(
      '[BannerAd] failed — code=${error.code} '
      'name=${_errorName(error.code)} '
      'domain=${error.domain} '
      'message=${error.message} '
      '— retry #${_retryCount + 1} in ${delaySeconds}s',
    );
    _retryCount++;
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: delaySeconds), () {
      if (mounted) _loadAd(parentWidth);
    });
  }

  // AdMob LoadAdError codes — useful when triaging tester reports.
  String _errorName(int code) {
    switch (code) {
      case 0: return 'INTERNAL_ERROR';
      case 1: return 'INVALID_REQUEST';
      case 2: return 'NETWORK_ERROR';
      case 3: return 'NO_FILL';
      case 8: return 'APP_ID_MISSING';
      case 9: return 'MEDIATION_NO_FILL';
      case 10: return 'INVALID_AD_SIZE';
      case 11: return 'INVALID_ARGUMENT';
      case 12: return 'REQUEST_ID_MISMATCH';
      default: return 'UNKNOWN';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        if (w.isFinite && w > 0 && _ad == null && _retryTimer == null) {
          // Defer to next frame so we don't trigger an async load inside build.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadAd(w.truncate());
          });
        }
        if (!_loaded || _ad == null || _adSize == null) {
          return const SizedBox.shrink();
        }
        return SizedBox(
          width: _adSize!.width.toDouble(),
          height: _adSize!.height.toDouble(),
          child: AdWidget(ad: _ad!),
        );
      },
    );
  }
}
