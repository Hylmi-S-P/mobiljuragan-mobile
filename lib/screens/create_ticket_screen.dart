import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/booking_controller.dart';
import '../controllers/support_controller.dart';
import '../models/support_ticket_model.dart';
import '../theme/app_colors.dart';
import 'chat_support_screen.dart';

/// Formulir pembuatan tiket kendala dan pengaduan layanan sewa (Frame 10)
class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bookingIdController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  TicketCategory _selectedCategory = TicketCategory.reservasi;
  String? _attachedFileName;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Auto-fill nomor booking aktif jika tersedia
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final booking = context.read<BookingController>();
      if (booking.hasActiveBooking && booking.activeBooking != null) {
        _bookingIdController.text = booking.activeBooking!.id;
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bookingIdController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final support = context.read<SupportController>();
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final bookingId = _bookingIdController.text.trim();

    final fullDesc = bookingId.isNotEmpty
        ? 'Ref Booking: $bookingId\n$description'
        : description;

    support.createTicket(
      title: title,
      category: _selectedCategory,
      description: fullDesc,
      attachmentName: _attachedFileName,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tiket bantuan berhasil diajukan! Membuka ruang chat...',
                style: TextStyle(fontFamily: 'Inter'),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF15803D),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    // Navigasi langsung ke ruang chat bantuan dengan tiket yang baru dibuat
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChatSupportScreen(ticket: support.tickets.first),
      ),
    );
  }

  void _toggleAttachmentSimulation() {
    setState(() {
      if (_attachedFileName == null) {
        _attachedFileName = 'foto_kendala_lapangan_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}.jpg';
      } else {
        _attachedFileName = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buat Ticket Bantuan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textWhite,
                fontFamily: 'Inter',
              ),
            ),
            Text(
              'Layanan Operasional Merauke',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.tealLight,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Utama Formulir
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSubtle),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Formulir Kendala Layanan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Sampaikan pertanyaan atau masalah selama masa sewa unit di Merauke.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: AppColors.borderSubtle, height: 1),
                      const SizedBox(height: 16),

                      // Input 1: Judul Ticket
                      const Text(
                        'Judul Ticket',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
                        decoration: InputDecoration(
                          hintText: 'Contoh: Mobil belum tiba di Bandara Mopah',
                          hintStyle: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontFamily: 'Inter',
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.borderSubtle),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.borderSubtle),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Judul tiket tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Input 2: Kategori / Jenis Bantuan
                      const Text(
                        'Jenis Bantuan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: TicketCategory.values.map((cat) {
                          final isSelected = _selectedCategory == cat;
                          return ChoiceChip(
                            label: Text(
                              _getCategoryShortLabel(cat),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
                                fontFamily: 'Inter',
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.primaryNavy,
                            backgroundColor: const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSelected ? AppColors.primaryNavy : AppColors.borderSubtle,
                              ),
                            ),
                            showCheckmark: false,
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _selectedCategory = cat;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Input 3: Nomor Booking Terkait (Opsional)
                      const Text(
                        'Nomor Booking Terkait (Opsional)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _bookingIdController,
                        style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
                        decoration: InputDecoration(
                          hintText: 'Contoh: MBJ-2026-0042',
                          hintStyle: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontFamily: 'Inter',
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.borderSubtle),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.borderSubtle),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Input 4: Detail Kendala
                      const Text(
                        'Detail Kendala atau Pertanyaan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
                        decoration: InputDecoration(
                          hintText: 'Tuliskan rincian situasi di lapangan, kendala unit, atau waktu penjemputan...',
                          hintStyle: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontFamily: 'Inter',
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.all(14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.borderSubtle),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.borderSubtle),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 5) {
                            return 'Mohon berikan rincian kendala minimal 5 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Lampiran Foto (Opsional)
                      InkWell(
                        onTap: _toggleAttachmentSimulation,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _attachedFileName != null ? AppColors.primaryTeal : AppColors.borderSubtle,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _attachedFileName != null ? Icons.check_circle : Icons.camera_alt_outlined,
                                size: 18,
                                color: _attachedFileName != null ? AppColors.primaryTeal : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _attachedFileName ?? 'Lampirkan Foto Kondisi Kendala (Opsional)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _attachedFileName != null ? FontWeight.w600 : FontWeight.w400,
                                    color: _attachedFileName != null ? AppColors.primaryTeal : AppColors.textSecondary,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                              if (_attachedFileName != null)
                                const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // AI Assistant Notice Box (Presisi Frame 10 Figma)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('🤖', style: TextStyle(fontSize: 16)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Chat dibantu AI Assistant untuk respon instan awal.\nJika butuh penanganan armada fisik, dialihkan otomatis ke staf CS.',
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF15803D),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Emergency Hotline Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('⚠️', style: TextStyle(fontSize: 16)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Kendala mogok atau darurat di perjalanan? Hubungi nomor darurat 24 jam Merauke di 0812-4800-9999.',
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFB91C1C),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Tombol Submit Form
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: AppColors.textWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Kirim Ticket & Buka Chat',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'Tiket terhubung langsung ke AI Assistant & staf operasional Merauke.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getCategoryShortLabel(TicketCategory category) {
    switch (category) {
      case TicketCategory.reservasi:
        return 'Jadwal & Reservasi';
      case TicketCategory.pembayaran:
        return 'Pembayaran & Biaya';
      case TicketCategory.kendaraan:
        return 'Kondisi Armada';
      case TicketCategory.layananSopir:
        return 'Layanan Driver';
      case TicketCategory.lainnya:
        return 'Pertanyaan Umum';
    }
  }
}
