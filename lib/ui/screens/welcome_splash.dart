import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Animated welcome screen — renders immediately on cold start.
///
/// Sequence (≈1.6s total):
///   1. Tally symbol (4 vertical bars + diagonal slash) scales + fades in.
///   2. "T A L L Y" letters appear one at a time, left-to-right.
///   3. Brief hold, then [onComplete] fires.
///
/// Symbol is drawn with pure Flutter widgets — no asset dependency, so
/// it shows instantly without waiting on image decode.
class WelcomeSplash extends StatefulWidget {
  final VoidCallback onComplete;
  const WelcomeSplash({super.key, required this.onComplete});

  @override
  State<WelcomeSplash> createState() => _WelcomeSplashState();
}

class _WelcomeSplashState extends State<WelcomeSplash> {
  static const _gold = Color(0xFFD4AF37);
  static const _bg = Color(0xFF000000);

  static const _letterStagger = Duration(milliseconds: 120);
  static const _letterDuration = Duration(milliseconds: 280);
  // No symbol entrance — the native splash already painted it. We pick
  // up exactly where the native splash leaves off; the letters slide in
  // beneath the same symbol.
  static const _letterStart = Duration(milliseconds: 50);
  static const _holdAfter = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    final total = _letterStart +
        _letterStagger * 5 +
        _letterDuration +
        _holdAfter;
    Future.delayed(total, () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    const letters = ['T', 'A', 'L', 'L', 'Y'];

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tally symbol — no entrance animation; the native splash
              // already painted it identically. We just hold it in place.
              const _TallySymbol(size: 180, color: _gold),

              const SizedBox(height: 24),

              // T A L L Y — appears beneath the existing symbol, staggered
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < letters.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Text(
                        letters[i],
                        style: const TextStyle(
                          color: _gold,
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          height: 1,
                        ),
                      )
                          .animate()
                          .fadeIn(
                            delay: _letterStart + (_letterStagger * i),
                            duration: _letterDuration,
                            curve: Curves.easeOut,
                          )
                          .slideY(
                            begin: 0.4,
                            end: 0,
                            delay: _letterStart + (_letterStagger * i),
                            duration: _letterDuration,
                            curve: Curves.easeOutCubic,
                          ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 4 vertical tally bars + 1 diagonal slash. Pure widgets, no asset.
class _TallySymbol extends StatelessWidget {
  final double size;
  final Color color;
  const _TallySymbol({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    final s = size / 180;          // proportional scale
    final barW = 12.0 * s;
    final barH = 130.0 * s;
    final gap = 22.0 * s;
    final totalW = 4 * barW + 3 * gap;
    final startX = (size - totalW) / 2;
    final barTop = (size - barH) / 2;
    final slashW = totalW + 30.0 * s;
    final slashH = 13.0 * s;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          for (int i = 0; i < 4; i++)
            Positioned(
              left: startX + i * (barW + gap),
              top: barTop,
              child: Container(
                width: barW,
                height: barH,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(barW / 2),
                ),
              ),
            ),
          Positioned(
            left: (size - slashW) / 2,
            top: (size - slashH) / 2,
            child: Transform.rotate(
              angle: -0.35, // ≈ -20°
              child: Container(
                width: slashW,
                height: slashH,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(slashH / 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
