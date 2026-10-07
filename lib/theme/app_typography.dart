import 'package:flutter/material.dart';

/// Skala tipografi terpusat aplikasi MobilJuragan.
///
/// Sebelum ini setiap layar menuliskan fontSize dan fontWeight sendiri,
/// sehingga terkumpul 480 deklarasi dengan 21 ukuran berbeda (8,5 sampai 34).
/// Akibatnya ukuran teks yang perannya sama bisa berbeda antar layar, dan
/// mengubah satu gaya menuntut menyunting puluhan berkas.
///
/// Skala ini menurunkan 21 ukuran menjadi 14 langkah, disusun dari nilai yang
/// sudah dipakai aplikasi. Nilai pecahan yang jarang (8,5 / 9,5 / 10,5 / 11,5 /
/// 12,5 / 13,5) disatukan ke langkah terdekat; selisihnya 0,5 px sehingga tidak
/// terlihat, dan justru menghilangkan ketidakkonsistenan antar layar.
///
/// Pemakaian:
///   Text('Total Biaya', style: AppTypography.body)
///   Text('Rp 1.325.000', style: AppTypography.amountLarge)
///   Text('Tersedia', style: AppTypography.badge.copyWith(color: warnaLain))
class AppTypography {
  AppTypography._();

  // ---------------------------------------------------------------------------
  // Langkah ukuran
  // ---------------------------------------------------------------------------
  // Dipakai langsung bila sebuah widget perlu angka mentah, misalnya saat
  // menghitung ukuran ikon yang harus sepadan dengan teks di sebelahnya.

  /// 9 px - label sangat kecil di dalam badge dan chip.
  static const double sizeMicro = 9;

  /// 10 px - label badge, tag, dan keterangan pendukung.
  static const double sizeTiny = 10;

  /// 11 px - teks bantuan, subjudul kartu, dan metadata.
  static const double sizeCaption = 11;

  /// 12 px - teks isi utama untuk keterangan dan paragraf pendek.
  static const double sizeBody = 12;

  /// 13 px - teks isi yang lebih menonjol dan judul kartu.
  static const double sizeBodyLarge = 13;

  /// 14 px - judul bagian dan label tombol utama.
  static const double sizeTitle = 14;

  /// 15 px - nominal uang yang menonjol.
  static const double sizeAmount = 15;

  /// 16 px - judul halaman dan nominal besar.
  static const double sizeHeading = 16;

  /// 18 px - angka metrik ringkasan.
  static const double sizeMetric = 18;

  /// 20 px - judul besar dan angka metrik utama.
  static const double sizeDisplay = 20;

  /// 22 px - angka pada pemilih tanggal dan waktu.
  static const double sizePicker = 22;

  /// 28 px - nama brand pada splash screen.
  static const double sizeBrandName = 28;

  /// 32 px - angka besar penunjuk jam dan menit.
  static const double sizeClock = 32;

  /// 34 px - inisial logo pada splash screen.
  static const double sizeBrand = 34;

  // ---------------------------------------------------------------------------
  // Gaya siap pakai
  // ---------------------------------------------------------------------------
  // Semua gaya memakai font Inter. Warna tidak disertakan agar tetap mengikuti
  // tema; tambahkan lewat copyWith bila perlu warna tertentu.

  // --- Badge dan tag ---

  /// Label sangat kecil di dalam badge, misalnya penanda "GRATIS".
  static const TextStyle badgeMicro = TextStyle(
    fontSize: sizeMicro,
    fontWeight: FontWeight.w700,
    fontFamily: 'Inter',
  );

  /// Badge dan tag standar, misalnya "Tersedia" atau "Lepas Kunci".
  static const TextStyle badge = TextStyle(
    fontSize: sizeTiny,
    fontWeight: FontWeight.w700,
    fontFamily: 'Inter',
  );

  /// Badge yang perlu lebih tegas, misalnya status pembayaran.
  static const TextStyle badgeStrong = TextStyle(
    fontSize: sizeTiny,
    fontWeight: FontWeight.w800,
    fontFamily: 'Inter',
  );

  // --- Keterangan dan metadata ---

  /// Keterangan pendukung berukuran 10 px.
  static const TextStyle captionTiny = TextStyle(
    fontSize: sizeTiny,
    fontWeight: FontWeight.w500,
    fontFamily: 'Inter',
  );

  /// Teks bantuan dan metadata.
  static const TextStyle caption = TextStyle(
    fontSize: sizeCaption,
    fontWeight: FontWeight.w400,
    fontFamily: 'Inter',
  );

  /// Metadata yang perlu sedikit lebih tegas.
  static const TextStyle captionMedium = TextStyle(
    fontSize: sizeCaption,
    fontWeight: FontWeight.w500,
    fontFamily: 'Inter',
  );

  /// Keterangan penting berukuran kecil.
  static const TextStyle captionStrong = TextStyle(
    fontSize: sizeCaption,
    fontWeight: FontWeight.w600,
    fontFamily: 'Inter',
  );

  /// Keterangan kecil yang paling menonjol.
  static const TextStyle captionBold = TextStyle(
    fontSize: sizeCaption,
    fontWeight: FontWeight.w700,
    fontFamily: 'Inter',
  );

  // --- Teks isi ---

