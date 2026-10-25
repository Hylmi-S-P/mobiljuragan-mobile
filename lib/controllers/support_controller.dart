import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/remote/ai_chat_api_service.dart';
import '../data/remote/faq_api_service.dart';
import '../data/remote/ticket_api_service.dart';
import '../models/booking_model.dart';
import '../models/faq_model.dart';
import '../models/support_ticket_model.dart';

/// Controller untuk mengelola tiket bantuan, FAQ, dan percakapan chat bantuan yang terisolasi per sesi
class SupportController extends ChangeNotifier {
  final FaqApiService _faqApiService;
  final TicketApiService _ticketApiService;
  final AiChatApiService _aiChatApiService;
  final List<SupportTicketModel> _tickets = [];

  /// Peta percakapan terisolasi per sesi (booking, tiket keluhan, atau bantuan umum)
  final Map<String, List<ChatMessageModel>> _conversations = {};

  /// Peta status eskalasi percakapan ke admin manusia per sesi
  final Map<String, bool> _handoffStatus = {};

  /// Peta status indikator proses berpikir / pengetikan asisten AI per sesi
  final Map<String, bool> _isAiThinking = {};

  /// Daftar FAQ aktif dengan fallback awal untuk ketahanan saat offline
  List<FaqModel> _faqs = FaqModel.fallbackFaqs;
  bool _isLoadingFaqs = false;
  String? _faqError;

  /// Status pemuatan sinkronisasi tiket dari backend
  bool _isLoadingTickets = false;
  String? _ticketError;

  /// ID tiket sesi AI di backend (jika percakapan umum terhubung ke sesi)
  String? _aiSessionTicketId;

