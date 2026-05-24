import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_theme.dart';
import '../../services/upi_service.dart';
import 'upi_confirm_screen.dart';

/// Full-screen camera that scans UPI QR codes. On a valid scan, navigates
/// to [UpiConfirmScreen] with the parsed payment intent. Also supports
/// manually entering a VPA when no QR is available.
class ScanPayScreen extends StatefulWidget {
  const ScanPayScreen({super.key});

  @override
  State<ScanPayScreen> createState() => _ScanPayScreenState();
}

class _ScanPayScreenState extends State<ScanPayScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      final intent = UpiService.parse(raw);
      if (intent == null) continue;

      _handled = true;
      HapticFeedback.heavyImpact();
      await _controller.stop();
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => UpiConfirmScreen(intent: intent)),
      );
      return;
    }
  }

  Future<void> _enterVpaManually() async {
    final ctrl = TextEditingController();
    final vpa = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppTheme.cardSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter UPI ID',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'name@bank',
                  hintStyle: const TextStyle(color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (v) => Navigator.pop(sheetCtx, v.trim()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(sheetCtx, ctrl.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Continue',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (vpa == null || vpa.isEmpty || !vpa.contains('@') || !mounted) return;
    final intent = UpiPaymentIntent(vpa: vpa);
    await _controller.stop();
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => UpiConfirmScreen(intent: intent)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _ErrorOverlay(error: error),
          ),
          _ViewfinderOverlay(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _IconBubble(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  ValueListenableBuilder<MobileScannerState>(
                    valueListenable: _controller,
                    builder: (_, state, child) => _IconBubble(
                      icon: state.torchState == TorchState.on
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      onTap: () => _controller.toggleTorch(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Point your camera at a UPI QR code',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ).animate().fade(duration: 400.ms),
                    const SizedBox(height: 4),
                    const Text(
                      'Pay any UPI ID, log it as an expense automatically',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ).animate().fade(delay: 200.ms),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: _enterVpaManually,
                      icon: const Icon(Icons.keyboard_alt_outlined, size: 18),
                      label: const Text('Enter UPI ID manually'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accent,
                        side: BorderSide(
                            color: AppTheme.accent.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBubble({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _ViewfinderOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(builder: (_, c) {
        final side = c.maxWidth * 0.72;
        return Stack(
          children: [
            Positioned(
              left: (c.maxWidth - side) / 2,
              top: (c.maxHeight - side) / 2,
              child: Container(
                width: side, height: side,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: AppTheme.accent, width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(children: const [
                  Positioned(top: -1, left: -1, child: _Corner(tl: true)),
                  Positioned(top: -1, right: -1, child: _Corner(tr: true)),
                  Positioned(bottom: -1, left: -1, child: _Corner(bl: true)),
                  Positioned(bottom: -1, right: -1, child: _Corner(br: true)),
                ]),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _Corner extends StatelessWidget {
  final bool tl, tr, bl, br;
  const _Corner({this.tl = false, this.tr = false, this.bl = false, this.br = false});

  @override
  Widget build(BuildContext context) {
    const len = 22.0;
    const w = 3.0;
    return SizedBox(
      width: len, height: len,
      child: CustomPaint(
        painter: _CornerPainter(tl: tl, tr: tr, bl: bl, br: br, stroke: w),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool tl, tr, bl, br;
  final double stroke;
  _CornerPainter({required this.tl, required this.tr, required this.bl, required this.br, required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accent
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    if (tl) {
      canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), paint);
      canvas.drawLine(const Offset(0, 0), Offset(0, size.height), paint);
    } else if (tr) {
      canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), paint);
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), paint);
    } else if (bl) {
      canvas.drawLine(const Offset(0, 0), Offset(0, size.height), paint);
      canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), paint);
    } else if (br) {
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), paint);
      canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CornerPainter old) => false;
}

class _ErrorOverlay extends StatelessWidget {
  final MobileScannerException error;
  const _ErrorOverlay({required this.error});

  @override
  Widget build(BuildContext context) {
    final isPermissionDenied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPermissionDenied
                  ? Icons.no_photography_outlined
                  : Icons.error_outline,
              color: AppTheme.error,
              size: 56,
            ),
            const SizedBox(height: 18),
            Text(
              isPermissionDenied
                  ? 'Camera permission denied'
                  : 'Camera unavailable',
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isPermissionDenied
                  ? 'Tally needs the camera only to scan UPI QR codes. '
                      'Enable it in Settings to continue.'
                  : (error.errorDetails?.message ?? 'Could not start the camera.'),
              style: const TextStyle(
                  color: Colors.white60, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.black,
              ),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
