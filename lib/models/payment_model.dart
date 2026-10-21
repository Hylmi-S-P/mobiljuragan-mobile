import 'package:flutter/foundation.dart';

/// Metode pembayaran yang didukung ekosistem MobilJuragan
enum PaymentMethod {
  qris,
  bankTransfer,
  cash;

  static PaymentMethod fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'QRIS':
        return PaymentMethod.qris;
      case 'BANK_TRANSFER':
      case 'BANKTRANSFER':
      case 'TRANSFER':
        return PaymentMethod.bankTransfer;
      case 'CASH':
      case 'COD':
        return PaymentMethod.cash;
      default:
        return PaymentMethod.qris;
    }
  }

  String toBackendString() {
    switch (this) {
      case PaymentMethod.qris:
        return 'QRIS';
      case PaymentMethod.bankTransfer:
        return 'BANK_TRANSFER';
      case PaymentMethod.cash:
        return 'CASH';
    }
  }

  String get label {
    switch (this) {
      case PaymentMethod.qris:
        return 'QRIS Dinamis';
      case PaymentMethod.bankTransfer:
        return 'Transfer Bank';
      case PaymentMethod.cash:
        return 'Bayar Tunai di Tempat (COD)';
    }
  }
}

/// Status siklus hidup pembayaran
enum PaymentStatus {
  unpaid,
  pendingVerification,
  paid,
  failed,
  refunded;

  static PaymentStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'UNPAID':
        return PaymentStatus.unpaid;
      case 'PENDING_VERIFICATION':
      case 'PENDINGVERIFICATION':
        return PaymentStatus.pendingVerification;
      case 'PAID':
        return PaymentStatus.paid;
      case 'FAILED':
        return PaymentStatus.failed;
      case 'REFUNDED':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.unpaid;
    }
  }

  String toBackendString() {
    switch (this) {
      case PaymentStatus.unpaid:
        return 'UNPAID';
      case PaymentStatus.pendingVerification:
        return 'PENDING_VERIFICATION';
      case PaymentStatus.paid:
        return 'PAID';
      case PaymentStatus.failed:
        return 'FAILED';
      case PaymentStatus.refunded:
        return 'REFUNDED';
    }
  }

  String get label {
    switch (this) {
      case PaymentStatus.unpaid:
        return 'Menunggu Pembayaran';
      case PaymentStatus.pendingVerification:
        return 'Menunggu Verifikasi Admin';
      case PaymentStatus.paid:
        return 'Lunas (Terverifikasi)';
      case PaymentStatus.failed:
        return 'Pembayaran Ditolak';
      case PaymentStatus.refunded:
        return 'Dana Dikembalikan';
    }
  }
}

/// Model data tagihan dan verifikasi pembayaran MobilJuragan
@immutable
class PaymentModel {
  final String id;
  final String bookingId;
  final int baseAmount;
  final int uniqueCode;
  final int totalAmount;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? qrisPayload;
  final String? proofImageUrl;
  final String? bankName;
  final String? senderAccount;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final String? notes;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PaymentModel({
    required this.id,
    required this.bookingId,
    required this.baseAmount,
    this.uniqueCode = 0,
    required this.totalAmount,
    required this.method,
    required this.status,
    this.qrisPayload,
    this.proofImageUrl,
    this.bankName,
    this.senderAccount,
    this.verifiedAt,
    this.verifiedBy,
    this.notes,
    this.expiresAt,
    this.createdAt,
    this.updatedAt,
  });

  /// Status apakah pembayaran sudah lunas tervalidasi
  bool get isPaid => status == PaymentStatus.paid;

  /// Status apakah bukti transfer sedang dalam antrean verifikasi staf
  bool get isPendingVerification => status == PaymentStatus.pendingVerification;

