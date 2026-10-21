import 'package:flutter/foundation.dart';

/// Model data Tanya Jawab (FAQ) Pusat Bantuan MobilJuragan
@immutable
class FaqModel {
  final String id;
  final String question;
  final String answer;
  final String category;
  final int orderIndex;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FaqModel({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    this.orderIndex = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory untuk membuat FaqModel dari Map JSON API backend
  factory FaqModel.fromJson(Map<String, dynamic> json) {
    int parsedOrder = 0;
    if (json['orderIndex'] is num) {
      parsedOrder = (json['orderIndex'] as num).toInt();
    } else if (json['orderIndex'] != null) {
      parsedOrder = int.tryParse(json['orderIndex'].toString()) ?? 0;
    }

    bool parsedActive = true;
    if (json['isActive'] is bool) {
      parsedActive = json['isActive'] as bool;
    } else if (json['isActive'] != null) {
      parsedActive = json['isActive'].toString().toLowerCase() == 'true';
    }

    DateTime? parsedCreatedAt;
    if (json['createdAt'] != null) {
      parsedCreatedAt = DateTime.tryParse(json['createdAt'].toString());
    }

    DateTime? parsedUpdatedAt;
    if (json['updatedAt'] != null) {
      parsedUpdatedAt = DateTime.tryParse(json['updatedAt'].toString());
    }

    return FaqModel(
      id: json['id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Umum',
      orderIndex: parsedOrder,
      isActive: parsedActive,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  /// Konversi FaqModel ke representasi JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category,
      'orderIndex': orderIndex,
      'isActive': isActive,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// 6 Fallback FAQ resmi Merauke untuk ketahanan saat offline / server tidak terjangkau
  static List<FaqModel> get fallbackFaqs => const [
    FaqModel(
      id: 'faq-seed-01',
      category: 'Booking & Sewa',
      question: 'Bagaimana prosedur penjemputan di Bandara Mopah Merauke?',
      answer:
          'Tim operasional kami akan menunggu di lobi kedatangan Bandara Mopah dengan papan nama penyewa atau menghubungi via WhatsApp 30 menit sebelum jadwal pesawat mendarat. Serah terima unit dilakukan langsung di area parkir bandara tanpa biaya tambahan antar-jemput.',
      orderIndex: 1,
      isActive: true,
    ),
    FaqModel(
      id: 'faq-seed-02',
      category: 'Booking & Sewa',
      question: 'Bagaimana verifikasi dokumen KTP dan SIM A untuk lepas kunci?',
      answer:
          'Verifikasi dokumen fisik asli (KTP elektronik dan SIM A aktif) dilakukan langsung di kantor operasional MobilJuragan atau saat serah terima unit di titik penjemputan Merauke.',
      orderIndex: 2,
      isActive: true,
    ),
    FaqModel(
      id: 'faq-seed-03',
      category: 'Armada',
      question: 'Bagaimana kebijakan bahan bakar (BBM) armada?',
      answer:
          'Mobil diserahterimakan dengan indikator BBM tertentu (umumnya terisi minimal setengah bar). Penyewa diharapkan mengembalikan unit dengan posisi BBM setara saat serah terima awal.',
      orderIndex: 3,
      isActive: true,
    ),
    FaqModel(
      id: 'faq-seed-04',
      category: 'Booking & Sewa',
      question: 'Berapa tarif jasa pengemudi dan durasi kerjanya?',
      answer:
          'Jasa pengemudi lokal Merauke bertarif Rp 150.000 per hari dengan durasi pemakaian normal hingga 12 jam per hari dalam wilayah perkotaan Merauke dan sekitarnya.',
      orderIndex: 4,
      isActive: true,
    ),
    FaqModel(
      id: 'faq-seed-05',
      category: 'Pembayaran',
      question: 'Metode pembayaran apa saja yang berlaku?',
      answer:
          'Pembayaran dapat diselesaikan langsung di aplikasi menggunakan QRIS Dinamis, Virtual Account / Transfer Bank (BRI / Mandiri), atau Tunai di Tempat (COD) saat serah terima unit di Merauke. Layanan konfirmasi manual melalui Chat CS juga siap membantu jika Anda memerlukan bantuan pembayaran.',
      orderIndex: 5,
      isActive: true,
    ),
    FaqModel(
      id: 'faq-seed-06',
      category: 'Armada',
      question: 'Apakah tersedia bantuan jika terjadi kendala armada di jalan?',
      answer:
          'MobilJuragan siap membantu penanganan kendala armada selama jam operasional (06.00 - 22.00 WIT) untuk wilayah Merauke Kota, Kurik, Tanah Miring, hingga Semangga. Hubungi nomor operasional kami jika membutuhkan bantuan darurat.',
      orderIndex: 6,
      isActive: true,
    ),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FaqModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          question == other.question &&
          answer == other.answer &&
          category == other.category &&
          orderIndex == other.orderIndex &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^
      question.hashCode ^
      answer.hashCode ^
      category.hashCode ^
      orderIndex.hashCode ^
      isActive.hashCode;

  @override
  String toString() =>
      'FaqModel(id: $id, question: $question, category: $category, orderIndex: $orderIndex, isActive: $isActive)';
}
