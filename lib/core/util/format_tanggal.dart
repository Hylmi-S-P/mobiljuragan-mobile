/// Format tanggal dan kode reservasi yang dipakai bersama semua layar.
///
/// Sebelum berkas ini ada, setiap layar menulis nama bulan dan menyusun
/// tanggalnya sendiri, sehingga pesanan yang sama tampil sebagai
/// `18/11 - 20/11/2026`, `18 November 2026`, dan `18 Nov - 20 Nov` di tiga
/// layar berbeda. Semua penyusunan tanggal sekarang lewat berkas ini.
library;

const List<String> namaBulan = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// Nama hari singkat, indeks 0 = Senin supaya cocok dengan `DateTime.weekday - 1`.
const List<String> namaHariSingkat = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

/// Bulan tiga huruf, misalnya `Nov`.
String namaBulanSingkat(int bulan) => namaBulan[bulan - 1].substring(0, 3);

/// Format baku ringkas: `18 Nov 2026`.
String formatTanggalSingkat(DateTime tanggal) =>
    '${tanggal.day} ${namaBulanSingkat(tanggal.month)} ${tanggal.year}';

/// Format baku panjang: `18 November 2026`.
String formatTanggalPanjang(DateTime tanggal) =>
    '${tanggal.day} ${namaBulan[tanggal.month - 1]} ${tanggal.year}';

/// Format dengan nama hari: `Jum, 20 November 2026`.
String formatHariTanggal(DateTime tanggal) =>
    '${namaHariSingkat[tanggal.weekday - 1]}, ${formatTanggalPanjang(tanggal)}';

/// Rentang sewa yang menyusut saat bulan atau tahunnya sama.
///
/// `18 - 20 Nov 2026` untuk bulan yang sama, `28 Nov - 2 Des 2026` untuk bulan
/// berbeda di tahun yang sama, dan bentuk lengkap saat tahunnya berbeda.
String formatRentangSewa(DateTime mulai, DateTime selesai) {
  if (mulai.year == selesai.year && mulai.month == selesai.month) {
    return '${mulai.day} - ${selesai.day} ${namaBulan[selesai.month - 1]} ${selesai.year}';
  }
  if (mulai.year == selesai.year) {
    return '${mulai.day} ${namaBulan[mulai.month - 1]} - '
        '${selesai.day} ${namaBulan[selesai.month - 1]} ${selesai.year}';
  }
  return '${formatTanggalPanjang(mulai)} - ${formatTanggalPanjang(selesai)}';
}

/// Satu-satunya label kode reservasi di seluruh aplikasi.
String labelKodeReservasi(String kode) => 'Kode reservasi: $kode';
