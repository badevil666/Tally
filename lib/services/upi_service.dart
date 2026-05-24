import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Parsed UPI payment intent — produced from a scanned QR code or manual entry.
///
/// UPI deep-link spec: https://www.npci.org.in/what-we-do/upi/product-overview
/// Canonical URI: upi://pay?pa=...&pn=...&am=...&cu=INR&tn=...&mc=...
class UpiPaymentIntent {
  final String vpa;        // payee address (required)
  final String? name;      // payee name
  final double? amount;    // fixed amount, if QR encodes one
  final String? note;      // transaction note
  final String? merchantCode;
  final bool amountLocked; // true when the QR specifies a non-editable amount

  const UpiPaymentIntent({
    required this.vpa,
    this.name,
    this.amount,
    this.note,
    this.merchantCode,
    this.amountLocked = false,
  });

  String get displayName => (name?.trim().isNotEmpty ?? false) ? name!.trim() : vpa;
}

class UpiService {
  /// Parse a UPI URI (typically scanned from a QR code) into a structured
  /// payment intent. Returns null if the input is not a valid `upi://pay` URI.
  static UpiPaymentIntent? parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;
    if (uri.scheme.toLowerCase() != 'upi') return null;
    if (uri.host.toLowerCase() != 'pay' && uri.path.toLowerCase() != 'pay') {
      return null;
    }

    final params = uri.queryParameters;
    final vpa = params['pa']?.trim();
    if (vpa == null || vpa.isEmpty || !vpa.contains('@')) return null;

    double? amount;
    final amStr = params['am']?.trim();
    if (amStr != null && amStr.isNotEmpty) {
      amount = double.tryParse(amStr);
    }

    return UpiPaymentIntent(
      vpa: vpa,
      name: params['pn'],
      amount: amount,
      note: params['tn'],
      merchantCode: params['mc'],
      // Some merchant QRs include `am` AND a separate "amount locked" hint via
      // `minam`/`maxam` or the absence of a UI flag. NPCI does not standardize
      // this — we treat any present `am` as a suggested default that the user
      // can still edit, except when both `am` and `mc` are present (merchant QR
      // with fixed price), which is the common case for printed shop QRs.
      amountLocked: amount != null && (params['mc']?.isNotEmpty ?? false),
    );
  }

  /// Build an outbound `upi://pay` URI from a payment intent + final amount.
  static Uri buildUri({
    required String vpa,
    required String payeeName,
    required double amount,
    String? note,
  }) {
    final params = <String, String>{
      'pa': vpa,
      'pn': payeeName,
      'am': amount.toStringAsFixed(2),
      'cu': 'INR',
    };
    if (note != null && note.trim().isNotEmpty) {
      params['tn'] = note.trim();
    }
    return Uri(scheme: 'upi', host: 'pay', queryParameters: params);
  }

  /// Launch a UPI payment. Android shows a chooser of installed UPI apps
  /// (GPay / PhonePe / Paytm / BHIM / etc) when more than one is present.
  ///
  /// Returns true if the OS accepted the intent (i.e. a UPI app exists and
  /// was launched). Does NOT indicate payment success — UPI deep-link
  /// callbacks are unreliable, so success must be confirmed by the user or
  /// reconciled via the bank's debit SMS.
  static Future<bool> launchPayment(Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      debugPrint('[UpiService] launchUrl -> $ok  ($uri)');
      return ok;
    } catch (e) {
      debugPrint('[UpiService] launchUrl failed: $e');
      return false;
    }
  }
}
