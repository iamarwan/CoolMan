# Flutter and its plugins ship their own keep rules; add app-specific rules here.
# Keep generic type info used by some plugins' JSON/reflection code.
-keepattributes Signature,*Annotation*
# Play Core is referenced by the Flutter engine for deferred components we don't use.
-dontwarn com.google.android.play.core.**
