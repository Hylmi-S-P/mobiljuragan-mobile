import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/remote/ai_api_service.dart';
import '../data/remote/faq_api_service.dart';
import '../data/remote/ticket_api_service.dart';
import '../data/remote/ticket_event_stream.dart';
import '../models/booking_model.dart';
import '../models/faq_model.dart';
import '../models/support_ticket_model.dart';

/// Controller untuk mengelola tiket bantuan, FAQ, dan percakapan chat bantuan yang terisolasi per sesi
class SupportController extends ChangeNotifier {
  final FaqApiService _faqApiService;
  final TicketApiService _ticketApiService;
  final AiApiService _aiApiService;

  /// Pendengar peristiwa tiket. Satu sambungan per tiket yang sedang dibuka.
  final Map<String, TicketEventStream> _aliranPeristiwa = {};
  final List<SupportTicketModel> _tickets = [];

  /// Peta percakapan terisolasi per sesi (booking, tiket keluhan, atau bantuan umum)
  final Map<String, List<ChatMessageModel>> _conversations = {};

  /// Peta status eskalasi percakapan ke admin manusia per sesi
  final Map<String, bool> _handoffStatus = {};

  /// Daftar FAQ aktif dengan fallback awal untuk ketahanan saat offline
  /* Mulai dari daftar kosong. Sebelumnya diisi FAQ karangan yang ditulis tangan
     dan tampil seolah-olah resmi saat server tidak terjangkau. Kalau data belum
     ada, lebih baik layar mengatakannya daripada menampilkan jawaban yang tidak
     pernah disetujui siapa pun. */
  List<FaqModel> _faqs = const [];
  bool _isLoadingFaqs = false;
  String? _faqError;

  SupportController({
    FaqApiService? faqApiService,
    TicketApiService? ticketApiService,
    AiApiService? aiApiService,
  })  : _faqApiService = faqApiService ?? FaqApiService(),
        _ticketApiService = ticketApiService ?? TicketApiService(),
        _aiApiService = aiApiService ?? AiApiService() {
    _initData();
  }


  /// Mulai mendengarkan peristiwa satu tiket.
  ///
  /// Tanpa ini, balasan staf baru terlihat setelah layar dimuat ulang manual.
  /// Backend sudah mengirim peristiwanya sejak lama; yang tidak ada adalah
  /// pendengarnya.
  ///
  /// [onPesanBaru] dipanggil saat jumlah pesan bertambah, [onStatusBerubah] saat
  /// status tiket berubah. Keduanya menerima data mentah supaya layar yang
  /// memutuskan cara memuat ulang.
  Future<void> dengarkanTiket({
    required String ticketId,
    required void Function() onPesanBaru,
    void Function(String status)? onStatusBerubah,
    void Function(String pesan)? onGalat,
  }) async {
    if (ticketId.isEmpty) return;

    /* Satu tiket hanya boleh punya satu sambungan. Kalau layar dibuka ulang,
       sambungan lama ditutup lebih dulu supaya tidak menumpuk. */
    _aliranPeristiwa[ticketId]?.berhenti();

    final aliran = TicketEventStream();
    _aliranPeristiwa[ticketId] = aliran;

    await aliran.mulai(
      ticketId: ticketId,
      onEvent: (peristiwa) {
        switch (peristiwa.jenis) {
          case 'pesan':
            onPesanBaru();
          case 'status':
            final status = peristiwa.status;
            if (status != null) onStatusBerubah?.call(status);
          case 'handover':
            onPesanBaru();
          default:
            /* `siap` hanya penanda sambungan terbentuk. */
            break;
        }
      },
      onError: onGalat,
    );
  }

  /// Menghentikan pendengar satu tiket.
  void berhentiDengarkanTiket(String ticketId) {
    _aliranPeristiwa.remove(ticketId)?.berhenti();
  }