  /// Status apakah tagihan sudah melewati waktu kedaluwarsa
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Sisa durasi pembayaran hingga kedaluwarsa
  Duration get remainingDuration {
    if (expiresAt == null) return Duration.zero;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Factory untuk memetakan JSON API backend ke PaymentModel
  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val, [int fallback = 0]) {
      if (val is num) return val.toInt();
      if (val != null) return num.tryParse(val.toString())?.toInt() ?? fallback;
      return fallback;
    }

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      return DateTime.tryParse(val.toString());
    }

    final base = parseInt(json['baseAmount']);
    final code = parseInt(json['uniqueCode']);
    final total = parseInt(json['totalAmount'], base + code);

    return PaymentModel(
      id: json['id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      baseAmount: base,
      uniqueCode: code,
      totalAmount: total,
      method: PaymentMethod.fromString(json['method']?.toString()),
      status: PaymentStatus.fromString(json['status']?.toString()),
      qrisPayload: json['qrisPayload']?.toString(),
      proofImageUrl: json['proofImageUrl']?.toString(),
      bankName: json['bankName']?.toString(),
      senderAccount: json['senderAccount']?.toString(),
      verifiedAt: parseDate(json['verifiedAt']),
      verifiedBy: json['verifiedBy']?.toString(),
      notes: json['notes']?.toString(),
      expiresAt: parseDate(json['expiresAt']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  /// Konversi PaymentModel ke representasi Map JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'baseAmount': baseAmount,
      'uniqueCode': uniqueCode,
      'totalAmount': totalAmount,
      'method': method.toBackendString(),
      'status': status.toBackendString(),
      'qrisPayload': ?qrisPayload,
      'proofImageUrl': ?proofImageUrl,
      'bankName': ?bankName,
      'senderAccount': ?senderAccount,
      'verifiedAt': ?verifiedAt?.toIso8601String(),
      'verifiedBy': ?verifiedBy,
      'notes': ?notes,
      'expiresAt': ?expiresAt?.toIso8601String(),
      'createdAt': ?createdAt?.toIso8601String(),
      'updatedAt': ?updatedAt?.toIso8601String(),
    };
  }

  PaymentModel copyWith({
    String? id,
    String? bookingId,
    int? baseAmount,
    int? uniqueCode,
    int? totalAmount,
    PaymentMethod? method,
    PaymentStatus? status,
    String? qrisPayload,
    String? proofImageUrl,
    String? bankName,
    String? senderAccount,
    DateTime? verifiedAt,
    String? verifiedBy,
    String? notes,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      baseAmount: baseAmount ?? this.baseAmount,
      uniqueCode: uniqueCode ?? this.uniqueCode,
      totalAmount: totalAmount ?? this.totalAmount,
      method: method ?? this.method,
      status: status ?? this.status,
      qrisPayload: qrisPayload ?? this.qrisPayload,
      proofImageUrl: proofImageUrl ?? this.proofImageUrl,
      bankName: bankName ?? this.bankName,
      senderAccount: senderAccount ?? this.senderAccount,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      notes: notes ?? this.notes,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          bookingId == other.bookingId &&
          totalAmount == other.totalAmount &&
          status == other.status;

  @override
  int get hashCode => id.hashCode ^ bookingId.hashCode ^ totalAmount.hashCode ^ status.hashCode;

  @override
  String toString() =>
      'PaymentModel(id: $id, bookingId: $bookingId, total: $totalAmount, method: $method, status: $status)';

  /// String QRIS statis resmi Gopay Merchant MobilJuragan (Hylmi Shafiy Pranama, Gro)
  static const String officialGopayQris =
      '00020101021126610014COM.GO-JEK.WWW01189360091433744961360210G3744961360303UMI51440014ID.CO.QRIS.WWW0215ID10254456994790303UMI5204549953033605802ID5925HYLMI SHAFIY PRANAMA, Gro6010YOGYAKARTA61055517162070703A0163041261';

  /// Generator QRIS Dinamis mandiri standar EMVCo (Injeksi Tag 54 & CRC-16 CCITT-FALSE)
  /// Menjamin ketahanan offline saat server tidak dapat dijangkau
  static String generateDynamicQris(int amount, [String staticQris = officialGopayQris]) {
    final rounded = amount.round();
    if (rounded <= 0) return staticQris;

    int idx = 0;
    final tags = <Map<String, dynamic>>[];
    while (idx < staticQris.length) {
      if (idx + 4 > staticQris.length) break;
      final tag = staticQris.substring(idx, idx + 2);
      final len = int.tryParse(staticQris.substring(idx + 2, idx + 4)) ?? 0;
      if (idx + 4 + len > staticQris.length) break;
      final val = staticQris.substring(idx + 4, idx + 4 + len);
      tags.add({'tag': tag, 'len': len, 'val': val});
      idx += 4 + len;
    }

    final cleanTags = tags.where((t) => t['tag'] != '63').toList();
    final tag01Idx = cleanTags.indexWhere((t) => t['tag'] == '01');
    if (tag01Idx != -1) {
      cleanTags[tag01Idx] = {'tag': '01', 'len': 2, 'val': '12'};
    }

    final amountStr = rounded.toString();
    final tag54 = {'tag': '54', 'len': amountStr.length, 'val': amountStr};

    final idx58 = cleanTags.indexWhere((t) => t['tag'] == '58');
    if (idx58 != -1) {
      cleanTags.insert(idx58, tag54);
    } else {
      cleanTags.add(tag54);
    }

    final sb = StringBuffer();
    for (final t in cleanTags) {
      final lenStr = (t['len'] as int).toString().padLeft(2, '0');
      sb.write('${t['tag']}$lenStr${t['val']}');
    }
    sb.write('6304');
    final payloadToSign = sb.toString();

    int crc = 0xFFFF;
    for (int i = 0; i < payloadToSign.length; i++) {
      final code = payloadToSign.codeUnitAt(i);
      crc ^= (code << 8);
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    final checksum = crc.toRadixString(16).toUpperCase().padLeft(4, '0');
    return '$payloadToSign$checksum';
  }
}
