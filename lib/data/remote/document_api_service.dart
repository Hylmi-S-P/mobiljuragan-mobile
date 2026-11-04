import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../models/booking_document_model.dart';

/// Berkas dokumen resmi hasil unduhan.
///
/// Isinya tidak selalu PDF: admin boleh mengunggah dokumen Word, dan aplikasi
/// harus menyimpan berkas itu apa adanya dengan tipe yang benar. Nama berkas
/// diambil dari server supaya pelanggan menerima nama yang dikenali, bukan nama
/// karangan aplikasi.
class BerkasDokumen {
  const BerkasDokumen({
    required this.isi,
    required this.namaBerkas,
    required this.mime,
  });

  final Uint8List isi;
  final String namaBerkas;
  final String mime;
}

/// Layanan API untuk pengelolaan berkas persyaratan sewa lepas kunci
class DocumentApiService {
  final ApiClient _client;
  final http.Client _httpClient;

  DocumentApiService([ApiClient? client, http.Client? httpClient])
      : _client = client ?? ApiClient(),
        _httpClient = httpClient ?? http.Client();

  /// Mengambil keterangan dokumen resmi yang sedang aktif.
  ///
  /// Yang dikembalikan adalah keterangan berkasnya (nama, tipe, ukuran, versi),
  /// bukan lagi daftar klausul. Dokumennya berupa berkas unggahan admin yang
  /// bisa berbentuk PDF atau Word, sehingga isinya tidak bisa ditampilkan
  /// sebagai teks. Pelanggan membaca dan menandatangani berkas hasil unduhan.
  Future<Map<String, dynamic>> fetchStatementTemplateText() async {
    final response = await _client.get(
      ApiConstants.documentTemplateTextEndpoint,
      requiresAuth: false,
    );

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return {};
  }

  /// Mengunduh berkas dokumen resmi yang sedang aktif.
  ///
  /// Nama berkas dan tipenya dibaca dari header balasan server, karena
  /// dokumennya bisa PDF atau Word tergantung apa yang diunggah admin.
  Future<BerkasDokumen> downloadStatementTemplatePdf() async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.documentTemplatePdfEndpoint}',
    );

    final response = await _httpClient
        .get(uri)
        .timeout(ApiConstants.timeoutDuration);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'Gagal mengunduh dokumen resmi (Status: ${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    final mime = response.headers['content-type']?.split(';').first.trim() ??
        'application/pdf';

    return BerkasDokumen(
      isi: response.bodyBytes,
      namaBerkas: _namaDariHeader(response.headers['content-disposition'], mime),
      mime: mime,
    );
  }

  /// Membaca nama berkas dari `Content-Disposition`, dengan cadangan yang aman.
  ///
  /// Server mengirim dua bentuk: `filename=` biasa dan `filename*=UTF-8''...`
  /// untuk nama berisi karakter non-ASCII. Bentuk kedua didahulukan karena
  /// itulah yang benar untuk nama seperti "Form Kesanggupan.pdf".
  String _namaDariHeader(String? header, String mime) {
    final cadangan = mime.contains('wordprocessingml')
        ? 'Form-Kesanggupan.docx'
        : mime == 'application/msword'
            ? 'Form-Kesanggupan.doc'
            : 'Form-Kesanggupan.pdf';

    if (header == null || header.isEmpty) return cadangan;

    final utf8 = RegExp(r"filename\*=UTF-8''([^;]+)", caseSensitive: false)
        .firstMatch(header);
    if (utf8 != null) {
      try {
        return Uri.decodeComponent(utf8.group(1)!.trim());
      } catch (_) {
        // Nama tidak bisa didekode; pakai cadangan.
      }
    }

    final biasa =
        RegExp(r'filename="?([^";]+)"?', caseSensitive: false).firstMatch(header);
    if (biasa != null) {
      final nama = biasa.group(1)!.trim();
      if (nama.isNotEmpty) return nama;
    }

    return cadangan;
  }

  /// Mengambil dokumen persyaratan yang terikat dengan pemesanan
  Future<BookingDocumentModel?> fetchBookingDocuments(String bookingId) async {
    final response = await _client.get(
      '${ApiConstants.bookingsEndpoint}/$bookingId/documents',
      requiresAuth: true,
    );

    if (response is Map) {
      return BookingDocumentModel.fromJson(
        Map<String, dynamic>.from(response),
      );
    }
    return null;
  }

  /// Mengunggah dokumen persyaratan sewa lepas kunci sebagai multipart.
  ///
  /// Berkas dikirim apa adanya (JPG/PNG/WebP). Server yang memvalidasi isi,
  /// mengubahnya ke WebP, dan membuang metadata — klien tidak perlu mengurus
  /// konversi atau base64 lagi.
  Future<BookingDocumentModel> uploadBookingDocuments({
    required String bookingId,
    XFile? statementLetter,
    XFile? ktp,
    XFile? sim,
  }) async {
    final files = <String, http.MultipartFile>{};

    Future<void> add(String field, XFile? file) async {
      if (file == null) return;
      /* Dikirim dari byte, bukan path: berkas hasil kamera bisa berada di cache
         sementara, dan `XFile.fromData` (dipakai pengujian) tidak punya path. */
      final bytes = await file.readAsBytes();
      files[field] = http.MultipartFile.fromBytes(
        field,
        bytes,
        filename: file.name.isEmpty ? '$field.jpg' : file.name,
      );
    }

    await add('statementLetter', statementLetter);
    await add('ktp', ktp);
    await add('sim', sim);

    if (files.isEmpty) {
      throw ApiException('Pilih minimal satu berkas untuk diunggah.');
    }

    final response = await _client.postMultipart(
      '${ApiConstants.bookingsEndpoint}/$bookingId/documents',
      files: files,
      requiresAuth: true,
    );

    if (response is Map) {
      return BookingDocumentModel.fromJson(Map<String, dynamic>.from(response));
    }
    throw ApiException('Respons server tidak valid saat mengunggah dokumen.');
  }
}