  /// Menghentikan semua pendengar. Dipanggil saat controller dibuang.
  void berhentiSemuaDengarkan() {
    for (final aliran in _aliranPeristiwa.values) {
      aliran.berhenti();
    }
    _aliranPeristiwa.clear();
  }

  @override
  void dispose() {
    berhentiSemuaDengarkan();
    super.dispose();
  }
  /// Membuat key sesi percakapan unik agar riwayat obrolan tidak bocor antar transaksi/tiket
  static String buildConversationKey({String? bookingId, String? ticketId}) {
    if (bookingId != null && bookingId.isNotEmpty) {
      return 'booking_$bookingId';
    }
    if (ticketId != null && ticketId.isNotEmpty) {
      return 'ticket_$ticketId';
    }
    return 'general';
  }

  void _initData() {
    _tickets.addAll(SupportTicketModel.sampleTickets);

    // Percakapan Bantuan Umum (General Help Desk)
    _conversations['general'] = [
      ChatMessageModel(
        id: 'msg-gen-01',
        message: 'Halo! Saya asisten virtual MobilJuragan Merauke. Ada yang bisa kami bantu seputar sewa mobil hari ini?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        isFromUser: false,
        senderName: 'Customer Service MobilJuragan',
        isAI: true,
        conversationKey: 'general',
      ),
    ];

    // Percakapan Sampel untuk Tiket Keluhan TCK-2026-081
    final sampleTicket = SupportTicketModel.sampleTickets.first;
    final ticketKey = 'ticket_${sampleTicket.id}';
    _conversations[ticketKey] = [
      ChatMessageModel(
        id: 'tck-sys-${sampleTicket.id}',
        message: 'Tiket kendala #${sampleTicket.id} (${sampleTicket.title}) telah terdaftar dengan status Diproses.',
        timestamp: sampleTicket.createdAt,
        isFromUser: false,
        senderName: 'Sistem',
        isAI: false,
        conversationKey: ticketKey,
      ),
      ChatMessageModel(
        id: 'tck-usr-${sampleTicket.id}',
        message: sampleTicket.description,
        timestamp: sampleTicket.createdAt.add(const Duration(minutes: 1)),
        isFromUser: true,
        senderName: 'Anda',
        conversationKey: ticketKey,
      ),
      ChatMessageModel(
        id: 'tck-resp-${sampleTicket.id}',
        message: 'Halo, laporan penyesuaian jadwal penjemputan Bandara Mopah Anda sudah kami teruskan ke tim driver lapangan. Driver kami akan standby di area parkir bandara sesuai waktu kedatangan baru Anda.',
        timestamp: sampleTicket.createdAt.add(const Duration(minutes: 15)),
        isFromUser: false,
        senderName: 'Admin Operasional Merauke',
        isAI: false,
        conversationKey: ticketKey,
      ),
    ];
    _handoffStatus[ticketKey] = true;
  }

  List<SupportTicketModel> get tickets => List.unmodifiable(_tickets);

  /// Daftar FAQ aktif (fallback awal atau tersinkronisasi dari backend)
  List<FaqModel> get faqs => List.unmodifiable(_faqs);

  /// Status pemuatan sinkronisasi FAQ dari backend
  bool get isLoadingFaqs => _isLoadingFaqs;

  /// Pesan error saat sinkronisasi FAQ (jika ada)
  String? get faqError => _faqError;

