# MobilJuragan Mobile App

Aplikasi mobile pelanggan untuk pemesanan dan layanan rental mobil **CV. Mobil Juragan Express Transport** di Merauke, Papua Selatan. Aplikasi ini dibangun dengan framework Flutter dan bahasa pemrograman Dart, mengimplementasikan antarmuka *High-Fidelity* (Hi-Fi) yang responsif dan mengikuti prinsip desain antarmuka modern.

- **Desain Prototype (Figma):** [MobilJuragan MVP UI/UX Case Study (Hi-Fi)](https://www.figma.com/design/Rxdv5kRYC8NiQpdWJhoIGJ/MobilJuragan-MVP-%E2%80%94-UI-UX-Case-Study?node-id=1006-92&t=i7Sp7eCwUQ0gnFEu-1)

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
- **Backend API**: Layanan backend MobilJuragan berjalan di port 4000 (lihat repositori `mobiljuragan-backend`).

---

## 4. Panduan Menjalankan Aplikasi

### Langkah 1: Unduh Dependencies
Buka terminal pada direktori project dan jalankan:
```bash
flutter pub get
```

### Langkah 2: Konfigurasi Endpoint Backend API
Aplikasi mobile berkomunikasi dengan backend Express via REST API:
- **Android Emulator**: Gunakan alamat `http://10.0.2.2:4000/api/v1` *(karena `localhost` di dalam emulator merujuk ke dirinya sendiri)*.
- **iOS Simulator / Web**: Gunakan alamat `http://localhost:4000/api/v1`.
- **Device Fisik (HP Asli)**: Gunakan IP lokal workstation (contoh: `http://192.168.1.x:4000/api/v1`).

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
