import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

/* Konfigurasi tanda tangan rilis.
 *
 * Sebelumnya build rilis ditandatangani dengan kunci debug, sehingga siapa pun
 * yang memegang kunci debug Flutter dapat membuat paket pembaruan yang disetujui
 * Android sebagai aplikasi yang sama. Nilai diambil dari android/key.properties
 * bila berkas itu ada (tidak ikut di-commit), atau dari environment variable
 * saat build berjalan di server CI. Build debug tidak terpengaruh.
 */
val berkasPropertiKunci = rootProject.file("key.properties")
val propertiKunci = Properties().apply {
    if (berkasPropertiKunci.exists()) {
        FileInputStream(berkasPropertiKunci).use { aliran -> load(aliran) }
    }
}

fun nilaiKunci(namaProperti: String, namaEnv: String): String? {
    val dariProperti = propertiKunci.getProperty(namaProperti)?.takeIf { it.isNotBlank() }
    return dariProperti ?: System.getenv(namaEnv)?.takeIf { it.isNotBlank() }
}

val lokasiKeyStore = nilaiKunci("storeFile", "MOBILJURAGAN_STORE_FILE")
val sandiKeyStore = nilaiKunci("storePassword", "MOBILJURAGAN_STORE_PASSWORD")
val aliasKunci = nilaiKunci("keyAlias", "MOBILJURAGAN_KEY_ALIAS")
val sandiKunci = nilaiKunci("keyPassword", "MOBILJURAGAN_KEY_PASSWORD")
val kunciRilisLengkap =
    lokasiKeyStore != null && sandiKeyStore != null && aliasKunci != null && sandiKunci != null

android {
    namespace = "id.mobiljuragan.mobiljuragan_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "id.mobiljuragan.mobiljuragan_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (kunciRilisLengkap) {
            create("rilis") {
                storeFile = file(lokasiKeyStore!!)
                storePassword = sandiKeyStore
                keyAlias = aliasKunci
                keyPassword = sandiKunci
            }
        }
    }

    buildTypes {
        release {
            /* Build rilis hanya boleh ditandatangani kunci rilis, tidak pernah
               kunci debug. Bila kunci belum tersedia, konfigurasi penandatangan
               dibiarkan kosong dan pemeriksaan di bawah menghentikan build
               khusus untuk tugas rilis — build debug tetap berjalan normal. */
            if (kunciRilisLengkap) {
                signingConfig = signingConfigs.getByName("rilis")
            }
        }
    }
}

/* Pemeriksaan dijalankan saat tugas Gradle benar-benar dipilih, bukan saat
 * konfigurasi. Melempar galat di dalam blok buildTypes akan mematikan seluruh
 * build (termasuk `flutter run` dan `flutter build apk --debug`) hanya karena
 * berkas kunci rilis tidak ada di mesin pengembang. */
gradle.taskGraph.whenReady { grafTugas ->
    val adaTugasRilis = grafTugas.allTasks.any { tugas ->
        tugas.name.contains("Release", ignoreCase = true) &&
            (tugas.name.startsWith("assemble") ||
                tugas.name.startsWith("bundle") ||
                tugas.name.startsWith("package"))
    }
    if (adaTugasRilis && !kunciRilisLengkap) {
        throw GradleException(
            "Kunci rilis belum tersedia. Sediakan android/key.properties " +
                "(storeFile, storePassword, keyAlias, keyPassword) atau set " +
                "MOBILJURAGAN_STORE_FILE, MOBILJURAGAN_STORE_PASSWORD, " +
                "MOBILJURAGAN_KEY_ALIAS, dan MOBILJURAGAN_KEY_PASSWORD. " +
                "Build rilis tidak lagi memakai kunci debug."
        )
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
