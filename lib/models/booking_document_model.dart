/// Status verifikasi berkas persyaratan lepas kunci
enum DocumentStatus {
  pendingUpload,
  pendingVerification,
  verified,
  rejected,
}

/// Model data dokumen persyaratan sewa lepas kunci (Surat pernyataan ttd basah, KTP, SIM A)
class BookingDocumentModel {
  final String id;
  final String bookingId;
  final String? statementLetterUrl;
  final String? ktpUrl;
  final String? simUrl;
  final DocumentStatus status;
  final String? rejectionReason;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BookingDocumentModel({
    required this.id,
    required this.bookingId,
    this.statementLetterUrl,
    this.ktpUrl,
    this.simUrl,
    this.status = DocumentStatus.pendingUpload,
    this.rejectionReason,
    this.verifiedAt,
    this.verifiedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasStatement =>
      statementLetterUrl != null && statementLetterUrl!.trim().isNotEmpty;
  bool get hasKtp => ktpUrl != null && ktpUrl!.trim().isNotEmpty;
  bool get hasSim => simUrl != null && simUrl!.trim().isNotEmpty;
  int get uploadedCount =>
      (hasStatement ? 1 : 0) + (hasKtp ? 1 : 0) + (hasSim ? 1 : 0);

  String get statusLabel {
    switch (status) {
      case DocumentStatus.pendingUpload:
        return 'Menunggu Unggahan';
      case DocumentStatus.pendingVerification:
        return 'Sedang Diverifikasi';
      case DocumentStatus.verified:
        return 'Terverifikasi Resmi';
      case DocumentStatus.rejected:
        return 'Perlu Perbaikan';
    }
  }

  factory BookingDocumentModel.fromJson(Map<String, dynamic> rawJson) {
    final Map<String, dynamic> json =
        (rawJson.containsKey('document') && rawJson['document'] is Map)
            ? Map<String, dynamic>.from(rawJson['document'] as Map)
            : rawJson;

    final parentBookingId = rawJson['bookingId']?.toString();

    DocumentStatus parseStatus(String? val) {
      switch (val) {
        case 'PENDING_VERIFICATION':
          return DocumentStatus.pendingVerification;
        case 'VERIFIED':
          return DocumentStatus.verified;
        case 'REJECTED':
          return DocumentStatus.rejected;
        case 'PENDING_UPLOAD':
        default:
          return DocumentStatus.pendingUpload;
      }
    }

    return BookingDocumentModel(
      id: json['id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? parentBookingId ?? '',
      statementLetterUrl: json['statementLetterUrl']?.toString(),
      ktpUrl: json['ktpUrl']?.toString(),
      simUrl: json['simUrl']?.toString(),
      status: parseStatus(json['status']?.toString()),
      rejectionReason: json['rejectionReason']?.toString(),
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.tryParse(json['verifiedAt'].toString())
          : null,
      verifiedBy: json['verifiedBy']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookingId': bookingId,
        'statementLetterUrl': statementLetterUrl,
        'ktpUrl': ktpUrl,
        'simUrl': simUrl,
        'status': status.name,
        'rejectionReason': rejectionReason,
        'verifiedAt': verifiedAt?.toIso8601String(),
        'verifiedBy': verifiedBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  BookingDocumentModel copyWith({
    String? id,
    String? bookingId,
    String? statementLetterUrl,
    String? ktpUrl,
    String? simUrl,
    DocumentStatus? status,
    String? rejectionReason,
    DateTime? verifiedAt,
    String? verifiedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookingDocumentModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      statementLetterUrl: statementLetterUrl ?? this.statementLetterUrl,
      ktpUrl: ktpUrl ?? this.ktpUrl,
      simUrl: simUrl ?? this.simUrl,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
