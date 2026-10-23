/// Kategori keluhan atau tiket bantuan pelanggan
enum TicketCategory {
  reservasi,
  pembayaran,
  kendaraan,
  layananSopir,
  lainnya;

  /// Kunci enum yang sesuai dengan kontrak backend MariaDB Prisma
  String get apiKey {
    switch (this) {
      case TicketCategory.reservasi:
        return 'GENERAL';
      case TicketCategory.pembayaran:
        return 'PAYMENT_CONFIRMATION';
      case TicketCategory.kendaraan:
        return 'VEHICLE_ISSUE';
      case TicketCategory.layananSopir:
        return 'COMPLAINT';
      case TicketCategory.lainnya:
        return 'OTHER';
    }
  }
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

  SupportTicketModel copyWith({
    String? id,
    String? title,
    TicketCategory? category,
    String? description,
    String? status,
    DateTime? createdAt,
    String? attachmentName,
  }) {
    return SupportTicketModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      attachmentName: attachmentName ?? this.attachmentName,
    );
  }

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
      SupportTicketModel(
        id: 'TCK-2026-074',
        title: 'Panduan pembayaran via QRIS Dinamis Merauke',
        category: TicketCategory.pembayaran,
        description: 'Verifikasi konfirmasi transaksi pembayaran sewa harian menggunakan QRIS Dinamis berhasil terbit.',
        status: 'Selesai',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
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
  final String? conversationKey;

  const ChatMessageModel({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.isFromUser,
    required this.senderName,
    this.isAI = false,
    this.conversationKey,
  });
}
