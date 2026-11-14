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
