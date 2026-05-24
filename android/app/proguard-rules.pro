# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Isar
-keep class dev.isar.** { *; }
-keep class isar.** { *; }
-keepclassmembers class ** {
    @dev.isar.* *;
}

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-keep class com.google.android.gms.common.** { *; }
-dontwarn com.google.android.gms.ads.**
-keep public class com.google.android.gms.ads.MobileAds { *; }
-keep public class com.google.android.gms.ads.AdRequest { *; }
-keep public class com.google.android.gms.ads.AdView { *; }
-keep public class com.google.android.gms.ads.AdSize { *; }
-keep public class com.google.android.gms.ads.LoadAdError { *; }

# Telephony / SMS
-keep class com.shounakmulay.telephony.** { *; }

# File picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Local notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**

# Play Core (used by Flutter deferred components — not used in this app)
-dontwarn com.google.android.play.core.**
