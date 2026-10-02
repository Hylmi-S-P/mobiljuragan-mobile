import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../models/support_ticket_model.dart';

/// Controller untuk mengelola tiket bantuan, FAQ, dan percakapan chat bantuan
class SupportController extends ChangeNotifier {
  final List<SupportTicketModel> _tickets = [];
  final List<ChatMessageModel> _chatMessages = [];
  bool _isAiHandoffToAdmin = false;

  SupportController() {
    _initData();
  }

  void _initData() {
    _tickets.addAll(SupportTicketModel.sampleTickets);

    _chatMessages.addAll([
      ChatMessageModel(
        id: 'msg-01',
        message: 'Halo! Saya asisten virtual MobilJuragan Merauke. Ada yang bisa kami bantu seputar sewa mobil hari ini?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        isFromUser: false,
        senderName: 'Customer Service MobilJuragan',
        isAI: true,
      ),
    ]);
  }

  List<SupportTicketModel> get tickets => List.unmodifiable(_tickets);
  List<ChatMessageModel> get chatMessages => List.unmodifiable(_chatMessages);
  bool get isAiHandoffToAdmin => _isAiHandoffToAdmin;

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

  /// Membuat tiket kendala baru
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
    notifyListeners();
  }

  /// Mengirim pesan dari pengguna ke chat bantuan
  void sendUserMessage(String text) {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessageModel(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      message: text.trim(),
      timestamp: DateTime.now(),
      isFromUser: true,
      senderName: 'Anda',
    );
    _chatMessages.add(userMsg);
    notifyListeners();

    // Simulasi respons otomatis AI atau staf operasional
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!_isAiHandoffToAdmin) {
        final reply = ChatMessageModel(
          id: 'msg-reply-${DateTime.now().millisecondsSinceEpoch}',
          message: 'Pesan Anda telah kami terima. Jika Anda membutuhkan bantuan langsung dari tim lapangan Merauke, silakan tekan tombol "Panggil Admin" di atas.',
          timestamp: DateTime.now(),
          isFromUser: false,
          senderName: 'Asisten AI MobilJuragan',
          isAI: true,
        );
        _chatMessages.add(reply);
      } else {
        final reply = ChatMessageModel(
          id: 'msg-admin-${DateTime.now().millisecondsSinceEpoch}',
          message: 'Halo, saya staf operasional MobilJuragan Merauke. Kami sedang memproses permohonan Anda.',
          timestamp: DateTime.now(),
          isFromUser: false,
          senderName: 'Admin Operasional Merauke',
          isAI: false,
        );
        _chatMessages.add(reply);
      }
      notifyListeners();
    });
  }

  /// Mengalihkan percakapan ke admin operasional manusia
  void handoffToAdmin() {
    _isAiHandoffToAdmin = true;
    final systemNotice = ChatMessageModel(
      id: 'sys-${DateTime.now().millisecondsSinceEpoch}',
      message: 'Percakapan berhasil dialihkan ke staf admin operasional MobilJuragan Merauke.',
      timestamp: DateTime.now(),
      isFromUser: false,
      senderName: 'Sistem',
      isAI: false,
    );
    _chatMessages.add(systemNotice);
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

  /// Mengirim pesan bot berisi instruksi tagihan resmi dan nomor rekening Bank BRI Merauke
  void sendPaymentInstructionMessage(BookingModel booking) {
    final invoiceMsgId = 'pay-${booking.id}';
    final alreadySent = _chatMessages.any((m) => m.id == invoiceMsgId);
    if (alreadySent) return;

    final invoiceText =
        'Halo! Berikut rincian tagihan resmi untuk pesanan #${booking.id} (${booking.vehicle.name}):\n\n'
        '• Total Biaya: Rp ${_formatRupiah(booking.totalCost)}\n'
        '• Bank Transfer: Bank BRI Merauke\n'
        '• No. Rekening: 0321-01-002847-53-1\n'
        '• Atas Nama: MobilJuragan Merauke\n\n'
        'Metode pembayaran telah diterbitkan oleh sistem. Silakan transfer sesuai nominal di atas, lalu Anda dapat mengonfirmasi pembayaran di bawah agar armada segera disiapkan.';

    _chatMessages.add(
      ChatMessageModel(
        id: invoiceMsgId,
        message: invoiceText,
        timestamp: DateTime.now(),
        isFromUser: false,
        senderName: 'Customer Service MobilJuragan',
        isAI: true,
      ),
    );
    notifyListeners();
  }

  /// Konfirmasi pembayaran langsung dari ruang chat CS
  void confirmPaymentFromChat({
    required BookingModel booking,
    required VoidCallback onAdvance,
  }) {
    onAdvance();

    final userConfirmMsg = ChatMessageModel(
      id: 'usr-pay-${DateTime.now().millisecondsSinceEpoch}',
      message: 'Saya sudah melakukan transfer pembayaran sebesar Rp ${_formatRupiah(booking.totalCost)} untuk pesanan #${booking.id}.',
      timestamp: DateTime.now(),
      isFromUser: true,
      senderName: 'Anda',
    );
    _chatMessages.add(userConfirmMsg);
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 700), () {
      final verifiedMsg = ChatMessageModel(
        id: 'bot-paid-${DateTime.now().millisecondsSinceEpoch}',
        message: 'Pembayaran pesanan #${booking.id} sebesar Rp ${_formatRupiah(booking.totalCost)} berhasil diverifikasi lunas oleh sistem dan staf operasional Merauke!\n\nUnit ${booking.vehicle.name} siap diserahterimakan di ${booking.pickupLocation}.',
        timestamp: DateTime.now(),
        isFromUser: false,
        senderName: 'Customer Service MobilJuragan',
        isAI: true,
      );
      _chatMessages.add(verifiedMsg);
      notifyListeners();
    });
  }
}
