import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/support_controller.dart';
import '../models/support_ticket_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'chat_support_screen.dart';

/// Formulir pengajuan tiket bantuan pelanggan.
///
/// Tiket di sini tidak harus soal sewa yang sedang berjalan: orang bisa bertanya
/// soal tarif, syarat lepas kunci, atau titik jemput sebelum memesan. Karena itu
/// formulirnya sengaja tidak meminta nomor booking maupun armada — dulu kedua
/// isian itu ada (bahkan terisi otomatis dari pesanan aktif), sehingga pertanyaan
/// pra-sewa terpaksa membawa data pesanan yang tidak ada hubungannya.
///
/// Lampiran foto juga dihapus: yang tersimpan dulu hanya *nama berkas karangan*,
/// bukan gambar, jadi pelanggan mengira sudah melampirkan bukti padahal tidak ada
/// berkas yang terkirim.
class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  /// Sama dengan batas di server (`MAKS_PANJANG_JUDUL`), supaya klien dan API
  /// tidak saling menyalahkan. Server tetap memeriksa sendiri.
  static const int _maxTitleLength = 100;

  /// Deskripsi dipakai server sebagai pesan pertama percakapan.
  static const int _maxDescriptionLength = 2000;

  /// Di bawah ini deskripsi belum bisa ditindaklanjuti siapa pun.
  static const int _minDescriptionLength = 10;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();

  TicketCategory _selectedCategory = TicketCategory.reservasi;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    /* Penghitung karakter ikut berubah saat mengetik. */
    _titleController.addListener(_refreshCounters);
    _descriptionController.addListener(_refreshCounters);
  }

  @override
  void dispose() {
    _titleController.removeListener(_refreshCounters);
    _descriptionController.removeListener(_refreshCounters);
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  void _refreshCounters() {
    if (mounted) setState(() {});
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final support = context.read<SupportController>();
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    final ticket = await support.createTicket(
      title: title,
      category: _selectedCategory,
      description: description,
    );

    if (!mounted) return;

    /* Server tidak menerima tiketnya. Dulu kasus ini didiamkan: sebuah tiket
       karangan tetap masuk daftar dan layar langsung pindah ke ruang obrolan,
       padahal tidak ada admin yang bisa melihatnya dan tiketnya hilang begitu
       aplikasi ditutup. Sekarang formulir tetap terisi dan pelanggan diberi tahu
       apa yang gagal. */
    if (!ticket.tersimpanDiServer) {
      support.buangTiketBelumTersimpan(ticket.id);
      setState(() {
        _isSubmitting = false;
        _errorMessage =
            'Tiket belum terkirim karena koneksi ke server gagal. Isian Anda masih tersimpan di formulir ini — periksa jaringan lalu kirim ulang.';
      });
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ChatSupportScreen(ticket: ticket)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final judulTerisi = _titleController.text.trim().isNotEmpty;
    final deskripsiLength = _descriptionController.text.trim().length;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Buat Tiket Bantuan',
          style: TextStyle(
            fontSize: AppTypography.sizeHeading,
            fontWeight: FontWeight.w700,
            color: AppColors.textWhite,
            fontFamily: 'Inter',
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              const Text(
                'Ceritakan kendala atau pertanyaan Anda. Bisa soal sewa yang sedang berjalan, atau rencana sewa yang belum dipesan.',
                style: TextStyle(
                  fontSize: AppTypography.sizeBodyLarge,
                  height: 1.45,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 24),

              _buildLabel('Jenis Bantuan'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TicketCategory.values.map(_buildCategoryChip).toList(),
              ),
              const SizedBox(height: 24),

              _buildLabel('Judul'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                focusNode: _titleFocus,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: [LengthLimitingTextInputFormatter(_maxTitleLength)],
                onFieldSubmitted: (_) => _descriptionFocus.requestFocus(),
                style: const TextStyle(
                  fontSize: AppTypography.sizeBodyLarge,
                  fontFamily: 'Inter',
                ),
                decoration: _inputDecoration(
                  hint: _titleHintFor(_selectedCategory),
                  counter: '${_titleController.text.characters.length}/$_maxTitleLength',
                ),
                validator: (value) {
                  final judul = value?.trim() ?? '';
                  if (judul.isEmpty) return 'Judul belum diisi.';
                  if (judul.length < 5) return 'Judul terlalu pendek — tulis minimal 5 karakter.';
                  return null;
                },
              ),
              const SizedBox(height: 18),

              _buildLabel('Detail'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                focusNode: _descriptionFocus,
                maxLines: 6,
                minLines: 5,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                inputFormatters: [LengthLimitingTextInputFormatter(_maxDescriptionLength)],
                style: const TextStyle(
                  fontSize: AppTypography.sizeBodyLarge,
                  height: 1.45,
                  fontFamily: 'Inter',
                ),
                decoration: _inputDecoration(
                  hint: 'Contoh: Saya rencana sewa Avanza lepas kunci tanggal 5, '
                      'bisa dijemput di Bandara Mopah?',
                  counter:
                      '$deskripsiLength/$_maxDescriptionLength',
                ),
                validator: (value) {
                  final detail = value?.trim() ?? '';
                  if (detail.isEmpty) return 'Detail belum diisi.';
                  if (detail.length < _minDescriptionLength) {
                    return 'Detail terlalu pendek — tulis minimal $_minDescriptionLength karakter.';
                  }
                  return null;
                },
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 18),
                _buildErrorBox(_errorMessage!),
              ],

              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: (_isSubmitting || !judulTerisi) ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: AppColors.textWhite,
                    disabledBackgroundColor: AppColors.borderMedium,
                    disabledForegroundColor: AppColors.textWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _errorMessage == null ? 'Kirim Tiket' : 'Kirim Ulang',
                          style: const TextStyle(
                            fontSize: AppTypography.sizeTitle,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: AppTypography.sizeBody,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        fontFamily: 'Inter',
      ),
    );
  }

  Widget _buildCategoryChip(TicketCategory category) {
    final isSelected = _selectedCategory == category;
    return ChoiceChip(
      label: Text(
        _categoryLabel(category),
        style: TextStyle(
          fontSize: AppTypography.sizeCaption,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
          fontFamily: 'Inter',
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primaryNavy,
      backgroundColor: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? AppColors.primaryNavy : AppColors.borderSubtle,
        ),
      ),
      showCheckmark: false,
      onSelected: (selected) {
        if (!selected) return;
        setState(() => _selectedCategory = category);
      },
    );
  }

  InputDecoration _inputDecoration({required String hint, required String counter}) {
    const radius = BorderRadius.all(Radius.circular(8));
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: AppTypography.sizeBody,
        height: 1.45,
        color: AppColors.textMuted,
        fontFamily: 'Inter',
      ),
      helperText: '',
      counterText: counter,
      counterStyle: const TextStyle(
        fontSize: AppTypography.sizeCaption,
        color: AppColors.textMuted,
        fontFamily: 'Inter',
      ),
      filled: true,
      fillColor: AppColors.cardWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.borderMedium),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.borderMedium),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.primaryTeal, width: 1.5),
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.statusCancelledBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.statusCancelled),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: AppTypography.sizeBody,
                height: 1.4,
                color: Color(0xFF991B1B),
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Contoh judul mengikuti jenis bantuan yang dipilih, supaya pelanggan tidak
  /// menulis "tanya" atau "kendala" saja.
  String _titleHintFor(TicketCategory category) {
    switch (category) {
      case TicketCategory.reservasi:
        return 'Contoh: Minta jemput di Bandara Mopah';
      case TicketCategory.pembayaran:
        return 'Contoh: Bukti transfer belum diverifikasi';
      case TicketCategory.kendaraan:
        return 'Contoh: AC tidak dingin sejak kemarin';
      case TicketCategory.layananSopir:
        return 'Contoh: Supir datang terlambat';
      case TicketCategory.lainnya:
        return 'Contoh: Apakah bisa sewa tiga hari saja?';
    }
  }

  String _categoryLabel(TicketCategory category) {
    switch (category) {
      case TicketCategory.reservasi:
        return 'Jadwal & Reservasi';
      case TicketCategory.pembayaran:
        return 'Pembayaran & Biaya';
      case TicketCategory.kendaraan:
        return 'Kondisi Armada';
      case TicketCategory.layananSopir:
        return 'Layanan Sopir';
      case TicketCategory.lainnya:
        return 'Pertanyaan Umum';
    }
  }
}
