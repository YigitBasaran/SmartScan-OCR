# --- SmartScan OCR release (R8) rules ---
#
# cunning_document_scanner bundles Huawei HMS ML Kit as a non-Google fallback.
# That Huawei code references optional Cronet/BouncyCastle/Conscrypt libraries
# which are not included (and are never used on Google Play devices). Silence
# R8's missing-class warnings so the release build can complete.
-dontwarn com.huawei.**
-dontwarn org.chromium.net.**
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**

# Keep the scanner + ML Kit entry points (defensive; they are invoked from
# native/method-channel code and generated plugin registration).
-keep class biz.cunning.** { *; }
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
