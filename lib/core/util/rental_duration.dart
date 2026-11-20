/// Perhitungan durasi sewa yang harus sama dengan aturan server.
///
/// Server membulatkan ke atas dan minimal satu hari (`hitungHariSewa` di
/// `backend/src/lib/tariff.ts`). Sebelumnya aplikasi memakai pembulatan ke bawah,
/// sehingga rentang yang menyisakan jam menghasilkan jumlah hari — dan total
/// perkiraan — yang lebih kecil dari tagihan server.
int hitungHariSewa(DateTime mulai, DateTime selesai) {
  final selisihMs = selesai.difference(mulai).inMilliseconds;
  final hari = (selisihMs / Duration.millisecondsPerDay).ceil();
  return hari > 0 ? hari : 1;
}

/// Membaca jam dan menit dari label seperti `09.00 WIT` atau `09:00`.
///
/// Mengembalikan `null` bila label tidak bisa dibaca, supaya pemanggil bisa
/// memakai jam default tanpa menebak.
({int jam, int menit})? jamMenitDariLabel(String label) {
  final cocok = RegExp(r'(\d{1,2})[.:](\d{2})').firstMatch(label);
  if (cocok == null) return null;

  final jam = int.tryParse(cocok.group(1)!);
  final menit = int.tryParse(cocok.group(2)!);
  if (jam == null || menit == null) return null;
  if (jam < 0 || jam > 23 || menit < 0 || menit > 59) return null;

  return (jam: jam, menit: menit);
}

/// Menggabungkan tanggal (yang biasanya tengah malam) dengan jam pilihan
/// pelanggan.
///
/// Tanpa ini, jam yang dipilih di layar tidak pernah sampai ke server dan
/// pesanan selalu tercatat mulai pukul 00.00 WIT.
DateTime gabungTanggalDanJam(DateTime tanggal, String labelJam) {
  final bagian = jamMenitDariLabel(labelJam);
  if (bagian == null) return tanggal;

  return DateTime(tanggal.year, tanggal.month, tanggal.day, bagian.jam, bagian.menit);
}

const int minBookingLeadHours = 2;
const int maxBookingAdvanceDays = 60;
const int operationalStartMinutes = 6 * 60;
const int operationalEndMinutes = 22 * 60;

