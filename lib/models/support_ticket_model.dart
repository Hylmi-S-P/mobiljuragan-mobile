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
  final String? ticketNumber;
  final String title;
  final TicketCategory category;
  final String description;
  final String status; // 'Menunggu', 'Diproses', 'Selesai'
  final String? handledBy; // 'AI', 'HUMAN'
  final DateTime? handoverAt;
  final DateTime createdAt;
  final String? attachmentName;

  const SupportTicketModel({
    required this.id,
    this.ticketNumber,
    required this.title,
    required this.category,
    required this.description,
    required this.status,
    this.handledBy,
    this.handoverAt,
    required this.createdAt,
    this.attachmentName,
  });

  String get displayTicketNumber => ticketNumber ?? id;

  bool get isHandledByHuman => handledBy?.toUpperCase() == 'HUMAN';

  bool get isResolved => status == 'Selesai';

  bool get isClosed => status == 'Ditutup';

  bool get isFinished => isResolved || isClosed;

  SupportTicketModel copyWith({
    String? id,
    String? ticketNumber,
    String? title,
    TicketCategory? category,
    String? description,
    String? status,
    String? handledBy,
    DateTime? handoverAt,
    DateTime? createdAt,
    String? attachmentName,
  }) {
    return SupportTicketModel(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      status: status ?? this.status,
      handledBy: handledBy ?? this.handledBy,
      handoverAt: handoverAt ?? this.handoverAt,
      createdAt: createdAt ?? this.createdAt,
      attachmentName: attachmentName ?? this.attachmentName,
    );
  }

  static TicketCategory parseCategory(String? raw) {
    if (raw == null) return TicketCategory.lainnya;
    switch (raw.toUpperCase()) {
      case 'GENERAL':
      case 'RESERVASI':
        return TicketCategory.reservasi;
      case 'PAYMENT_CONFIRMATION':
      case 'PEMBAYARAN':
        return TicketCategory.pembayaran;
      case 'VEHICLE_ISSUE':
      case 'KENDARAAN':
        return TicketCategory.kendaraan;
      case 'COMPLAINT':
      case 'LAYANANSOPIR':
      case 'LAYANAN_SOPIR':
        return TicketCategory.layananSopir;
      case 'CANCELLATION':
      case 'OTHER':
      case 'LAINNYA':
      default:
        return TicketCategory.lainnya;
    }
  }

  static String parseStatus(String? raw) {
    if (raw == null) return 'Menunggu';
    switch (raw.toUpperCase()) {
      case 'OPEN':
      case 'MENUNGGU':
        return 'Menunggu';
      case 'IN_PROGRESS':
      case 'WAITING_CUSTOMER':
      case 'DIPROSES':
        return 'Diproses';
      case 'RESOLVED':
      case 'SELESAI':
        return 'Selesai';
      case 'CLOSED':
      case 'DITUTUP':
        return 'Ditutup';
      default:
        return raw;
    }
  }

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: json['id']?.toString() ?? '',
      ticketNumber: json['ticketNumber']?.toString(),
      title: json['title']?.toString() ?? 'Tiket Bantuan',
      category: parseCategory(json['category']?.toString()),
      description: json['description']?.toString() ?? '',
      status: parseStatus(json['status']?.toString()),
      handledBy: json['handledBy']?.toString(),
      handoverAt: json['handoverAt'] != null
          ? DateTime.tryParse(json['handoverAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      attachmentName: json['attachmentName']?.toString(),
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

  static List<SupportTicketModel> get sampleTickets => const [];
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

  /// Menandai pesan yang gagal sampai ke server. Pesan tetap tampil di percakapan
  /// supaya pelanggan tahu apa yang sudah ia tulis, tetapi diberi penanda gagal
  /// agar tidak dikira sudah terkirim.
  final bool isFailed;

  const ChatMessageModel({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.isFromUser,
    required this.senderName,
    this.isAI = false,
    this.conversationKey,
    this.isFailed = false,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json, {String? conversationKey}) {
    final isCustomer = json['isCustomer'] == true || json['authorRole'] == 'CUSTOMER';
    final isAi = json['isAi'] == true;

    final String authorName;
    if (isCustomer) {
      authorName = 'Anda';
    } else if (isAi) {
      authorName = 'Asisten AI MobilJuragan';
    } else {
      authorName = json['sender']?['fullName']?.toString() ??
          json['author']?['fullName']?.toString() ??
          'Admin Operasional Merauke';
    }

    final rawDate = json['sentAt']?.toString() ?? json['createdAt']?.toString();
    final parsedDate = rawDate != null ? (DateTime.tryParse(rawDate) ?? DateTime.now()) : DateTime.now();

    return ChatMessageModel(
      id: json['id']?.toString() ?? 'msg-${DateTime.now().millisecondsSinceEpoch}',
      message: json['body']?.toString() ?? json['message']?.toString() ?? '',
      timestamp: parsedDate,
      isFromUser: isCustomer,
      senderName: authorName,
      isAI: isAi,
      conversationKey: conversationKey,
      isFailed: false,
    );
  }

  ChatMessageModel copyWith({bool? isFailed}) {
    return ChatMessageModel(
      id: id,
      message: message,
      timestamp: timestamp,
      isFromUser: isFromUser,
      senderName: senderName,
      isAI: isAI,
      conversationKey: conversationKey,
      isFailed: isFailed ?? this.isFailed,
    );
  }
}