  /// Kategori FAQ yang diekstraksi secara dinamis dari daftar FAQ aktif, selalu menyertakan opsi 'Semua'
  List<String> get faqCategories {
    final categories = _faqs
        .map((f) => f.category.trim())
        .where((cat) => cat.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['Semua', ...categories];
  }

  /// Mengambil data FAQ terbaru dari backend dengan penanganan offline graceful
  Future<void> fetchFaqs({bool force = false}) async {
    if (_isLoadingFaqs) return;
    _isLoadingFaqs = true;
    _faqError = null;
    notifyListeners();

    try {
      final remoteFaqs = await _faqApiService.fetchFaqs();
      if (remoteFaqs.isNotEmpty) {
        _faqs = remoteFaqs;
      }
    } catch (e) {
      // Offline resilience: tangkap galat jaringan secara aman,
      // pertahankan data fallback yang ada tanpa melempar exception/crash ke UI
      _faqError = e.toString();
    } finally {
      _isLoadingFaqs = false;
      notifyListeners();
    }
  }

  /// Mengambil daftar pesan terisolasi sesuai sesi obrolan
  List<ChatMessageModel> getMessages(String conversationKey) {
    if (!_conversations.containsKey(conversationKey)) {
      // Inisialisasi thread baru jika belum ada
      if (conversationKey.startsWith('booking_')) {
        final bookingId = conversationKey.replaceFirst('booking_', '');
        _conversations[conversationKey] = [
          ChatMessageModel(
            id: 'init-booking-$bookingId',
            message: 'Halo! Ini adalah ruang obrolan koordinasi resmi untuk pesanan #$bookingId. Tim CS dan staf operasional MobilJuragan siap melayani kebutuhan Anda.',
            timestamp: DateTime.now(),
            isFromUser: false,
            senderName: 'Customer Service MobilJuragan',
            isAI: true,
            conversationKey: conversationKey,
          ),
        ];
      } else if (conversationKey.startsWith('ticket_')) {
        final ticketId = conversationKey.replaceFirst('ticket_', '');
        _conversations[conversationKey] = [
          ChatMessageModel(
            id: 'init-ticket-$ticketId',
            message: 'Halo! Ruang percakapan ini dikhususkan untuk penanganan tiket bantuan #$ticketId. Tim kami siap membantu menyelesaikan kendala Anda.',
            timestamp: DateTime.now(),
            isFromUser: false,
            senderName: 'Customer Service MobilJuragan',
            isAI: true,
            conversationKey: conversationKey,
          ),
        ];
      } else {
        _conversations[conversationKey] = [
          ChatMessageModel(
            id: 'init-gen-${DateTime.now().millisecondsSinceEpoch}',
            message: 'Halo! Saya asisten virtual MobilJuragan Merauke. Ada yang bisa kami bantu seputar sewa mobil hari ini?',
            timestamp: DateTime.now(),
            isFromUser: false,
            senderName: 'Customer Service MobilJuragan',
            isAI: true,
            conversationKey: conversationKey,
          ),
        ];
      }
    }
    return List.unmodifiable(_conversations[conversationKey]!);
  }

  /// Backward-compatibility getter untuk percakapan umum
  List<ChatMessageModel> get chatMessages => getMessages('general');

  /// Status apakah percakapan sesi dialihkan ke admin operasional
  bool isAiHandoffToAdminFor(String conversationKey) {
    return _handoffStatus[conversationKey] ?? false;
  }

  /// Memuat riwayat percakapan sebuah tiket dari server.
  ///
  /// Sebelumnya riwayat hanya hidup di memori aplikasi. Menutup layar bantuan atau
  /// memulai ulang aplikasi membuat percakapan hilang, padahal pesannya sudah
  /// tersimpan di server — termasuk jawaban asisten AI dan balasan staf.
  ///
  /// Hasilnya menggantikan isi percakapan lokal, lalu status handoff ikut
  /// disesuaikan supaya tombol "Panggil Staf" tidak muncul lagi pada tiket yang
  /// sudah ditangani staf.
  Future<void> muatRiwayatTiket({required String ticketId}) async {
    final conversationKey = 'ticket_$ticketId';

    try {
      final detail = await _ticketApiService.fetchTicketDetail(ticketId: ticketId);
      final daftarPesan = detail['messages'];
      if (daftarPesan is! List) return;

      final hasil = <ChatMessageModel>[];
      for (final mentah in daftarPesan) {
        if (mentah is! Map) continue;

        final adalahPelanggan = mentah['isCustomer'] == true;
        final adalahAi = mentah['isAi'] == true;
        final pengirim = mentah['sender'];
        final namaPengirim = pengirim is Map
            ? (pengirim['fullName'] as String?)?.trim()
            : null;

        hasil.add(
          ChatMessageModel(
            id: (mentah['id'] as String?) ?? 'srv-${hasil.length}',
            message: (mentah['body'] as String?) ?? '',
            timestamp:
                DateTime.tryParse((mentah['sentAt'] as String?) ?? '') ?? DateTime.now(),
            isFromUser: adalahPelanggan,
            senderName: adalahPelanggan
                ? 'Anda'
                : adalahAi
                    ? 'Asisten AI MobilJuragan'
                    : (namaPengirim?.isNotEmpty == true
                        ? namaPengirim!
                        : 'Customer Service MobilJuragan'),
            isAI: adalahAi,
            conversationKey: conversationKey,
          ),
        );
      }

      _conversations[conversationKey] = hasil;

      // Tiket yang sudah dipegang staf tidak boleh menampilkan tombol "Panggil Staf".
      if ((detail['handledBy'] as String?) == 'HUMAN') {
        _handoffStatus[conversationKey] = true;
      }

      notifyListeners();
    } catch (_) {
      // Gagal memuat tidak boleh menghapus percakapan yang sudah tampil.
    }
  }

  /// Backward-compatibility getter
  bool get isAiHandoffToAdmin => isAiHandoffToAdminFor('general');

  /// Daftar Tanya Jawab (FAQ) umum seputar sewa mobil di Merauke
  static const List<Map<String, String>> faqList = [
    {
      'question': 'Bagaimana prosedur penjemputan di Bandara Mopah Merauke?',
      'answer': 'Tim operasional kami akan menunggu di lobi kedatangan Bandara Mopah dengan papan nama penyewa atau menghubungi via WhatsApp 30 menit sebelum jadwal pesawat mendarat. Serah terima unit dilakukan langsung di area parkir bandara tanpa biaya tambahan antar-jemput.',
    },
    {
      'question': 'Bagaimana mekanisme verifikasi dokumen KTP dan SIM A?',
      'answer': 'Verifikasi dokumen fisik asli (KTP elektronik dan SIM A aktif) dilakukan langsung di kantor operasional MobilJuragan atau saat serah terima unit di titik penjemputan Merauke.',
    },
    {
      'question': 'Berapa tarif jasa pengemudi dan jam kerjanya?',
      'answer': 'Jasa pengemudi lokal Merauke bertarif Rp 150.000 per hari dengan durasi pemakaian normal hingga 12 jam per hari dalam wilayah perkotaan Merauke dan sekitarnya.',
    },
    {
      'question': 'Bagaimana kebijakan bahan bakar (BBM) armada?',
      'answer': 'Mobil diserahterimakan dengan indikator BBM tertentu (umumnya terisi minimal setengah bar). Penyewa diharapkan mengembalikan unit dengan posisi BBM setara saat serah terima awal.',
    },
    {
      'question': 'Metode pembayaran apa saja yang berlaku?',
      'answer': 'Pembayaran dapat diselesaikan langsung di aplikasi menggunakan QRIS Dinamis, Virtual Account / Transfer Bank (BRI / Mandiri), atau Tunai di Tempat (COD) saat serah terima unit di Merauke. Layanan bantuan via Chat CS juga siap mendampingi konfirmasi pembayaran Anda.',
    },
    {
      'question': 'Apakah tersedia bantuan jika terjadi kendala armada di jalan?',
      'answer': 'MobilJuragan siap membantu penanganan kendala armada selama jam operasional (06.00 - 22.00 WIT) untuk wilayah Merauke Kota, Kurik, Tanah Miring, hingga Semangga. Hubungi nomor operasional kami melalui tombol WhatsApp.',
    },
  ];

  /// Membuat tiket kendala baru dan menyiapkan thread percakapan terisolasi
  Future<void> createTicket({
    required String title,
    required TicketCategory category,
    required String description,
    String? attachmentName,
  }) async {
    final tempId = 'TCK-2026-${(82 + _tickets.length).toString().padLeft(3, '0')}';
    final newTicket = SupportTicketModel(
      id: tempId,
      title: title,
      category: category,
      description: description,
      status: 'Menunggu',
      createdAt: DateTime.now(),
      attachmentName: attachmentName,
    );

    _tickets.insert(0, newTicket);

    final ticketKey = 'ticket_${newTicket.id}';
    _handoffStatus[ticketKey] = true;
    final initialList = [
      ChatMessageModel(
        id: 'tck-sys-${newTicket.id}',
        message: 'Laporan Anda telah diterima tim operasional Merauke. Mohon sampaikan rincian tambahan atau tunggu tanggapan staf.',
        timestamp: DateTime.now(),
        isFromUser: false,
        senderName: 'Sistem',
        isAI: false,
        conversationKey: ticketKey,
      ),
      ChatMessageModel(
        id: 'tck-usr-${newTicket.id}',
        message: attachmentName != null ? '$description\n\n[Lampiran Dokumen/Foto: $attachmentName]' : description,
        timestamp: DateTime.now(),
        isFromUser: true,
        senderName: 'Anda',
        conversationKey: ticketKey,
      ),
    ];
    _conversations[ticketKey] = initialList;

    notifyListeners();

    try {
      final res = await _ticketApiService.createTicket(
        title: title,
        description: description,
        category: category.apiKey,
      );
      if (res.isNotEmpty && res.containsKey('id')) {
        final serverId = res['id'].toString();
        final serverTicketNumber = res['ticketNumber']?.toString() ?? tempId;
        final serverTicket = newTicket.copyWith(
          id: serverId,
          title: '$title ($serverTicketNumber)',
        );
        final idx = _tickets.indexWhere((t) => t.id == tempId);
        if (idx != -1) {
          _tickets[idx] = serverTicket;
        }
        _conversations['ticket_$serverId'] = initialList;
        notifyListeners();
      }
    } catch (_) {
      // Offline fallback: data lokal tetap tersimpan di controller
    }
  }

  /// Mengirim satu pesan tiket ke backend lalu menandai pesan lokal bila gagal.
  ///
  /// Dipisah dari [sendUserMessage] supaya pengiriman jaringan tidak menahan
  /// pembaruan antarmuka: pesan sudah tampil lebih dulu, lalu statusnya diperbaiki
  /// setelah server menjawab.
  Future<void> _kirimPesanTiket({
    required String ticketId,
    required String pesan,
    required ChatMessageModel pesanLokal,
  }) async {
    try {
      await _ticketApiService.addMessage(ticketId: ticketId, message: pesan);
    } catch (_) {
      final key = pesanLokal.conversationKey;
      if (key == null) return;

      final daftar = _conversations[key];
      if (daftar == null) return;

      final posisi = daftar.indexWhere((m) => m.id == pesanLokal.id);
      if (posisi == -1) return;

      daftar[posisi] = daftar[posisi].copyWith(isFailed: true);
      notifyListeners();
    }
  }

  /// Mengirim pesan dari pengguna ke sesi obrolan yang sedang aktif
  void sendUserMessage({
    required String text,
    String conversationKey = 'general',
  }) {
    if (text.trim().isEmpty) return;

    final list = _conversations.putIfAbsent(conversationKey, () => []);

    final userMsg = ChatMessageModel(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      message: text.trim(),
      timestamp: DateTime.now(),
      isFromUser: true,
      senderName: 'Anda',
      conversationKey: conversationKey,
    );
    list.add(userMsg);
    notifyListeners();

    // Jika percakapan merupakan tiket kendala, kirim pesan ke backend REST API.
    //
    // Sebelumnya pengiriman dilepas dengan unawaited(), sehingga kegagalan jaringan
    // tidak pernah terlihat: pesan tetap tampil seolah terkirim padahal server tidak
    // menerimanya, dan pelanggan menunggu balasan yang tidak akan pernah datang.
    // Sekarang hasilnya ditunggu, lalu pesan ditandai gagal bila server menolak.
    if (conversationKey.startsWith('ticket_')) {
      final ticketId = conversationKey.replaceFirst('ticket_', '');

      _kirimPesanTiket(ticketId: ticketId, pesan: text.trim(), pesanLokal: userMsg);
    }

    final isHandedOff = isAiHandoffToAdminFor(conversationKey);

    /* Balasan AI diambil dari backend sungguhan.
     *
     * Sebelumnya blok ini berisi `Future.delayed` yang menempelkan kalimat tetap di
     * dalam aplikasi. Pelanggan melihat "jawaban AI" yang tidak pernah berasal dari
     * model dan tidak pernah tersimpan di server, sehingga admin yang mengambil alih
     * tiket tidak melihat percakapan sebelumnya sama sekali.
     *
     * Sekarang permintaan dikirim ke POST /ai/chat beserta id tiketnya, sehingga
     * backend menyimpan pertanyaan dan jawaban ke tiket yang sama. */
    if (!isHandedOff && conversationKey.startsWith('ticket_')) {
      final ticketId = conversationKey.replaceFirst('ticket_', '');
      unawaited(
        _mintaBalasanAi(
          ticketId: ticketId,
          pesan: text.trim(),
          conversationKey: conversationKey,
        ),
      );
    }
  }

  /// Meminta balasan asisten AI dari backend lalu menampilkannya di percakapan.
  ///
  /// Kegagalan jaringan ditampilkan apa adanya, bukan disembunyikan dengan balasan
  /// palsu. Pelanggan perlu tahu kapan pesannya tidak terkirim.
  Future<void> _mintaBalasanAi({
    required String ticketId,
    required String pesan,
    required String conversationKey,
  }) async {
    try {
      final hasil = await _aiApiService.kirimPesan(pesan: pesan, ticketId: ticketId);

      if (hasil.kosong) return;

      final daftar = _conversations.putIfAbsent(conversationKey, () => []);
      daftar.add(
        ChatMessageModel(
          id: 'msg-ai-${DateTime.now().microsecondsSinceEpoch}',
          message: hasil.balasan,
          timestamp: DateTime.now(),
          isFromUser: false,
          senderName: 'Asisten AI MobilJuragan',
          isAI: true,
          conversationKey: conversationKey,
        ),
      );
      notifyListeners();
    } catch (_) {
      final daftar = _conversations[conversationKey];
      if (daftar == null) return;

      daftar.add(
        ChatMessageModel(
          id: 'msg-err-${DateTime.now().microsecondsSinceEpoch}',
          message:
              'Asisten AI sedang tidak bisa dihubungi. Pesan Anda tetap tersimpan; '
              'silakan tekan "Panggil Staf" agar dibantu tim operasional.',
          timestamp: DateTime.now(),
          isFromUser: false,
          senderName: 'Sistem',
          isAI: false,
          conversationKey: conversationKey,
        ),
      );
      notifyListeners();
    }
  }

  /// Menyinkronkan riwayat pesan tiket dari backend REST API
  Future<void> refreshTicketConversation(String ticketId) async {
    await muatRiwayatTiket(ticketId: ticketId);
  }

  /// Mengalihkan percakapan sesi ke staf operasional manusia.
  ///
  /// Sebelumnya fungsi ini hanya mengubah flag di memori aplikasi, sehingga backend
  /// tidak pernah tahu dan tiket tidak pernah masuk antrean admin, padahal pesan
  /// sistem yang tampil berbunyi "berhasil dialihkan". Sekarang server diberi tahu
  /// lebih dulu, dan penanda lokal baru dipasang setelah server membalas berhasil.
  Future<bool> handoffToAdmin({String conversationKey = 'general'}) async {
    if (!conversationKey.startsWith('ticket_')) {
      // Percakapan tanpa tiket belum punya wadah di backend. Penanda lokal tetap
      // dipasang supaya perilaku lamanya tidak hilang.
      _handoffStatus[conversationKey] = true;
      _tambahPesanSistem(
        conversationKey: conversationKey,
        pesan: 'Percakapan dialihkan ke staf operasional.',
      );
      return true;
    }

    final ticketId = conversationKey.replaceFirst('ticket_', '');

    try {
      final berhasil = await _ticketApiService.handover(ticketId: ticketId);

      if (!berhasil) {
        _tambahPesanSistem(
          conversationKey: conversationKey,
          pesan:
              'Gagal mengalihkan ke staf: tiket belum berstatus ditangani staf. '
              'Silakan coba lagi sebentar.',
        );
        return false;
      }

      _handoffStatus[conversationKey] = true;
      _tambahPesanSistem(
        conversationKey: conversationKey,
        pesan:
            'Percakapan berhasil dialihkan ke staf admin operasional MobilJuragan Merauke. '
            'Balasan staf akan muncul di layar ini.',
      );
      return true;
    } catch (_) {
      _tambahPesanSistem(
        conversationKey: conversationKey,
        pesan:
            'Gagal mengalihkan ke staf karena koneksi bermasalah. '
            'Pesan Anda tetap tersimpan; silakan coba lagi.',
      );
      return false;
    }
  }

  /// Menambahkan pesan pemberitahuan dari sistem ke sebuah percakapan.
  void _tambahPesanSistem({required String conversationKey, required String pesan}) {
    final list = _conversations.putIfAbsent(conversationKey, () => []);
    list.add(
      ChatMessageModel(
        id: 'sys-${DateTime.now().microsecondsSinceEpoch}',
        message: pesan,
        timestamp: DateTime.now(),
        isFromUser: false,
        senderName: 'Sistem',
        isAI: false,
        conversationKey: conversationKey,
      ),
    );
    notifyListeners();
  }

  /// Format angka ke representasi rupiah
  String _formatRupiah(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return buffer.toString().split('').reversed.join();
  }

  /// Mengirim pesan bot berisi instruksi tagihan resmi ke thread pesanan terkait
  void sendPaymentInstructionMessage(BookingModel booking) {
    final convKey = 'booking_${booking.id}';
    final invoiceMsgId = 'pay-${booking.id}';

    final list = _conversations.putIfAbsent(convKey, () => []);
    final alreadySent = list.any((m) => m.id == invoiceMsgId);
    if (alreadySent) return;

    final driverDetail = booking.withDriver && booking.assignedDriver != null
        ? '· Staf Pengemudi: ${booking.assignedDriver!.driverName} (Staf Tetap)\n· Kontak WhatsApp Sopir: ${booking.assignedDriver!.phoneNumber}\n'
        : '';

    final invoiceText =
        'Halo! Berikut rincian tagihan resmi untuk pesanan #${booking.id} (${booking.vehicle.name}):\n\n'
        '· Total Biaya: Rp ${_formatRupiah(booking.totalCost)}\n'
        '· Bank Transfer: Bank BRI Merauke\n'
        '· No. Rekening: 0321-01-002847-53-1\n'
        '· Atas Nama: MobilJuragan Merauke\n'
        '$driverDetail\n'
        'Metode pembayaran telah diterbitkan oleh sistem. Silakan transfer sesuai nominal di atas, lalu Anda dapat mengonfirmasi pembayaran di bawah agar armada segera disiapkan.';

    list.add(
      ChatMessageModel(
        id: invoiceMsgId,
        message: invoiceText,
        timestamp: DateTime.now(),
        isFromUser: false,
        senderName: 'Customer Service MobilJuragan',
        isAI: true,
        conversationKey: convKey,
      ),
    );
    notifyListeners();
  }

  /// Mencatat bahwa pelanggan mengaku sudah transfer, tanpa mengubah status apa pun.
  ///
  /// Sebelumnya method ini mengarang pesan "pembayaran berhasil diverifikasi lunas"
  /// dan langsung memajukan status pesanan ke mobil siap digunakan, padahal backend
  /// tidak pernah menerima bukti apa pun. Akibatnya pelanggan bisa melewati
  /// pembayaran hanya dengan menekan satu tombol di ruang chat.
  ///
  /// Sekarang yang dikirim hanya pesan ke thread tiket. Status pembayaran tetap
  /// menunggu admin memverifikasi bukti transfer lewat portal.
  Future<void> confirmPaymentFromChat({
    required BookingModel booking,
  }) async {
    final convKey = 'booking_${booking.id}';
    final list = _conversations.putIfAbsent(convKey, () => []);

    final pesan = ChatMessageModel(
      id: 'usr-pay-${DateTime.now().millisecondsSinceEpoch}',
      message:
          'Saya sudah melakukan transfer pembayaran sebesar Rp ${_formatRupiah(booking.totalCost)} untuk pesanan #${booking.id}. Mohon diperiksa ya.',
      timestamp: DateTime.now(),
      isFromUser: true,
      senderName: 'Anda',
      conversationKey: convKey,
    );
    list.add(pesan);
    notifyListeners();

    /* Pesan diteruskan ke backend supaya staf melihatnya di portal. Kalau gagal,
       pesan tetap tampil di layar tetapi bendera di bawah memberi tahu bahwa
       laporannya belum tersampaikan. */
    try {
      await _ticketApiService.addMessage(
        ticketId: booking.id,
        message: pesan.message,
      );
      _pesanBelumTerkirim = false;
    } catch (_) {
      _pesanBelumTerkirim = true;
    }
    notifyListeners();
  }

  /// Benar kalau laporan pembayaran terakhir gagal terkirim ke server.
  bool get pesanBelumTerkirim => _pesanBelumTerkirim;
  bool _pesanBelumTerkirim = false;

  /// Mengirimkan pesan koordinasi penjemputan E-Ticket resmi ke thread pesanan terkait
  void sendPickupCoordinationMessage(BookingModel booking) {
    final convKey = 'booking_${booking.id}';
    final ticketMsgId = 'ticket-coord-${booking.id}';

    final list = _conversations.putIfAbsent(convKey, () => []);
    final alreadySent = list.any((m) => m.id == ticketMsgId);
    if (alreadySent) return;

    final driverInfo = booking.withDriver && booking.assignedDriver != null
        ? 'Staf pengemudi tetap: ${booking.assignedDriver!.driverName} (HP/WA: ${booking.assignedDriver!.phoneNumber}).'
        : 'Pengambilan armada mandiri di ${booking.pickupLocation}. Tim staf kami siap menyambut serah terima kunci.';

    final paymentStatusText = booking.isCodPayment
        ? 'Metode: Bayar Tunai di Tempat (COD Rp ${_formatRupiah(booking.totalCost)} disiapkan saat serah terima unit).'
        : 'Metode: Non-Tunai / QRIS (LUNAS Terverifikasi Otomatis).';

    final text = 'Halo! E-Ticket resmi untuk reservasi #${booking.id} telah terbit.\n\n'
        'Armada: ${booking.vehicle.name} (${booking.vehicle.plateNumber})\n'
        'Jadwal: ${booking.startDate.day}/${booking.startDate.month}/${booking.startDate.year}, ${booking.startTime} (${booking.durationDays} Hari)\n'
        'Titik Jemput: ${booking.pickupLocation}\n'
        '$paymentStatusText\n'
        '$driverInfo\n\n'
        'Silakan sampaikan catatan titik temu spesifik atau koordinasi langsung penjemputan dengan kami di sini.';

    list.add(
      ChatMessageModel(
        id: ticketMsgId,
        message: text,
        timestamp: DateTime.now(),
        isFromUser: false,
        senderName: 'Customer Service MobilJuragan',
        isAI: true,
        conversationKey: convKey,
      ),
    );
    notifyListeners();
  }
}
