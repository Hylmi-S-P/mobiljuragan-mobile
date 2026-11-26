import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'standard_bottom_sheet.dart';

/// Konteks ketentuan legal yang ditampilkan di dalam modal terpusat.
enum JenisKetentuanLegal {
  akunDanPrivasi,
  sewaUnit,
  syaratDanKetentuan,
}

/// Modal terpusat untuk Syarat & Ketentuan Pengguna MobilJuragan serta
/// Kebijakan Privasi & Akun.
///
/// Seluruh teks legal disimpan di satu berkas ini agar konsisten antara layar
/// Pendaftaran Akun, Opsi Rental, Tinjau Pesanan, dan Profil Pengguna.
class LegalTermsSheet {
  LegalTermsSheet._();

  static Future<void> show(
    BuildContext context, {
    required JenisKetentuanLegal jenis,
  }) {
    final bool isSyaratKetentuan =
        jenis == JenisKetentuanLegal.syaratDanKetentuan ||
        jenis == JenisKetentuanLegal.sewaUnit;
    final String pembukaan = isSyaratKetentuan
        ? _pembukaanSyaratDanKetentuan
        : _pembukaanAkunDanPrivasi;
    final List<_PasalLegal> daftarPasal = isSyaratKetentuan
        ? _pasalSyaratDanKetentuan
        : _pasalAkunDanPrivasi;

    return StandardBottomSheet.show<void>(
      context: context,
      title: isSyaratKetentuan
          ? 'Syarat & Ketentuan Pengguna'
          : 'Syarat Layanan & Privasi Akun',
      subtitle: 'MobilJuragan · Merauke',
      icon: isSyaratKetentuan
          ? Icons.description_outlined
          : Icons.privacy_tip_outlined,
      child: _KontenKetentuanLegal(
        salamPembuka: isSyaratKetentuan ? _salamSyaratDanKetentuan : null,
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

  static Future<void> showSyaratDanKetentuan(BuildContext context) {
    return show(context, jenis: JenisKetentuanLegal.syaratDanKetentuan);
  }

  static Future<void> showAkunDanPrivasi(BuildContext context) {
    return show(context, jenis: JenisKetentuanLegal.akunDanPrivasi);
  }

  static Future<void> showSewaUnit(BuildContext context) {
    return showSyaratDanKetentuan(context);
  }

  static const String _salamSyaratDanKetentuan =
      'Selamat datang di MobilJuragan!';

  static const String _pembukaanSyaratDanKetentuan =
      'Syarat dan Ketentuan ini mengatur penggunaan platform MobilJuragan, termasuk website, aplikasi, layanan pemesanan kendaraan, serta fitur lain yang tersedia di dalam platform. Dengan mengakses, mendaftar, atau menggunakan layanan MobilJuragan, pengguna dianggap telah membaca, memahami, dan menyetujui seluruh Syarat dan Ketentuan yang berlaku.';

  static const String _pembukaanAkunDanPrivasi =
      'Dengan mendaftarkan akun, mengakses, atau menggunakan aplikasi MobilJuragan, Pengguna menyatakan telah membaca, memahami, dan menyetujui untuk terikat secara hukum oleh seluruh ketentuan di bawah ini. Apabila Pengguna tidak menyetujui salah satu ketentuan, Pengguna wajib menghentikan pendaftaran maupun penggunaan layanan.';

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

  static const List<_PasalLegal> _pasalSyaratDanKetentuan = [
    _PasalLegal(
      judul: '1. Definisi',
      butir: [
        'MobilJuragan adalah platform digital yang menyediakan layanan informasi, pemesanan, pengelolaan, dan penyewaan kendaraan.',
        'Pengguna adalah setiap individu yang mengakses, mendaftar, atau menggunakan layanan MobilJuragan.',
        'Penyewa adalah pengguna yang melakukan pemesanan atau penyewaan kendaraan melalui MobilJuragan.',
        'Pemilik Kendaraan adalah individu atau pihak yang menyediakan kendaraan untuk disewakan melalui platform MobilJuragan.',
        'Pengemudi adalah individu yang bertugas mengemudikan kendaraan dalam layanan yang menggunakan pengemudi.',
        'Platform adalah website, aplikasi, dan sistem digital MobilJuragan.',
      ],
    ),
    _PasalLegal(
      judul: '2. Ketentuan Penggunaan Platform',
      bernomor: true,
      butir: [
        'Pengguna wajib memberikan informasi yang benar, akurat, lengkap, dan terkini saat melakukan pendaftaran maupun transaksi.',
        'Pengguna wajib menjaga kerahasiaan akun, kata sandi, serta informasi akses lainnya.',
        'Pengguna dilarang menggunakan platform untuk kegiatan yang melanggar hukum, melakukan penipuan, atau merugikan pihak lain.',
        'MobilJuragan berhak membatasi, menangguhkan, atau menghentikan akses pengguna apabila ditemukan pelanggaran terhadap Syarat dan Ketentuan ini.',
        'Pengguna bertanggung jawab atas segala aktivitas yang dilakukan melalui akun miliknya.',
      ],
    ),
    _PasalLegal(
      judul: '3. Ketentuan Pemesanan Kendaraan',
      bernomor: true,
      butir: [
        'Pemesanan kendaraan dilakukan melalui fitur pesan yang tersedia pada platform MobilJuragan.',
        'Pengguna wajib memastikan informasi pemesanan telah sesuai, termasuk jenis kendaraan, tanggal penyewaan, durasi, jenis penyewaan dengan pengemudi atau tidak, lokasi penjemputan, dan lokasi pengembalian.',
        'Pemesanan dianggap berhasil setelah mendapatkan konfirmasi dari admin sesuai prosedur pemesanan yang berlaku.',
        'Pengguna wajib memenuhi persyaratan penyewaan yang ditentukan oleh MobilJuragan.',
        'Pemesanan dapat menggunakan layanan kendaraan dengan pengemudi maupun tanpa pengemudi, sesuai ketersediaan layanan.',
      ],
    ),
    _PasalLegal(
      judul: '4. Ketentuan Pembayaran',
      bernomor: true,
      butir: [
        'Pengguna wajib melakukan pembayaran sesuai nominal, metode, dan batas waktu yang ditentukan dalam proses pemesanan.',
        'Harga sewa yang ditampilkan pada platform dapat berbeda berdasarkan jenis kendaraan, durasi sewa, lokasi, layanan tambahan, maupun ketentuan lainnya.',
        'Biaya tambahan, apabila ada, akan diinformasikan kepada pengguna sebelum atau selama proses transaksi sesuai ketentuan layanan.',
        'Pengguna bertanggung jawab memastikan pembayaran dilakukan melalui metode pembayaran yang sah dan tersedia pada platform.',
        'Bukti pembayaran wajib disimpan oleh pengguna apabila diperlukan untuk proses verifikasi atau penyelesaian kendala transaksi.',
        'Pemesanan yang belum memenuhi ketentuan pembayaran dapat dibatalkan atau tidak diproses lebih lanjut.',
      ],
    ),
    _PasalLegal(
      judul: '5. Ketentuan Penggunaan Kendaraan',
      bernomor: true,
      butir: [
        'Kendaraan hanya boleh digunakan untuk keperluan yang sah dan tidak bertentangan dengan hukum yang berlaku.',
        'Pengguna wajib menggunakan kendaraan sesuai peruntukan dan menjaga kendaraan selama masa penyewaan.',
        'Pengguna dilarang menggunakan kendaraan untuk kegiatan ilegal, balapan, mengangkut barang terlarang, membawa muatan berlebih, atau kegiatan yang dapat membahayakan keselamatan.',
        'Pengguna dilarang memindahtangankan, menyewakan kembali, atau memberikan kendaraan kepada pihak lain tanpa persetujuan pihak yang berwenang.',
        'Pengguna wajib mematuhi peraturan lalu lintas yang berlaku.',
        'Pengguna bertanggung jawab atas biaya yang timbul akibat pelanggaran lalu lintas, penggunaan kendaraan yang tidak sesuai ketentuan, atau tindakan yang dilakukan selama masa penyewaan, sesuai dengan ketentuan dan bukti yang berlaku.',
        'Pengguna wajib mengembalikan kendaraan sesuai waktu, lokasi, dan kondisi yang telah disepakati, kecuali terdapat persetujuan perubahan dari pihak terkait.',
      ],
    ),
    _PasalLegal(
      judul: '6. Pemeriksaan dan Kondisi Kendaraan',
      bernomor: true,
      butir: [
        'Pengguna disarankan melakukan pemeriksaan kendaraan sebelum dan setelah masa penyewaan.',
        'Pemeriksaan dapat meliputi kondisi fisik kendaraan, kebersihan, bahan bakar, kelengkapan kendaraan, serta kondisi komponen lainnya.',
        'Pengguna disarankan mendokumentasikan kondisi kendaraan melalui foto atau video saat serah terima.',
        'Kerusakan, kehilangan, atau ketidaksesuaian kondisi kendaraan wajib segera dilaporkan kepada pemilik kendaraan atau pihak MobilJuragan.',
        'Pengguna tidak bertanggung jawab atas kerusakan yang telah ada sebelum kendaraan diserahkan, sepanjang dapat dibuktikan.',
        'Kerusakan yang terjadi selama masa penyewaan akan ditangani berdasarkan penyebab, bukti, kesepakatan, dan ketentuan tanggung jawab yang berlaku.',
      ],
    ),
    _PasalLegal(
      judul: '7. Ketentuan Pembatalan dan Perubahan Pemesanan',
      bernomor: true,
      butir: [
        'Pesanan otomatis batal ketika pengguna membayarkan harga sewa melebihi dari batas waktu pembayaran (1 hari).',
        'Jika membatalkan pesanan yang sudah dikonfirmasi berhasil, maka akan dikembalikan dana sesuai dengan nominal yang dibayarkan melalui mekanisme yang tersedia.',
        'Perubahan jadwal, durasi, kendaraan, maupun lokasi penyewaan bergantung pada ketersediaan dan persetujuan pihak terkait.',
        'Apabila kendaraan tidak dapat disediakan oleh pihak penyedia karena keadaan tertentu, pengguna berhak memperoleh informasi mengenai alternatif layanan atau penyelesaian transaksi.',
        'Ketentuan pengembalian dana, apabila berlaku, akan diproses sesuai kebijakan transaksi dan metode pembayaran yang digunakan.',
      ],
    ),
    _PasalLegal(
      judul: '8. Keterlambatan dan Perpanjangan Sewa',
      bernomor: true,
      butir: [
        'Pengguna wajib mengembalikan kendaraan sesuai waktu yang telah disepakati.',
        'Perpanjangan masa sewa wajib diajukan sebelum masa penyewaan berakhir.',
        'Perpanjangan sewa hanya dapat dilakukan setelah mendapatkan persetujuan pihak terkait.',
        'Keterlambatan pengembalian kendaraan dapat dikenakan biaya tambahan sesuai ketentuan penyewaan yang telah diinformasikan.',
        'Pengguna wajib menginformasikan apabila terjadi kendala yang menyebabkan keterlambatan pengembalian kendaraan.',
      ],
    ),
    _PasalLegal(
      judul: '9. Tanggung Jawab Pengguna',
      paragraf: ['Pengguna bertanggung jawab untuk:'],
      bernomor: true,
      butir: [
        'Memberikan informasi yang benar selama menggunakan platform.',
        'Menjaga kendaraan dan menggunakannya secara wajar.',
        'Mematuhi ketentuan penyewaan dan peraturan lalu lintas.',
        'Menanggung biaya yang timbul akibat tindakan, kelalaian, atau pelanggaran yang menjadi tanggung jawabnya selama masa penyewaan.',
        'Melaporkan kecelakaan, kerusakan, kehilangan, atau kejadian lain yang berkaitan dengan kendaraan sesegera mungkin.',
        'Tidak melakukan tindakan yang merugikan MobilJuragan, pemilik kendaraan, pengemudi, maupun pengguna lainnya.',
      ],
    ),
    _PasalLegal(
      judul: '10. Tanggung Jawab MobilJuragan',
      bernomor: true,
      butir: [
        'MobilJuragan berupaya menyediakan platform yang dapat digunakan secara aman, nyaman, dan sesuai fungsi layanan.',
        'MobilJuragan berupaya menyediakan informasi layanan dan kendaraan yang ditampilkan pada platform berdasarkan data yang tersedia.',
        'MobilJuragan dapat membantu pengguna dalam menangani kendala pemesanan, komunikasi, maupun pengaduan terkait layanan.',
        'MobilJuragan tidak menjamin platform selalu tersedia tanpa gangguan, mengingat adanya pemeliharaan sistem, gangguan teknis, jaringan, maupun keadaan lain di luar kendali.',
        'MobilJuragan akan berupaya menangani pengaduan dan permasalahan transaksi secara wajar serta sesuai ketentuan yang berlaku.',
      ],
    ),
    _PasalLegal(
      judul: '11. Privasi dan Penggunaan Data',
      bernomor: true,
      butir: [
        'MobilJuragan dapat mengumpulkan informasi pengguna yang diperlukan untuk pendaftaran, pemesanan, pembayaran, verifikasi, dan penyediaan layanan.',
        'Informasi pengguna akan digunakan sesuai tujuan layanan, kebijakan privasi, serta ketentuan perlindungan data pribadi yang berlaku.',
        'MobilJuragan berupaya menjaga keamanan informasi pengguna dari akses, penggunaan, atau pengungkapan yang tidak sah.',
        'Pengguna dapat diminta memberikan informasi tambahan apabila diperlukan untuk verifikasi identitas, keamanan transaksi, atau penanganan kendala layanan.',
      ],
    ),
    _PasalLegal(
      judul: '12. Keadaan di Luar Kendali (Force Majeure)',
      paragraf: [
        'MobilJuragan maupun pihak terkait tidak dapat dianggap bertanggung jawab atas keterlambatan atau kegagalan pelaksanaan layanan yang disebabkan oleh keadaan di luar kendali wajar, termasuk bencana alam, kebakaran, gangguan jaringan, gangguan sistem, kebijakan pemerintah, kerusuhan, kecelakaan, atau keadaan lain yang tidak dapat dicegah secara wajar.',
        'Pihak terkait akan berupaya memberikan informasi dan melakukan penanganan yang diperlukan atas dampak keadaan tersebut.',
      ],
    ),
    _PasalLegal(
      judul: '13. Perubahan Syarat dan Ketentuan',
      paragraf: [
        'MobilJuragan berhak memperbarui, mengubah, atau menyesuaikan Syarat dan Ketentuan ini dari waktu ke waktu sesuai kebutuhan layanan maupun ketentuan hukum yang berlaku.',
        'Perubahan akan diinformasikan melalui platform atau media komunikasi yang tersedia. Pengguna diharapkan membaca dan memahami perubahan yang berlaku sebelum melanjutkan penggunaan layanan.',
      ],
    ),
    _PasalLegal(
      judul: '14. Penyelesaian Perselisihan',
      bernomor: true,
      butir: [
        'Apabila terjadi perselisihan terkait penggunaan layanan MobilJuragan, para pihak akan berupaya menyelesaikannya terlebih dahulu melalui musyawarah.',
        'Apabila penyelesaian secara musyawarah tidak tercapai, perselisihan akan diselesaikan melalui mekanisme hukum yang berlaku di Republik Indonesia.',
        'Seluruh penggunaan platform dan transaksi yang dilakukan melalui MobilJuragan tunduk pada hukum yang berlaku di Republik Indonesia.',
      ],
    ),
    _PasalLegal(
      judul: '15. Penutup',
      paragraf: [
        'Dengan menggunakan platform MobilJuragan, pengguna menyatakan telah membaca, memahami, dan menyetujui seluruh Syarat dan Ketentuan yang berlaku.',
        'Terima kasih telah menggunakan MobilJuragan. Kami berkomitmen untuk menghadirkan pengalaman penyewaan kendaraan yang lebih praktis, mudah, dan nyaman.',
      ],
    ),
  ];
}

class _PasalLegal {
  final String judul;
  final List<String> paragraf;
  final List<String> butir;
  final bool bernomor;

  const _PasalLegal({
    required this.judul,
    this.paragraf = const [],
    this.butir = const [],
    this.bernomor = false,
  });
}

class _KontenKetentuanLegal extends StatelessWidget {
  final String? salamPembuka;
  final String pembukaan;
  final List<_PasalLegal> daftarPasal;

  const _KontenKetentuanLegal({
    this.salamPembuka,
    required this.pembukaan,
    required this.daftarPasal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (salamPembuka != null) ...[
          Text(
            salamPembuka!,
            style: const TextStyle(
              fontSize: AppTypography.sizeBodyLarge,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: AppSpacing.gapSm),
        ],
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
          for (final paragraf in daftarPasal[i].paragraf)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                paragraf,
                style: const TextStyle(
                  fontSize: AppTypography.sizeBody,
                  height: 1.5,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          for (int j = 0; j < daftarPasal[i].butir.length; j++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (daftarPasal[i].bernomor)
                    SizedBox(
                      width: 22,
                      child: Text(
                        '${j + 1}.',
                        style: const TextStyle(
                          fontSize: AppTypography.sizeBody,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                          color: AppColors.primaryNavy,
                          fontFamily: 'Inter',
                        ),
                      ),
                    )
                  else
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
                      daftarPasal[i].butir[j],
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
    );
  }
}
