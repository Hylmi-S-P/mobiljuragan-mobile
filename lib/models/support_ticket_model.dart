/// Kategori keluhan atau tiket bantuan pelanggan
enum TicketCategory {
  reservasi,
  pembayaran,
  kendaraan,
  layananSopir,
  lainnya,
}

/// Entitas tiket bantuan pelanggan
class SupportTicketModel {
  final String id;
  final String title;
  final TicketCategory category;
  final String description;
  final String status; // 'Menunggu', 'Diproses', 'Selesai'
  final DateTime createdAt;
  final String? attachmentName;

  const SupportTicketModel({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.status,
    required this.createdAt,
    this.attachmentName,
  });

  String get categoryLabel {
    switch (category) {
      case TicketCategory.reservasi:
        return 'Jadwal & Reservasi';
      case TicketCategory.pembayaran:
        return 'Pembayaran & Tagihan';
      case TicketCategory.kendaraan:
        return 'Kondisi Unit Armada';
      case TicketCategory.layananSopir:
        return 'Layanan Driver';
      case TicketCategory.lainnya:
        return 'Pertanyaan Umum';
    }
  }

  static List<SupportTicketModel> get sampleTickets {
    return [
      SupportTicketModel(
        id: 'TCK-2026-081',
        title: 'Konfirmasi penjemputan kedatangan Bandara Mopah',
        category: TicketCategory.reservasi,
        description: 'Pesawat saya mengalami penyesuaian waktu, mohon konfirmasi serah terima armada di area parkir bandara.',
        status: 'Diproses',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ];
  }
}

/// Entitas pesan percakapan chat bantuan (AI Handoff & CS Admin)
class ChatMessageModel {
  final String id;
  final String message;
  final DateTime timestamp;
  final bool isFromUser;
  final String senderName;
  final bool isAI;

  const ChatMessageModel({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.isFromUser,
    required this.senderName,
    this.isAI = false,
  });
}
