import Flutter
import UIKit
import Security

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /* Penanda bahwa aplikasi sudah pernah dijalankan setelah pemasangan.
   *
   * UserDefaults ikut terhapus saat aplikasi dihapus, sedangkan Keychain iOS
   * tidak. Tanpa penanda ini, token akses dan identitas pelanggan dari
   * pemasangan sebelumnya tetap terbaca oleh pemasangan baru di perangkat yang
   * sama — misalnya perangkat yang dipindah tangan. */
  private static let kunciPenandaPemasangan = "app_installed_v1"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    AppDelegate.bersihkanKeychainSaatPemasanganBaru()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  /// Menghapus seluruh isi Keychain aplikasi pada peluncuran pertama.
  ///
  /// Dijalankan sebelum Flutter membaca token, sehingga sesi lama tidak sempat
  /// dipulihkan. Kegagalan penghapusan tidak menghentikan aplikasi; sesi tetap
  /// dianggap tidak ada karena tidak ada server yang memverifikasinya.
  private static func bersihkanKeychainSaatPemasanganBaru() {
    let bawaan = UserDefaults.standard
    if bawaan.bool(forKey: kunciPenandaPemasangan) {
      return
    }

    hapusSemuaItemKeychain()
    bawaan.set(true, forKey: kunciPenandaPemasangan)
  }

  /// Menghapus semua item Keychain milik aplikasi lintas kelas akun.
  private static func hapusSemuaItemKeychain() {
    let kelasYangDicari: [CFString] = [
      kSecClassGenericPassword,
      kSecClassInternetPassword,
      kSecClassCertificate,
      kSecClassKey,
      kSecClassIdentity,
    ]

    for kelas in kelasYangDicari {
      let kueri: [String: Any] = [kSecClass as String: kelas]
      SecItemDelete(kueri as CFDictionary)
    }
  }
}
