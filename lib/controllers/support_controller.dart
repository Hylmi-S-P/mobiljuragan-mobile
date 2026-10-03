import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../models/support_ticket_model.dart';

/// Controller untuk mengelola tiket bantuan, FAQ, dan percakapan chat bantuan yang terisolasi per sesi
class SupportController extends ChangeNotifier {
  final List<SupportTicketModel> _tickets = [];

  /// Peta percakapan terisolasi per sesi (booking, tiket keluhan, atau bantuan umum)
  final Map<String, List<ChatMessageModel>> _conversations = {};

  /// Peta status eskalasi percakapan ke admin manusia per sesi
  final Map<String, bool> _handoffStatus = {};

  SupportController() {
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
      'question': 'Apakah tersedia layanan bantuan darurat di jalan?',
      'answer': 'Ya, MobilJuragan menyediakan layanan darurat 24 jam untuk wilayah Merauke Kota, Kurik, Tanah Miring, hingga Semangga. Hubungi nomor darurat operasional kami melalui tombol WhatsApp.',
    },
  ];

  /// Membuat tiket kendala baru dan menyiapkan thread percakapan terisolasi
  void createTicket({
    required String title,
    required TicketCategory category,
    required String description,
    String? attachmentName,
  }) {
    final newTicket = SupportTicketModel(
      id: 'TCK-2026-${(82 + _tickets.length).toString().padLeft(3, '0')}',
      title: title,
      category: category,
      description: description,
      status: 'Menunggu',
      createdAt: DateTime.now(),
      attachmentName: attachmentName,
    );

    _tickets.insert(0, newTicket);

    final ticketKey = 'ticket_${newTicket.id}';
    final initialList = [
      ChatMessageModel(
        id: 'tck-sys-${newTicket.id}',
        message: 'Tiket bantuan #${newTicket.id} (${newTicket.title}) telah terdaftar dengan status Menunggu. Tim operasional MobilJuragan akan segera merespons kendala Anda.',
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

    final isHandedOff = isAiHandoffToAdminFor(conversationKey);

    // Simulasi respons otomatis AI atau staf operasional untuk sesi tersebut
    Future.delayed(const Duration(milliseconds: 900), () {
      final currentList = _conversations.putIfAbsent(conversationKey, () => []);

      if (!isHandedOff) {
        final reply = ChatMessageModel(
          id: 'msg-reply-${DateTime.now().millisecondsSinceEpoch}',
          message: 'Pesan Anda telah kami terima. Jika Anda membutuhkan bantuan langsung dari tim operasional Merauke, silakan tekan tombol "Panggil Staf" di atas.',
          timestamp: DateTime.now(),
          isFromUser: false,
          senderName: 'Asisten AI MobilJuragan',
          isAI: true,
          conversationKey: conversationKey,
        );
        currentList.add(reply);
      } else {
        final reply = ChatMessageModel(
          id: 'msg-admin-${DateTime.now().millisecondsSinceEpoch}',
          message: 'Halo, saya staf operasional MobilJuragan Merauke. Kami sedang memproses permohonan Anda.',
          timestamp: DateTime.now(),
          isFromUser: false,
          senderName: 'Admin Operasional Merauke',
          isAI: false,
          conversationKey: conversationKey,
        );
        currentList.add(reply);
      }
      notifyListeners();
    });
  }

  /// Mengalihkan percakapan sesi ke staf operasional manusia
  void handoffToAdmin({String conversationKey = 'general'}) {
    _handoffStatus[conversationKey] = true;
    final list = _conversations.putIfAbsent(conversationKey, () => []);

    final systemNotice = ChatMessageModel(
      id: 'sys-${DateTime.now().millisecondsSinceEpoch}',
      message: 'Percakapan berhasil dialihkan ke staf admin operasional MobilJuragan Merauke.',
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