/// Membuang komponen jam sehingga hanya menyisakan tahun, bulan, dan tanggal.
DateTime tanggalSaja(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// Membentuk label jam baku seperti `09.00 WIT`.
String formatJamWit(int jam, int menit) =>
    '${jam.toString().padLeft(2, '0')}.${menit.toString().padLeft(2, '0')} WIT';

/// Memeriksa apakah jam & menit berada dalam rentang operasional 06.00 s.d. 22.00 WIT.
bool adalahJamOperasional(int jam, int menit) {
  final totalMinutes = jam * 60 + menit;
  return totalMinutes >= operationalStartMinutes &&
      totalMinutes <= operationalEndMinutes;
}

/// Menghitung waktu jemput paling awal yang diperbolehkan dari waktu sekarang.
///
/// Detik dibulatkan ke atas ke menit penuh berikutnya supaya jam yang dipilih
/// di picker tidak pernah kurang beberapa detik dari batas minimal.
DateTime waktuJemputPalingAwal(
  DateTime now, {
  Duration leadTime = const Duration(hours: minBookingLeadHours),
}) {
  final punyaSisaDetik =
      now.second > 0 || now.millisecond > 0 || now.microsecond > 0;
  final basisMenit = DateTime(
    now.year,
    now.month,
    now.day,
    now.hour,
    now.minute,
  ).add(punyaSisaDetik ? const Duration(minutes: 1) : Duration.zero);
  return basisMenit.add(leadTime);
}

/// Tanggal paling awal yang masih punya slot penjemputan operasional (>= 2 jam).
DateTime tanggalMulaiPalingAwal(DateTime now) {
  final hariIni = tanggalSaja(now);
  if (waktuJemputPalingAwal(now).isAfter(tutupOperasional(hariIni))) {
    return hariIni.add(const Duration(days: 1));
  }
  return hariIni;
}

DateTime tutupOperasional(DateTime dt) =>
    DateTime(dt.year, dt.month, dt.day, 22, 0);

/// Batas tanggal mulai terjauh yang dapat dipilih pelanggan (60 hari ke depan).
DateTime batasTanggalMulaiMaksimal(DateTime now) =>
    tanggalSaja(now).add(const Duration(days: maxBookingAdvanceDays));

/// Mengembalikan true bila kombinasi tanggal + jam memenuhi minimal jeda 2 jam.
bool jadwalMulaiMemenuhiLeadTime(
  DateTime tanggal,
  int jam,
  int menit,
  DateTime now, {
  Duration leadTime = const Duration(hours: minBookingLeadHours),
}) {
  final pickup = DateTime(tanggal.year, tanggal.month, tanggal.day, jam, menit);
  return !pickup.isBefore(waktuJemputPalingAwal(now, leadTime: leadTime));
}

/// Menyesuaikan jam pilihan agar tetap valid saat tanggal berganti ke hari ini.
String jamValidUntukTanggal({
  required DateTime tanggal,
  required String labelSekarang,
  required DateTime now,
}) {
  final parsed = jamMenitDariLabel(labelSekarang);
  final hariPilihan = tanggalSaja(tanggal);
  final hariIni = tanggalSaja(now);

  if (parsed != null &&
      adalahJamOperasional(parsed.jam, parsed.menit) &&
      (!hariPilihan.isAtSameMomentAs(hariIni) ||
          jadwalMulaiMemenuhiLeadTime(
            hariPilihan,
            parsed.jam,
            parsed.menit,
            now,
          ))) {
    return formatJamWit(parsed.jam, parsed.menit);
  }

  if (hariPilihan.isAtSameMomentAs(hariIni)) {
    final minPickup = waktuJemputPalingAwal(now);
    final bukaHariIni = DateTime(hariIni.year, hariIni.month, hariIni.day, 6, 0);
    final kandidat = minPickup.isAfter(bukaHariIni) ? minPickup : bukaHariIni;
    if (!kandidat.isAfter(tutupOperasional(hariIni))) {
      return formatJamWit(kandidat.hour, kandidat.minute);
    }
  }

  return '09.00 WIT';
}

/// Memvalidasi jadwal sewa lengkap; mengembalikan pesan kesalahan jika tidak sah.
String? validasiJadwalSewa({
  required DateTime tanggal,
  required String labelJam,
  required DateTime now,
  Duration leadTime = const Duration(hours: minBookingLeadHours),
}) {
  final parsed = jamMenitDariLabel(labelJam);
  if (parsed == null) {
    return 'Format jam tidak valid. Silakan pilih waktu yang tersedia.';
  }

  if (!adalahJamOperasional(parsed.jam, parsed.menit)) {
    return 'Jam sewa harus dalam batas operasional (06.00 s.d. 22.00 WIT). Hubungi Chat CS Merauke jika butuh penjemputan khusus.';
  }

  final hariMulai = tanggalSaja(tanggal);
  final hariIni = tanggalSaja(now);
  final palingAwal = tanggalMulaiPalingAwal(now);
  final maksimal = batasTanggalMulaiMaksimal(now);

  if (hariMulai.isBefore(hariIni)) {
    return 'Tanggal mulai sewa tidak boleh sebelum hari ini.';
  }

  if (hariMulai.isBefore(palingAwal)) {
    return 'Pemesanan untuk hari ini sudah melewati batas jam operasional. Silakan pilih mulai besok.';
  }

  if (hariMulai.isAfter(maksimal)) {
    return 'Tanggal mulai sewa maksimal $maxBookingAdvanceDays hari ke depan.';
  }

  if (!jadwalMulaiMemenuhiLeadTime(
    hariMulai,
    parsed.jam,
    parsed.menit,
    now,
    leadTime: leadTime,
  )) {
    final minPickup = waktuJemputPalingAwal(now, leadTime: leadTime);
    final tutup = tutupOperasional(hariIni);
    if (minPickup.isAfter(tutup)) {
      return 'Pemesanan untuk hari ini sudah melewati batas jam operasional. Silakan pilih mulai besok.';
    }
    return 'Untuk pemesanan hari ini, jam jemput minimal 2 jam dari sekarang (paling cepat pukul ${formatJamWit(minPickup.hour, minPickup.minute)}).';
  }

  return null;
}
