# Jaga seluruh kelas JNI milik shared_preferences_android, jni, dan tipe Kotlin
# (Continuation, Result, Result$Failure) yang dicari berdasarkan descriptor
# JNI saat runtime agar tidak dihilangkan atau diubah namanya oleh R8 di rilis.
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class kotlin.coroutines.** { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$** { *; }
-keep class com.github.dart_lang.jni.** { *; }
-keep class com.github.dart_lang.jni_flutter.** { *; }