  SupportController({
    FaqApiService? faqApiService,
    TicketApiService? ticketApiService,
    AiChatApiService? aiChatApiService,
  })  : _faqApiService = faqApiService ?? FaqApiService(),
        _ticketApiService = ticketApiService ?? TicketApiService(),
        _aiChatApiService = aiChatApiService ?? AiChatApiService() {
    _initData();
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
        senderName: 'Asisten AI MobilJuragan',
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

  /// Status pemuatan sinkronisasi tiket dari backend
  bool get isLoadingTickets => _isLoadingTickets;

  /// Pesan error saat sinkronisasi tiket (jika ada)
  String? get ticketError => _ticketError;

  /// ID tiket sesi asisten AI di backend
  String? get aiSessionTicketId => _aiSessionTicketId;

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

  /// Mengambil daftar tiket milik pelanggan dari backend dengan penanganan offline graceful
  Future<void> fetchTickets({bool force = false}) async {
    if (_isLoadingTickets && !force) return;
    _isLoadingTickets = true;
    _ticketError = null;
    notifyListeners();

    try {
      final rawList = await _ticketApiService.fetchCustomerTickets();
      final remoteTickets = <SupportTicketModel>[];
      for (final item in rawList) {
        if (item is Map) {
          final ticket = SupportTicketModel.fromJson(Map<String, dynamic>.from(item));
          remoteTickets.add(ticket);

          // Simpan riwayat pesan tiket jika disertakan oleh respons backend
          final ticketKey = 'ticket_${ticket.id}';
          if (item.containsKey('messages') && item['messages'] is List) {
            final rawMessages = item['messages'] as List;
            if (rawMessages.isNotEmpty) {
              final parsed = rawMessages
                  .whereType<Map>()
                  .map((m) => ChatMessageModel.fromJson(
                        Map<String, dynamic>.from(m),
                        conversationKey: ticketKey,
                      ))
                  .toList();
              _conversations[ticketKey] = parsed;
            }
          }

          // Sinkronkan status eskalasi bila tiket ditangani manusia
          if (ticket.isHandledByHuman) {
            _handoffStatus[ticketKey] = true;
          }
        }
      }

      _tickets.clear();
      _tickets.addAll(remoteTickets);
    } catch (e) {
      _ticketError = e.toString();
    } finally {
      _isLoadingTickets = false;
      notifyListeners();
    }
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
            senderName: 'Asisten AI MobilJuragan',
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

  /// Backward-compatibility getter
  bool get isAiHandoffToAdmin => isAiHandoffToAdminFor('general');

  /// Status apakah asisten AI sedang memproses/mengetik jawaban untuk sesi obrolan
  bool isAiThinkingFor(String conversationKey) {
    return _isAiThinking[conversationKey] ?? false;
  }

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
  Future<SupportTicketModel> createTicket({
    required String title,
    required TicketCategory category,
    required String description,
    String? attachmentName,
  }) async {
    final tempId = 'TCK-2026-${(82 + _tickets.length).toString().padLeft(3, '0')}';
    SupportTicketModel createdTicket = SupportTicketModel(
      id: tempId,
      ticketNumber: tempId,
      title: title,
      category: category,
      description: description,
      status: 'Menunggu',
      handledBy: 'HUMAN',
      createdAt: DateTime.now(),
      attachmentName: attachmentName,
    );

    try {
      final res = await _ticketApiService.createTicket(
        title: title,
        description: description,
        category: category.apiKey,
      );
      if (res.isNotEmpty && res.containsKey('id')) {
        final serverTicketNumber = res['ticketNumber']?.toString();
        final effectiveTitle = (serverTicketNumber != null && !title.contains(serverTicketNumber))
            ? '$title ($serverTicketNumber)'
            : title;
        createdTicket = SupportTicketModel.fromJson(res).copyWith(
          title: effectiveTitle,
          attachmentName: attachmentName,
        );
      }
    } catch (_) {
      // Offline fallback: data lokal tetap tersimpan di controller
    }

    final existingIdx = _tickets.indexWhere((t) => t.id == createdTicket.id || t.id == tempId);
    if (existingIdx != -1) {
      _tickets[existingIdx] = createdTicket;
    } else {
      _tickets.insert(0, createdTicket);
    }

    final ticketKey = 'ticket_${createdTicket.id}';
    _handoffStatus[ticketKey] = true;
    final initialList = [
      ChatMessageModel(
        id: 'tck-sys-${createdTicket.id}',
        message: 'Laporan Anda telah diterima tim operasional Merauke. Mohon sampaikan rincian tambahan atau tunggu tanggapan staf.',
        timestamp: createdTicket.createdAt,
        isFromUser: false,
        senderName: 'Sistem',
        isAI: false,
        conversationKey: ticketKey,
      ),
      ChatMessageModel(
        id: 'tck-usr-${createdTicket.id}',
        message: attachmentName != null ? '$description\n\n[Lampiran Dokumen/Foto: $attachmentName]' : description,
        timestamp: createdTicket.createdAt,
        isFromUser: true,
        senderName: 'Anda',
        conversationKey: ticketKey,
      ),
    ];
    _conversations[ticketKey] = initialList;

    notifyListeners();
    return createdTicket;
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

    // Jika percakapan merupakan tiket kendala, kirim pesan ke backend REST API
    if (conversationKey.startsWith('ticket_')) {
      final ticketId = conversationKey.replaceFirst('ticket_', '');
      _kirimPesanTiket(ticketId: ticketId, pesan: text.trim(), pesanLokal: userMsg);
      return;
    }

    final isHandedOff = isAiHandoffToAdminFor(conversationKey);

    if (!isHandedOff) {
      _handleAiChatResponse(text.trim(), conversationKey);
    }
  }

  /// Memastikan sesi tiket AI aktif di backend untuk percakapan umum
  Future<void> _ensureAiSession() async {
    if (_aiSessionTicketId != null) return;
    try {
      final res = await _ticketApiService.createAiSession(
        title: 'Percakapan Asisten AI Mobile',
        category: 'GENERAL',
      );
      if (res.isNotEmpty && res.containsKey('id')) {
        _aiSessionTicketId = res['id'].toString();
      }
    } catch (_) {}
  }

  Future<void> _handleAiChatResponse(String text, String conversationKey) async {
    if (conversationKey == 'general') {
      _ensureAiSession();
    }

    final historyList = _conversations[conversationKey] ?? [];
    final history = historyList
        .where((m) => m.senderName != 'Sistem')
        .map((m) => {
              'role': m.isFromUser ? 'user' : 'assistant',
              'content': m.message,
            })
        .toList();

    final trimmedHistory = history.length > 6
        ? history.sublist(history.length - 6)
        : history;

    _isAiThinking[conversationKey] = true;
    notifyListeners();

    try {
      final aiReply = await _aiChatApiService.sendChat(
        message: text,
        history: trimmedHistory,
      );

      final currentList = _conversations.putIfAbsent(conversationKey, () => []);
      final replyMessage = aiReply != null && aiReply.isNotEmpty
          ? aiReply
          : 'Pesan Anda telah kami terima. Jika Anda membutuhkan bantuan langsung dari tim operasional Merauke, silakan tekan tombol "Panggil Staf" di atas.';

      currentList.add(
        ChatMessageModel(
          id: 'msg-reply-${DateTime.now().millisecondsSinceEpoch}',
          message: replyMessage,
          timestamp: DateTime.now(),
          isFromUser: false,
          senderName: 'Asisten AI MobilJuragan',
          isAI: true,
          conversationKey: conversationKey,
        ),
      );
    } catch (_) {
      final currentList = _conversations.putIfAbsent(conversationKey, () => []);
      currentList.add(
        ChatMessageModel(
          id: 'msg-reply-${DateTime.now().millisecondsSinceEpoch}',
          message: 'Halo! Asisten AI kami sedang melakukan sinkronisasi data operasional. Jika membutuhkan bantuan cepat, silakan tekan tombol "Panggil Staf" di atas.',
          timestamp: DateTime.now(),
          isFromUser: false,
          senderName: 'Asisten AI MobilJuragan',
          isAI: true,
          conversationKey: conversationKey,
        ),
      );
    } finally {
      _isAiThinking[conversationKey] = false;
      notifyListeners();
    }
  }

  /// Menyinkronkan riwayat pesan tiket dari backend REST API
  Future<void> refreshTicketConversation(String ticketId) async {
    try {
      final detail = await _ticketApiService.fetchTicketDetail(ticketId);
      if (detail != null) {
        final ticketKey = 'ticket_$ticketId';

        // Sinkronkan status penanganan jika staf manusia sudah mengambil alih
        final handledBy = detail['handledBy']?.toString().toUpperCase();
        if (handledBy == 'HUMAN') {
          _handoffStatus[ticketKey] = true;
        }

        // Perbarui data tiket di daftar _tickets jika status berubah
        final statusRaw = detail['status']?.toString();
        if (statusRaw != null) {
          final parsedStatus = SupportTicketModel.parseStatus(statusRaw);
          final idx = _tickets.indexWhere((t) => t.id == ticketId);
          if (idx != -1) {
            _tickets[idx] = _tickets[idx].copyWith(
              status: parsedStatus,
              handledBy: handledBy,
            );
          } else {
            _tickets.insert(0, SupportTicketModel.fromJson(detail));
          }
          notifyListeners();
        }

        if (detail.containsKey('messages')) {
          final rawMessages = detail['messages'] as List?;
          if (rawMessages != null) {
            final serverList = <ChatMessageModel>[];
            for (final m in rawMessages) {
              if (m is Map) {
                serverList.add(
                  ChatMessageModel.fromJson(
                    Map<String, dynamic>.from(m),
                    conversationKey: ticketKey,
                  ),
                );
              }
            }

            // Pertahankan pesan lokal sistem atau pesan yang masih gagal terkirim
            final currentList = _conversations[ticketKey] ?? [];
            final localFailedOrSystem = currentList.where((m) =>
                m.isFailed ||
                (m.senderName == 'Sistem' && !serverList.any((s) => s.message == m.message)));

            final merged = <ChatMessageModel>[
              ...serverList,
              ...localFailedOrSystem,
            ];
            merged.sort((a, b) => a.timestamp.compareTo(b.timestamp));

            _conversations[ticketKey] = merged;
            notifyListeners();
          }
        }
      }
    } catch (_) {}
  }

  /// Menutup tiket bantuan oleh pelanggan
  Future<bool> closeTicket(String ticketId) async {
    final ticketKey = 'ticket_$ticketId';

    // Perbarui status lokal seketika
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx != -1) {
      _tickets[idx] = _tickets[idx].copyWith(status: 'Ditutup');
    }

    // Tambahkan pesan konfirmasi penutupan sistem di percakapan
    final currentList = _conversations.putIfAbsent(ticketKey, () => []);
    final closeMsg = ChatMessageModel(
      id: 'sys-closed-${DateTime.now().millisecondsSinceEpoch}',
      message:
          'Tiket bantuan ini telah ditutup oleh pelanggan. Riwayat percakapan tersimpan sebagai arsip.',
      timestamp: DateTime.now(),
      isFromUser: false,
      senderName: 'Sistem',
      isAI: false,
      conversationKey: ticketKey,
    );
    currentList.add(closeMsg);
    notifyListeners();

    try {
      final res = await _ticketApiService.closeTicket(ticketId);
      if (res.isNotEmpty && res.containsKey('status')) {
        final serverStatus = SupportTicketModel.parseStatus(res['status']?.toString());
        final updatedIdx = _tickets.indexWhere((t) => t.id == ticketId);
        if (updatedIdx != -1) {
          _tickets[updatedIdx] = _tickets[updatedIdx].copyWith(status: serverStatus);
          notifyListeners();
        }
      }
      return true;
    } catch (_) {
      // Offline fallback: status lokal tetap 'Ditutup'
      return true;
    }
  }

  /// Mengalihkan percakapan sesi ke staf operasional manusia
  void handoffToAdmin({String conversationKey = 'general'}) {
    _handoffStatus[conversationKey] = true;
    final list = _conversations.putIfAbsent(conversationKey, () => []);

    final systemNotice = ChatMessageModel(
      id: 'sys-${DateTime.now().millisecondsSinceEpoch}',
      message: 'Percakapan dialihkan ke staf operasional MobilJuragan Merauke. Staf kami akan segera menanggapi pesan Anda.',
      timestamp: DateTime.now(),
      isFromUser: false,
      senderName: 'Sistem',
      isAI: false,
      conversationKey: conversationKey,
    );
    list.add(systemNotice);
    notifyListeners();

    if (conversationKey.startsWith('ticket_')) {
      final ticketId = conversationKey.replaceFirst('ticket_', '');
      _ticketApiService.handoverTicket(ticketId).catchError((_) => false);
    } else if (conversationKey == 'general') {
      if (_aiSessionTicketId != null) {
        _ticketApiService.handoverTicket(_aiSessionTicketId!).catchError((_) => false);
      } else {
        _ticketApiService.createAiSession(
          title: 'Permintaan Bantuan Staf Merauke',
          category: 'GENERAL',
        ).then((session) {
          if (session.isNotEmpty && session.containsKey('id')) {
            _aiSessionTicketId = session['id'].toString();
            return _ticketApiService.handoverTicket(_aiSessionTicketId!);
          }
          return false;
        }).catchError((_) => false);
      }
    }
  }

  /// Mengembalikan penanganan sesi percakapan ke asisten AI MobilJuragan
  void returnToAi({String conversationKey = 'general'}) {
    _handoffStatus[conversationKey] = false;
    final list = _conversations.putIfAbsent(conversationKey, () => []);

    final systemNotice = ChatMessageModel(
      id: 'sys-${DateTime.now().millisecondsSinceEpoch}',
      message: 'Percakapan dikembalikan ke Asisten AI MobilJuragan. Anda dapat melanjutkan konsultasi otomatis.',
      timestamp: DateTime.now(),
      isFromUser: false,
      senderName: 'Sistem',
      isAI: false,
      conversationKey: conversationKey,
    );
    list.add(systemNotice);
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
        ? '• Staf Pengemudi: ${booking.assignedDriver!.driverName} (Staf Tetap)\n• Kontak WhatsApp Sopir: ${booking.assignedDriver!.phoneNumber}\n'
        : '';

    final invoiceText =
        'Halo! Berikut rincian tagihan resmi untuk pesanan #${booking.id} (${booking.vehicle.name}):\n\n'
        '• Total Biaya: Rp ${_formatRupiah(booking.totalCost)}\n'
        '• Bank Transfer: Bank BRI Merauke\n'
        '• No. Rekening: 0321-01-002847-53-1\n'
        '• Atas Nama: MobilJuragan Merauke\n'
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

  /// Konfirmasi pembayaran langsung dari ruang chat CS untuk pesanan terkait
  void confirmPaymentFromChat({
    required BookingModel booking,
    required VoidCallback onAdvance,
  }) {
    onAdvance();

    final convKey = 'booking_${booking.id}';
    final list = _conversations.putIfAbsent(convKey, () => []);

    final userConfirmMsg = ChatMessageModel(
      id: 'usr-pay-${DateTime.now().millisecondsSinceEpoch}',
      message: 'Saya sudah melakukan transfer pembayaran sebesar Rp ${_formatRupiah(booking.totalCost)} untuk pesanan #${booking.id}.',
      timestamp: DateTime.now(),
      isFromUser: true,
      senderName: 'Anda',
      conversationKey: convKey,
    );
    list.add(userConfirmMsg);
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 700), () {
      final currentList = _conversations.putIfAbsent(convKey, () => []);

      final driverReadyText = booking.withDriver && booking.assignedDriver != null
          ? '\n\nStaf pengemudi kami, ${booking.assignedDriver!.driverName} (WhatsApp: ${booking.assignedDriver!.phoneNumber}), siap menjemput Anda di ${booking.pickupLocation}. Sopir akan menghubungi nomor Anda sebelum waktu penjemputan.'
          : '\n\nUnit ${booking.vehicle.name} siap diserahterimakan di ${booking.pickupLocation}.';

      final verifiedMsg = ChatMessageModel(
        id: 'bot-paid-${DateTime.now().millisecondsSinceEpoch}',
        message: 'Pembayaran pesanan #${booking.id} sebesar Rp ${_formatRupiah(booking.totalCost)} berhasil diverifikasi lunas oleh sistem dan staf operasional Merauke!$driverReadyText',
        timestamp: DateTime.now(),
        isFromUser: false,
        senderName: 'Customer Service MobilJuragan',
        isAI: true,
        conversationKey: convKey,
      );
      currentList.add(verifiedMsg);
      notifyListeners();
    });
  }

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
