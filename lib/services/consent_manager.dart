import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google UMP (User Messaging Platform) consent gathering.
///
/// Required by Play Store + AdMob for users in regulated regions (EU/UK/Swiss,
/// US states, etc). Must run BEFORE [MobileAds.initialize] so that personalized
/// vs. non-personalized ad serving honors the user's choice.
class ConsentManager {
  /// Gather consent if required by the user's region. Always completes —
  /// errors are logged but do not block app boot. Personalized ads are only
  /// served when the user has actually granted consent through the UMP form.
  static Future<void> gatherConsent() async {
    final completer = Completer<void>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        try {
          ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
            if (error != null) {
              debugPrint(
                  '[ConsentManager] Consent form error: ${error.errorCode} ${error.message}');
            }
            if (!completer.isCompleted) completer.complete();
          });
        } catch (e) {
          debugPrint('[ConsentManager] Consent form exception: $e');
          if (!completer.isCompleted) completer.complete();
        }
      },
      (FormError error) {
        debugPrint(
            '[ConsentManager] Consent info update failed: ${error.errorCode} ${error.message}');
        if (!completer.isCompleted) completer.complete();
      },
    );

    return completer.future;
  }

  /// Re-show the consent form on demand (e.g. from a Settings screen).
  /// Lets users revoke or modify their consent after the initial flow.
  static Future<void> showPrivacyOptionsForm() async {
    final completer = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((FormError? error) {
      if (error != null) {
        debugPrint(
            '[ConsentManager] Privacy options form error: ${error.errorCode} ${error.message}');
      }
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  static Future<bool> isPrivacyOptionsRequired() async {
    final status = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
    return status == PrivacyOptionsRequirementStatus.required;
  }
}
