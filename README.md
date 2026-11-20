# MobilJuragan Mobile App

Aplikasi mobile pelanggan untuk pemesanan dan layanan rental mobil **CV. Mobil Juragan Express Transport** di Merauke, Papua Selatan. Aplikasi ini dibangun dengan framework Flutter dan bahasa pemrograman Dart, mengimplementasikan antarmuka *High-Fidelity* (Hi-Fi) yang responsif dan mengikuti prinsip desain antarmuka modern.

- **Desain Prototype (Figma):** [MobilJuragan MVP UI/UX Case Study (Hi-Fi)](https://www.figma.com/design/Ps9d41PfofqpOFXO2O6YGj/Untitled?node-id=0-1&t=C3uIavBnCubfhXV4-1)

---

## 1. Arsitektur & Alur Antarmuka

Aplikasi menggunakan arsitektur komponen modular (*component-driven UI*) dengan pemisahan antara model data, tema global, layar antarmuka, dan komponen widget pakai-ulang (*reusable widgets*):

```text
┌───────────────────────────────────────────────────┐
│         Aplikasi Pelanggan (Flutter Mobile)       │
├───────────────────────────────────────────────────┤
│ [Layar 01] Beranda (Home)                         │
│     ├── Hero Banner & Identitas Bisnis Merauke    │
│     └── Pratinjau Armada Unggulan                 │
│ [Layar 02] Pilih Kendaraan (Katalog & Filter)     │
│     ├── Filter Kategori (MPV, SUV, Pickup)        │
│     └── Kartu Spesifikasi & Status Ketersediaan   │
│ [Layar 03] Detail Kendaraan                       │
│     ├── Galeri Aset & Spesifikasi Teknis Armada   │
│     └── Informasi Konfirmasi Tarif Resmi          │
│ [Layar 04] Pilih Tanggal & Waktu Sewa             │
│     ├── Kalender Sewa & Durasi Hari               │
│     └── Estimasi Pengambilan & Pengembalian       │
│ [Layar Shell] 4-Tab Bottom Navigation Bar         │
│     ├── Beranda, Pesan, Status Sewa, Bantuan      │
└─────────────────────────┬─────────────────────────┘
                          │
             HTTP REST API │ (JSON Envelope)
                          ▼
┌───────────────────────────────────────────────────┐
│             MobilJuragan Backend API              │
│               (Express.js :4000)                  │
└───────────────────────────────────────────────────┘
```

---

## 2. Struktur Direktori Kunci

Berikut adalah struktur file dan modul penting pada aplikasi mobile:

```text
mobiljuragan-mobile/
├── assets/
│   └── images/              # Aset visual lokal armada resmi (Avanza, Fortuner, Hilux, Innova)
├── lib/
│   ├── main.dart            # Entrypoint utama aplikasi Flutter & MultiProvider
│   ├── controllers/         # Global State Management (Provider)
│   │   ├── booking_controller.dart # State siklus pemesanan, kalkulasi biaya, status sewa
│   │   └── vehicle_controller.dart # State katalog armada & penyaringan kategori
│   ├── models/
│   │   └── vehicle_model.dart # Data model entitas armada kendaraan & spesifikasi
│   ├── screens/
│   │   ├── home_screen.dart             # Layar Beranda utama pelanggan
│   │   ├── vehicle_selection_screen.dart # Layar Katalog & filter armada
│   │   ├── vehicle_detail_screen.dart    # Layar Detail spesifikasi kendaraan
│   │   ├── date_time_screen.dart         # Layar Pemilihan tanggal & durasi sewa
│   │   └── main_navigation_screen.dart   # Shell Container navigasi 4-tab bawah
│   ├── theme/
│   │   ├── app_colors.dart  # Definisi token warna primer, netral, dan status
│   │   └── app_theme.dart   # Konfigurasi ThemeData Material 3
│   └── widgets/
│       ├── bottom_nav_bar.dart    # Komponen reusable bar navigasi bawah
│       ├── custom_app_bar.dart    # Komponen header bar terstandarisasi
│       ├── spec_card_item.dart    # Komponen kartu badge spesifikasi mobil
│       └── vehicle_card_item.dart # Komponen kartu katalog mobil
├── pubspec.yaml             # Manifest package dependencies & deklarasi aset
└── analysis_options.yaml    # Konfigurasi linter & quality rules Dart
```

---

## 3. Prasyarat Pengembangan

- **Flutter SDK**: Versi $\ge$ 3.13 (disarankan Flutter 3.24+ atau terbaru)
- **Dart SDK**: Versi $\ge$ 3.0
- **Android Studio** / **VS Code** dengan ekstensi Flutter & Dart terpasang
- **Backend API**: Layanan backend MobilJuragan berjalan di port 4000 dengan basis data **MariaDB/MySQL** (lihat repositori `mobiljuragan-backend`). Seluruh kontrak REST API tetap konsisten dengan struktur data model Flutter.

---

## 4. Panduan Menjalankan Aplikasi

### Langkah 1: Unduh Dependencies
Buka terminal pada direktori project dan jalankan:
```bash
flutter pub get
```

### Langkah 2: Konfigurasi Endpoint Backend API
Secara bawaan, aplikasi mobile memakai `http://127.0.0.1:4000/api/v1` (lihat `lib/core/constants/api_constants.dart`).

- **Android Emulator / HP Asli via USB (disarankan):**
  Jalankan port forwarding agar `127.0.0.1` di perangkat mengarah ke laptop:
  ```bash
  adb reverse tcp:4000 tcp:4000
  # Tambahkan baris berikut hanya jika backend memakai MinIO lokal di port 9000:
  adb reverse tcp:9000 tcp:9000
  ```
- **Custom URL (misalnya via IP Wi-Fi atau server terpisah):**
  ```bash
  flutter run --dart-define=API_BASE_URL=http://192.168.1.x:4000/api/v1
  ```
- **Login Uji Coba Pelanggan:**
  Jika backend tidak memakai gateway WhatsApp (`WAPI_API_KEY`), pastikan `ALLOW_DEV_OTP_BYPASS=true` aktif di `.env` backend, lalu masukkan kode OTP `123456` saat login/registrasi.

### Langkah 3: Menjalankan Aplikasi
Pilih device target dan jalankan:
```bash
# Menjalankan di device default / emulator aktif
flutter run

# Menjalankan khusus di browser (Chrome)
flutter run -d chrome
```

### Langkah 4: Analisis Kualitas Kode & Pengujian
```bash
# Linter kode Dart
flutter analyze

# Menjalankan widget & unit test
flutter test
```
