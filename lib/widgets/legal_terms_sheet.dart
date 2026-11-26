import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'standard_bottom_sheet.dart';

/// Konteks ketentuan legal yang ditampilkan di dalam modal terpusat.
enum JenisKetentuanLegal {
  akunDanPrivasi,
  sewaUnit,
}

/// Modal terpusat untuk Kebijakan Privasi & Akun serta Syarat & Ketentuan Sewa.
///
/// Seluruh teks legal disimpan di satu berkas ini agar konsisten antara layar
/// Pendaftaran Akun, Opsi Rental, Tinjau Pesanan, dan Profil Pengguna.
class LegalTermsSheet {
  LegalTermsSheet._();

  static Future<void> show(
    BuildContext context, {
    required JenisKetentuanLegal jenis,
  }) {
    final bool isSewa = jenis == JenisKetentuanLegal.sewaUnit;
    final String pembukaan =
        isSewa ? _pembukaanSewaUnit : _pembukaanAkunDanPrivasi;
    final List<_PasalLegal> daftarPasal =
        isSewa ? _pasalSewaUnit : _pasalAkunDanPrivasi;

    return StandardBottomSheet.show<void>(
      context: context,
      title: isSewa
          ? 'Syarat & Ketentuan Sewa'
          : 'Syarat Layanan & Privasi Akun',
      subtitle: 'MobilJuragan · Merauke',
      icon: isSewa ? Icons.description_outlined : Icons.privacy_tip_outlined,
      child: _KontenKetentuanLegal(
        pembukaan: pembukaan,
        daftarPasal: daftarPasal,
      ),
      footer: Builder(
        builder: (footerCtx) => SizedBox(
          width: double.infinity,
          height: (44 * MediaQuery.textScalerOf(footerCtx).scale(1)).clamp(
            44.0,
            88.0,
          ),
          child: ElevatedButton(
            onPressed: () => Navigator.pop(footerCtx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Saya Mengerti',
              style: TextStyle(
                fontSize: AppTypography.sizeBodyLarge,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> showAkunDanPrivasi(BuildContext context) {
    return show(context, jenis: JenisKetentuanLegal.akunDanPrivasi);
  }

  static Future<void> showSewaUnit(BuildContext context) {
    return show(context, jenis: JenisKetentuanLegal.sewaUnit);
  }

  static const String _pembukaanAkunDanPrivasi =
      'Dengan mendaftarkan akun, mengakses, atau menggunakan aplikasi MobilJuragan, Pengguna menyatakan telah membaca, memahami, dan menyetujui untuk terikat secara hukum oleh seluruh ketentuan di bawah ini. Apabila Pengguna tidak menyetujui salah satu ketentuan, Pengguna wajib menghentikan pendaftaran maupun penggunaan layanan.';

  static const String _pembukaanSewaUnit =
      'Syarat & Ketentuan Penyewaan Kendaraan ini merupakan perjanjian yang sah dan mengikat secara hukum antara MobilJuragan (Penyedia Jasa) dan pelanggan yang mengajukan maupun menggunakan jasa penyewaan (Penyewa). Dengan mencentang kotak persetujuan pada halaman Tinjau Pesanan, Penyewa tunduk pada seluruh ketentuan di bawah ini.';

  static const List<_PasalLegal> _pasalAkunDanPrivasi = [
    _PasalLegal(
      judul: 'Pasal 1: Keberlakuan & Kelayakan Pengguna',
      butir: [
        'Layanan aplikasi MobilJuragan diselenggarakan untuk memfasilitasi pemesanan penyewaan kendaraan operasional MobilJuragan di wilayah Merauke, Papua Selatan.',
        'Pengguna wajib memenuhi batas usia dan kecakapan hukum sesuai peraturan perundang-undangan Republik Indonesia untuk mengikatkan diri dalam perjanjian penyewaan kendaraan bermotor.',
        'Setiap Pengguna bertanggung jawab penuh atas keabsahan, kebenaran, dan keakuratan seluruh informasi serta dokumen yang disampaikan melalui aplikasi.',
      ],
    ),
    _PasalLegal(
      judul: 'Pasal 2: Pendaftaran, Kebenaran Identitas, & Keamanan Akun',
      butir: [
        'Pengguna wajib mendaftarkan identitas asli sesuai Kartu Tanda Penduduk Elektronik (e-KTP) aktif menggunakan nomor WhatsApp aktif milik pribadi (+62).',
        'Pengguna dilarang mendaftarkan identitas pihak lain tanpa hak, identitas fiktif, atau data yang dipalsukan. MobilJuragan berhak menolak, membekukan, atau menonaktifkan akun apabila ditemukan ketidaksesuaian atau indikasi penyalahgunaan identitas.',
        'Pengguna wajib menjaga kerahasiaan kata sandi serta kode verifikasi sekali pakai (OTP) yang dikirimkan ke nomor WhatsApp terdaftar, dan dilarang memberikannya kepada pihak mana pun, termasuk pihak yang mengaku sebagai staf MobilJuragan.',
        'Seluruh tindakan, pengajuan pesanan, unggahan dokumen, maupun konfirmasi yang dilakukan melalui akun Pengguna yang telah terautentikasi dianggap sah dilakukan oleh pemilik akun yang bersangkutan.',
        'Apabila Pengguna mengetahui atau mencurigai adanya akses tidak sah terhadap akunnya, Pengguna wajib segera mengganti kata sandi dan melaporkannya kepada tim operasional melalui fitur Pusat Bantuan atau Chat CS di aplikasi.',
      ],
    ),
    _PasalLegal(
      judul: 'Pasal 3: Kategori Data Pribadi yang Dikumpulkan',
      butir: [
        'Data Identitas & Profil Akun: nama lengkap sesuai e-KTP, nomor telepon/WhatsApp, jenis kelamin, serta kata sandi akun yang disimpan secara terenkripsi.',
        'Data Lokasi & Rincian Reservasi: jadwal penyewaan, pilihan mode layanan (Lepas Kunci atau Dengan Sopir), serta titik penjemputan atau pengantaran kendaraan di area Merauke.',
        'Data Verifikasi Dokumen (Khusus Lepas Kunci): foto e-KTP asli yang masih berlaku, foto SIM A aktif atas nama Penyewa, serta foto Surat Pernyataan Penyewa bermeterai yang telah ditandatangani.',
        'Data Pembayaran & Pengembalian Dana (Refund): bukti pembayaran transfer serta data rekening bank tujuan (nama bank, nomor rekening, dan nama pemilik rekening) apabila terjadi pengembalian dana.',
        'Data Layanan Pelanggan: isi laporan, tiket bantuan, lampiran kendala, serta riwayat percakapan pada fitur Chat CS.',
      ],
    ),
    _PasalLegal(
      judul: 'Pasal 4: Tujuan Pemrosesan Data',
      butir: [
        'Mengelola pendaftaran, autentikasi masuk, pengiriman kode OTP WhatsApp, serta pemulihan akses akun.',
        'Memproses pengajuan pemesanan, menetapkan tagihan final, memantau status penyewaan, dan menyampaikan pembaruan pesanan.',
        'Melakukan verifikasi kelayakan Penyewa dan validitas berkas persyaratan sewa Lepas Kunci sebelum penyerahan kendaraan.',
        'Melakukan verifikasi pembayaran manual serta memproses penyaluran pengembalian dana ke rekening yang ditentukan Pengguna.',
        'Menyediakan dukungan pelanggan, menindaklanjuti kendala perjalanan, melakukan pencegahan penipuan/penyalahgunaan aset, serta memenuhi kewajiban hukum yang berlaku.',
      ],
    ),
    _PasalLegal(
      judul: 'Pasal 5: Penyimpanan, Keamanan, & Pembatasan Pengungkapan Data',
      butir: [
        'MobilJuragan menerapkan langkah pengamanan teknis dan operasional yang wajar untuk melindungi data pribadi dan berkas identitas Pengguna dari akses tidak sah, kebocoran, atau penyalahgunaan.',
        'Akses terhadap data dan dokumen verifikasi dibatasi hanya kepada pihak internal operasional MobilJuragan yang berwenang menjalankan verifikasi pesanan, serah terima armada, verifikasi pembayaran, dan penanganan layanan pelanggan.',
        'MobilJuragan tidak memperjualbelikan, menyewakan, atau menukarkan data pribadi maupun dokumen Pengguna kepada pihak ketiga mana pun untuk tujuan komersial di luar layanan MobilJuragan.',
        'MobilJuragan hanya dapat mengungkapkan data atau dokumen Pengguna apabila diwajibkan oleh perintah undang-undang, putusan pengadilan, atau permintaan sah aparat penegak hukum, termasuk dalam rangka pengusutan dugaan tindak pidana, penyalahgunaan kendaraan, atau penggelapan aset.',
      ],
    ),
    _PasalLegal(
      judul: 'Pasal 6: Hak Pemilik Data',
      butir: [
        'Pengguna berhak mengakses informasi akunnya di dalam aplikasi serta memperbarui data akun apabila terdapat perubahan yang sah.',
        'Pengguna dapat mengajukan permintaan koreksi atau penghapusan data pribadi melalui fitur Pusat Bantuan atau Chat CS, dengan tetap memperhatikan kewajiban penyimpanan riwayat transaksi, dokumen penyewaan, dan catatan hukum yang berlaku apabila masih terdapat pesanan aktif, kewajiban tertunggak, atau sengketa yang belum selesai.',
      ],
    ),
    _PasalLegal(
      judul: 'Pasal 7: Perubahan Ketentuan & Saluran Bantuan',
      butir: [
        'MobilJuragan berhak memperbarui Syarat Layanan Akun & Kebijakan Privasi ini sewaktu-waktu menyesuaikan kebutuhan operasional maupun peraturan perundang-undangan. Ketentuan terbaru berlaku efektif sejak ditampilkan di dalam aplikasi.',
        'Pertanyaan atau pengaduan terkait privasi data dapat diajukan melalui fitur Pusat Bantuan dan Chat CS.',
      ],
    ),
  ];

  static const List<_PasalLegal> _pasalSewaUnit = [
    _PasalLegal(
      judul: 'Pasal 1: Ruang Lingkup & Definisi',
      butir: [
        'Perjanjian Sewa mencakup penyewaan kendaraan bermotor milik/kelolaan Penyedia Jasa di wilayah Merauke, Papua Selatan, baik dengan mode layanan Lepas Kunci maupun Dengan Sopir.',
        'Penyewa adalah pemegang akun terdaftar yang namanya tercantum pada pengajuan pesanan dan bertanggung jawab atas kepatuhan terhadap perjanjian ini, termasuk atas tindakan seluruh penumpang yang ikut dalam kendaraan selama masa sewa.',
      ],
    ),
    _PasalLegal(
      judul: 'Pasal 2: Pemesanan, Konfirmasi Biaya Final, & Pembayaran',
      butir: [
        'Pengajuan pesanan yang dikirimkan melalui aplikasi merupakan permohonan reservasi dan baru bersifat mengikat penuh setelah diperiksa dan disetujui oleh admin operasional Penyedia Jasa.',
        'Nominal tarif pada halaman Tinjau Pesanan merupakan estimasi awal. Biaya final (termasuk penyesuaian jam layanan apabila ada maupun potongan promo yang sah) ditetapkan dan dikonfirmasi oleh admin operasional sebelum Penyewa diminta melakukan pembayaran.',
        'Pembayaran dilakukan ke rekening/saluran resmi Penyedia Jasa yang tercantum di aplikasi dengan mengunggah bukti pembayaran untuk diverifikasi secara manual oleh admin operasional.',
        'Penyerahan unit hanya dapat dilaksanakan setelah status pembayaran diverifikasi oleh admin operasional serta seluruh persyaratan mode layanan dinyatakan lengkap dan sah.',
      ],
    ),
    _PasalLegal(
      judul: 'Pasal 3: Ketentuan Khusus Mode Layanan',
      butir: [
        'Mode Sewa Lepas Kunci: Penyewa wajib mengunggah 3 berkas yang jelas dan sesuai aslinya melalui Status Pesanan, yaitu (a) foto e-KTP asli berlaku atas nama Penyewa, (b) foto SIM A aktif sesuai identitas Penyewa, dan (c) foto Surat Pernyataan Penyewa yang diunduh dari template aplikasi, dicetak A4, diisi lengkap, dibubuhi meterai berlaku, serta ditandatangani basah.',
        'Pada mode Lepas Kunci, saat serah terima unit Penyewa wajib hadir sendiri dan menunjukkan e-KTP fisik asli serta SIM A fisik asli untuk pencocokan ulang oleh petugas kantor MobilJuragan Merauke. Kendaraan hanya boleh dikemudikan oleh Penyewa yang telah diverifikasi dan disetujui.',
        'Mode Layanan Dengan Sopir: pengemudi yang bertugas adalah staf tetap Penyedia Jasa yang terikat SOP dan kode etik perusahaan, dengan jam kerja operasional harian 12 jam per hari sesuai jadwal sewa.',
        'Kebutuhan tambahan jam sopir di luar 12 jam per hari wajib dikonfirmasi durasi dan biayanya bersama admin operasional sebelum dilaksanakan. Pada mode ini Penyewa tidak memerlukan unggahan berkas Lepas Kunci, dan koordinasi penjemputan dilakukan melalui Chat CS resmi di aplikasi.',
      ],
    ),
    _PasalLegal(
      judul: 'Pasal 4: Larangan Umum & Kepatuhan Hukum (Berlaku Semua Mode)',
      butir: [
        'Seluruh larangan pada pasal ini berlaku penuh tanpa pengecualian bagi Penyewa maupun seluruh penumpang pada semua mode layanan (baik Lepas Kunci maupun Dengan Sopir).',
        'Bebas Narkotika, Psikotropika, & Alkohol: dilarang keras membawa, menyimpan, mengedarkan, mengonsumsi, ataupun mengemudi di bawah pengaruh narkotika, psikotropika, obat terlarang, zat adiktif ilegal, atau minuman beralkohol di dalam maupun dengan menggunakan kendaraan Penyedia Jasa.',
        'Larangan Tindak Pidana & Barang Ilegal: dilarang keras menggunakan kendaraan untuk tindakan melanggar hukum, kejahatan, penadahan, penyelundupan, atau mengangkut barang ilegal, berbahaya, maupun hasil tindak pidana.',
        'Larangan Pemindahtanganan & Penyalahgunaan Unit: dilarang keras menggadaikan, menjual, menyewakan kembali, memindahtangankan penguasaan, melepas perangkat keamanan, atau mengubah komponen maupun dokumen resmi kendaraan (STNK/pelat nomor).',
        'Larangan Penggunaan Tidak Wajar: dilarang menggunakan kendaraan untuk balapan, uji kecepatan, mengangkut muatan/penumpang melebihi kapasitas aman pabrikan, atau melintasi medan yang merusak kendaraan di luar kewajaran.',
        'Sanksi Penghentian Sepihak & Penegakan Hukum: apabila terdapat bukti atau indikasi kuat pelanggaran terhadap Pasal 4 ini, Penyedia Jasa berhak penuh menghentikan masa sewa seketika secara sepihak, menarik kembali unit kendaraan (atau memerintahkan pengemudi menghentikan perjalanan pada mode Dengan Sopir), menolak pengembalian dana sewa yang telah berjalan, serta melaporkan pelanggaran kepada aparat penegak hukum yang berwenang.',
      ],
    ),
    _PasalLegal(
      judul: 'Pasal 5: Wilayah Operasional, Bahan Bakar, & Serah Terima',
      butir: [
        'Kendaraan hanya diizinkan beroperasi di wilayah Kota Merauke dan area sekitarnya sesuai kesepakatan rute pada reservasi.',
        'Pada saat serah terima maupun pengembalian unit (khususnya Lepas Kunci), kondisi fisik kendaraan, perlengkapan standar, posisi indikator bahan bakar, dan dokumen STNK/kunci diperiksa dan dicatat bersama petugas Penyedia Jasa.',
        'Kendaraan wajib dikembalikan dengan posisi indikator bahan bakar sekurang-kurangnya sama dengan kondisi saat serah terima awal.',
      ],
    ),
    _PasalLegal(
      judul: 'Pasal 6: Tanggung Jawab Kerusakan, Kehilangan, & Pelanggaran',
      butir: [
        'Pada mode Lepas Kunci, selama kendaraan berada dalam penguasaan Penyewa terhitung sejak serah terima hingga pengembalian resmi kepada petugas, Penyewa bertanggung jawab penuh atas keamanan, keutuhan unit, kunci kendaraan, dan STNK.',
        'Penyewa bertanggung jawab atas segala biaya perbaikan kerusakan, kehilangan bagian/perlengkapan kendaraan, maupun kerugian akibat kelalaian Penyewa atau pengemudi tidak sah selama masa penguasaan unit.',
        'Segala denda pelanggaran lalu lintas, tilang elektronik (ETLE), maupun sanksi administratif lalu lintas selama masa penggunaan Lepas Kunci menjadi beban penuh Penyewa.',
        'Apabila terjadi kecelakaan lalu lintas, gangguan berat, atau kehilangan/tindak kejahatan terhadap kendaraan, Penyewa wajib segera menghentikan pengoperasian bila membahayakan keselamatan, menjaga dokumentasi lokasi bila memungkinkan, dan menghubungi admin melalui Chat CS sesegera mungkin.',
      ],
    ),
    _PasalLegal(
      judul: 'Pasal 7: Pembatalan & Pengembalian Dana (Refund)',
      butir: [
        'Pembatalan pesanan yang dilakukan sebelum adanya dana pembayaran masuk tidak dikenakan biaya pembatalan.',
        'Apabila Penyewa membatalkan pesanan setelah pembayaran masuk, pengembalian dana dikenakan potongan tetap sebesar Rp 50.000 untuk keperluan biaya admin bank dan administrasi dari total dana pembayaran yang masuk. Apabila total pembayaran kurang dari atau sama dengan nominal potongan tersebut, tidak ada kelebihan penagihan kepada Penyewa.',
        'Apabila pesanan dibatalkan atau ditolak oleh admin operasional atau sistem Penyedia Jasa setelah pembayaran masuk, dana dikembalikan 100% penuh tanpa potongan.',
        'Apabila bukti transfer sudah diunggah tetapi belum selesai diverifikasi saat pembatalan terjadi, proses pengembalian dana dijalankan setelah dana masuk terkonfirmasi pada mutasi rekening kantor Penyedia Jasa.',
        'Penyewa wajib mengisi data rekening bank tujuan yang valid di dalam aplikasi untuk keperluan penyaluran refund, dan dapat memantau status serta bukti transfer pengembalian dana melalui halaman Status Pesanan.',
      ],
    ),
    _PasalLegal(
      judul: 'Pasal 8: Barang Pribadi, Keadaan Kahar, & Batasan Tanggung Jawab',
      butir: [
        'Penyewa bertanggung jawab memeriksa dan mengamankan seluruh barang pribadi di dalam kendaraan sebelum mengakhiri perjalanan atau mengembalikan armada. Penyedia Jasa tidak bertanggung jawab atas kehilangan atau tertinggalnya barang pribadi milik Penyewa maupun penumpang.',
        'Masing-masing pihak dibebaskan dari tuntutan keterlambatan atau kegagalan pemenuhan kewajiban apabila disebabkan secara langsung oleh Keadaan Kahar (Force Majeure) seperti bencana alam, banjir, huru-hara, kebijakan darurat pemerintah, atau pemutusan akses jalan di luar kendali wajar para pihak.',
      ],
    ),
    _PasalLegal(
      judul: 'Pasal 9: Penyelesaian Perselisihan & Hukum yang Berlaku',
      butir: [
        'Perjanjian ini tunduk pada dan ditafsirkan berdasarkan hukum Negara Kesatuan Republik Indonesia.',
        'Setiap perbedaan pendapat atau perselisihan yang timbul dari pelaksanaan perjanjian ini diselesaikan terlebih dahulu melalui musyawarah untuk mufakat melalui saluran resmi Pusat Bantuan, Tiket Bantuan, dan Chat CS MobilJuragan, atau di kantor operasional MobilJuragan Merauke sebelum menempuh jalur hukum sesuai ketentuan yang berlaku.',
      ],
    ),
  ];
}

class _PasalLegal {
  final String judul;
  final List<String> butir;

  const _PasalLegal({
    required this.judul,
    required this.butir,
  });
}

class _KontenKetentuanLegal extends StatelessWidget {
  final String pembukaan;
  final List<_PasalLegal> daftarPasal;

  const _KontenKetentuanLegal({
    required this.pembukaan,
    required this.daftarPasal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pembukaan,
          style: const TextStyle(
            fontSize: AppTypography.sizeBody,
            height: 1.5,
            color: AppColors.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: AppSpacing.gapLg),
        for (int i = 0; i < daftarPasal.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.gapLg),
          Text(
            daftarPasal[i].judul,
            style: const TextStyle(
              fontSize: AppTypography.sizeBodyLarge,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: AppSpacing.gapSm),
          for (final teks in daftarPasal[i].butir) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(top: 7, right: 8),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryNavy,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      teks,
                      style: const TextStyle(
                        fontSize: AppTypography.sizeBody,
                        height: 1.5,
                        color: AppColors.textSecondary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}
