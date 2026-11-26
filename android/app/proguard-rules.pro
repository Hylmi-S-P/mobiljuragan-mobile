# Jaga seluruh kelas JNI milik shared_preferences_android, jni, dan tipe Kotlin
# (Continuation, Result, Result$Failure) yang dicari berdasarkan descriptor
# JNI saat runtime agar tidak dihilangkan atau diubah namanya oleh R8 di rilis.
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class kotlin.coroutines.** { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$** { *; }
-keep class com.github.dart_lang.jni.** { *; }
-keep class com.github.dart_lang.jni_flutter.** { *; }

# Notifikasi lokal (GSON & receiver jadwal) pada build rilis R8.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# Penyimpanan kredensial aman (FlutterSecureStorage & Google Tink).
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.errorprone.annotations.**

# Geolocator & layanan lokasi Play Services.
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.google.android.gms.**