  /// Teks isi standar.
  static const TextStyle body = TextStyle(
    fontSize: sizeBody,
    fontWeight: FontWeight.w400,
    fontFamily: 'Inter',
  );

  /// Teks isi dengan penekanan ringan.
  static const TextStyle bodyMedium = TextStyle(
    fontSize: sizeBody,
    fontWeight: FontWeight.w500,
    fontFamily: 'Inter',
  );

  /// Nilai penting di dalam teks isi.
  static const TextStyle bodyStrong = TextStyle(
    fontSize: sizeBody,
    fontWeight: FontWeight.w600,
    fontFamily: 'Inter',
  );

  /// Teks isi yang paling tegas, sering dipakai untuk nilai label.
  static const TextStyle bodyBold = TextStyle(
    fontSize: sizeBody,
    fontWeight: FontWeight.w700,
    fontFamily: 'Inter',
  );

  /// Teks isi berukuran 13 px.
  static const TextStyle bodyLarge = TextStyle(
    fontSize: sizeBodyLarge,
    fontWeight: FontWeight.w400,
    fontFamily: 'Inter',
  );

  /// Teks isi 13 px dengan penekanan ringan.
  static const TextStyle bodyLargeMedium = TextStyle(
    fontSize: sizeBodyLarge,
    fontWeight: FontWeight.w500,
    fontFamily: 'Inter',
  );

  /// Teks isi 13 px dengan penekanan sedang.
  static const TextStyle bodyLargeStrong = TextStyle(
    fontSize: sizeBodyLarge,
    fontWeight: FontWeight.w600,
    fontFamily: 'Inter',
  );

  // --- Judul ---

  /// Judul kartu.
  static const TextStyle cardTitle = TextStyle(
    fontSize: sizeBodyLarge,
    fontWeight: FontWeight.w700,
    fontFamily: 'Inter',
  );

  /// Judul kartu yang perlu lebih tegas.
  static const TextStyle cardTitleStrong = TextStyle(
    fontSize: sizeBodyLarge,
    fontWeight: FontWeight.w800,
    fontFamily: 'Inter',
  );

  /// Judul bagian berukuran 14 px.
  static const TextStyle sectionTitle = TextStyle(
    fontSize: sizeTitle,
    fontWeight: FontWeight.w700,
    fontFamily: 'Inter',
  );

  /// Judul halaman.
  static const TextStyle pageTitle = TextStyle(
    fontSize: sizeHeading,
    fontWeight: FontWeight.w700,
    fontFamily: 'Inter',
  );

  /// Judul halaman yang perlu lebih tegas.
  static const TextStyle pageTitleStrong = TextStyle(
    fontSize: sizeHeading,
    fontWeight: FontWeight.w800,
    fontFamily: 'Inter',
  );

  // --- Tombol ---

  /// Label tombol utama.
  static const TextStyle button = TextStyle(
    fontSize: sizeTitle,
    fontWeight: FontWeight.w700,
    fontFamily: 'Inter',
  );

  /// Label tombol yang perlu lebih tegas.
  static const TextStyle buttonStrong = TextStyle(
    fontSize: sizeTitle,
    fontWeight: FontWeight.w800,
    fontFamily: 'Inter',
  );

  /// Label tombol berukuran lebih kecil.
  static const TextStyle buttonSmall = TextStyle(
    fontSize: sizeBodyLarge,
    fontWeight: FontWeight.w700,
    fontFamily: 'Inter',
  );

  // --- Angka dan nominal ---

  /// Nominal uang yang menonjol.
  static const TextStyle amount = TextStyle(
    fontSize: sizeAmount,
    fontWeight: FontWeight.w700,
    fontFamily: 'Inter',
  );

  /// Nominal uang yang paling menonjol.
  static const TextStyle amountStrong = TextStyle(
    fontSize: sizeAmount,
    fontWeight: FontWeight.w800,
    fontFamily: 'Inter',
  );

  /// Nominal besar, misalnya total tarif final.
  static const TextStyle amountLarge = TextStyle(
    fontSize: sizeHeading,
    fontWeight: FontWeight.w800,
    fontFamily: 'Inter',
  );

  /// Angka metrik ringkasan, misalnya jumlah sewa aktif.
  static const TextStyle metric = TextStyle(
    fontSize: sizeMetric,
    fontWeight: FontWeight.w800,
    fontFamily: 'Inter',
  );

  /// Angka metrik utama.
  static const TextStyle metricLarge = TextStyle(
    fontSize: sizeDisplay,
    fontWeight: FontWeight.w800,
    fontFamily: 'Inter',
  );

  // --- Khusus ---

  /// Angka pada pemilih tanggal dan waktu.
  static const TextStyle picker = TextStyle(
    fontSize: sizePicker,
    fontWeight: FontWeight.w700,
    fontFamily: 'Inter',
  );

  /// Angka besar penunjuk jam dan menit.
  static const TextStyle clockDisplay = TextStyle(
    fontSize: sizeClock,
    fontWeight: FontWeight.w800,
    fontFamily: 'Inter',
  );

  /// Inisial logo pada splash screen.
  static const TextStyle brandMark = TextStyle(
    fontSize: sizeBrand,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.5,
    fontFamily: 'Inter',
  );

  /// Nama brand pada splash screen.
  static const TextStyle brandName = TextStyle(
    fontSize: sizeBrandName,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    fontFamily: 'Inter',
  );
}