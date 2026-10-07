import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/booking_controller.dart';
import '../controllers/support_controller.dart';
import '../models/booking_model.dart';
import '../models/support_ticket_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Layanan Live Chat Bantuan Pelanggan terisolasi per sesi pesanan/tiket (AI Assistant, Handoff Staf Operasional & Pembayaran)
class ChatSupportScreen extends StatefulWidget {
  final SupportTicketModel? ticket;
  final BookingModel? booking;

  const ChatSupportScreen({
    super.key,
    this.ticket,
    this.booking,
  });

  @override
  State<ChatSupportScreen> createState() => _ChatSupportScreenState();
}

class _ChatSupportScreenState extends State<ChatSupportScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  /// Menghasilkan key unik sesi percakapan agar tidak tercampur antar transaksi/tiket
  String get conversationKey {
    if (widget.booking != null) {
      return SupportController.buildConversationKey(bookingId: widget.booking!.id);
    }
    if (widget.ticket != null) {
      return SupportController.buildConversationKey(ticketId: widget.ticket!.id);
    }
    return SupportController.buildConversationKey();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Inisialisasi otomatis hanya jika chat dibuka dari pesanan sewa mobil spesifik
      if (widget.booking != null) {
        final bookingCtrl = context.read<BookingController>();
        final targetBooking = bookingCtrl.bookingHistory.firstWhere(
          (b) => b.id == widget.booking!.id,
          orElse: () => widget.booking!,
        );

        if (targetBooking.status == BookingStatus.mobilSiapDigunakan ||
            targetBooking.status == BookingStatus.pembayaranSelesai) {
          context.read<SupportController>().sendPickupCoordinationMessage(targetBooking);
          _scrollToBottom();
        } else if (targetBooking.status == BookingStatus.menungguPembayaran) {
          context.read<SupportController>().sendPaymentInstructionMessage(targetBooking);
          _scrollToBottom();
        }
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSendMessage(SupportController controller) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    controller.sendUserMessage(text: text, conversationKey: conversationKey);
    _messageController.clear();
    _scrollToBottom();
  }

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

  @override
  Widget build(BuildContext context) {
    final support = context.watch<SupportController>();
    final bookingCtrl = context.watch<BookingController>();

    // Isolasi state: currentBooking hanya ada jika layar ini memang dibuka untuk booking tertentu
    final currentBooking = widget.booking != null
        ? (bookingCtrl.bookingHistory.firstWhere(
            (b) => b.id == widget.booking!.id,
            orElse: () => widget.booking!,
          ))
        : null;

    // activeTicket hanya ada jika layar ini memang dibuka untuk tiket keluhan tertentu
    final activeTicket = widget.ticket;

    // Ambil daftar pesan dan status handoff terisolasi untuk sesi saat ini
    final messages = support.getMessages(conversationKey);
    final isHandedOff = support.isAiHandoffToAdminFor(conversationKey);

    // Rekomendasi pesan cepat sesuai konteks sesi
    final List<String> suggestions;
    if (currentBooking != null) {
      if (currentBooking.status == BookingStatus.menungguPembayaran) {
        suggestions = [
          'Konfirmasi Sudah Bayar',
          'No. Rekening Bank BRI',
          'Lokasi jemput Bandara Mopah',
          'Panggil Staf Lapangan',
        ];
      } else {
        suggestions = [
          'Lokasi jemput Bandara Mopah',
          'Konfirmasi armada siap',
          'Perpanjang durasi sewa',
          'Pertanyaan seputar BBM',
        ];
      }
    } else if (activeTicket != null) {
      suggestions = [
        'Status penanganan tiket',
        'Hubungi staf lapangan',
        'Estimasi tindak lanjut',
        'Panggil Staf Admin',
      ];
    } else {
      suggestions = [
        'Lokasi jemput Bandara Mopah',
        'Verifikasi KTP & SIM A',
        'Tarif sewa & supir',
        'Panggil Staf Admin',
      ];
    }

    // Tentukan judul dan subjudul header AppBar
    final String screenTitle;
    final String screenSubtitle;
    if (currentBooking != null) {
      screenTitle = 'CS Pesanan #${currentBooking.id}';
      screenSubtitle = isHandedOff
          ? 'Staf Operasional Merauke (Online)'
          : '${currentBooking.vehicle.name} (${currentBooking.vehicle.plateNumber})';
    } else if (activeTicket != null) {
      screenTitle = 'Tiket #${activeTicket.id}';
      screenSubtitle = isHandedOff
          ? 'Staf Penanganan Aktif (Online)'
          : 'Kategori: ${activeTicket.categoryLabel}';
    } else {
      screenTitle = 'Chat Bantuan CS';
      screenSubtitle = isHandedOff
          ? 'Staf Operasional Merauke (Online)'
          : 'Customer Service MobilJuragan';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              screenTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: AppTypography.sizeAmount,
                fontWeight: FontWeight.w700,
                color: AppColors.textWhite,
                fontFamily: 'Inter',
              ),
            ),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                // Flexible + ellipsis: subjudul menyusut agar tidak menabrak
                // tombol "Panggil Staf" saat ukuran teks sistem diperbesar.
                Flexible(
                  child: Text(
                    screenSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppTypography.sizeCaption,
                      color: AppColors.tealLight,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (!isHandedOff)
            TextButton.icon(
              onPressed: () {
                support.handoffToAdmin(conversationKey: conversationKey);
                _scrollToBottom();
              },
              icon: const Icon(Icons.support_agent, color: AppColors.primaryTeal, size: 18),
              label: const Text(
                'Panggil Staf',
                style: TextStyle(
                  color: AppColors.primaryTeal,
                  fontSize: AppTypography.sizeBody,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified, color: AppColors.primaryTeal, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Staf Aktif',
                    style: TextStyle(
                      fontSize: AppTypography.sizeCaption,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Banner Tiket Bantuan HANYA muncul jika layar ini dibuka untuk tiket keluhan
            if (activeTicket != null) _buildTicketSummaryBanner(activeTicket),

            // Card Aksi Pembayaran HANYA muncul jika layar ini dibuka untuk pesanan sewa mobil
            if (currentBooking != null)
              _buildBookingPaymentCard(currentBooking, support, bookingCtrl),

            // Daftar Pesan Chat terisolasi per sesi
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  return _buildMessageItem(msg, support);
                },
              ),
            ),

            // Chips Saran Pertanyaan Cepat
            _buildQuickSuggestionsBar(suggestions, support, currentBooking, bookingCtrl),

            // Komposer Pesan
            _buildComposerBar(support),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingPaymentCard(
    BookingModel booking,
    SupportController support,
    BookingController bookingCtrl,
  ) {
    final isWaiting = booking.status == BookingStatus.menungguPembayaran;
    final isReady = booking.status == BookingStatus.mobilSiapDigunakan;

    if (!isWaiting && !isReady) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isWaiting ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4),
        border: Border(
          bottom: BorderSide(
            color: isWaiting ? const Color(0xFFFDE68A) : const Color(0xFFBBF7D0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isWaiting ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                isWaiting ? Icons.account_balance_wallet_outlined : Icons.check_circle_outline,
                color: isWaiting ? const Color(0xFFB45309) : const Color(0xFF15803D),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                  children: [
                    Text(
                      isWaiting
                          ? 'Tagihan: Rp ${_formatRupiah(booking.totalCost)}'
                          : 'Pembayaran Lunas Diverifikasi',
                      style: TextStyle(
                        fontSize: AppTypography.sizeBody,
                        fontWeight: FontWeight.w700,
                        color: isWaiting ? const Color(0xFF92400E) : const Color(0xFF166534),
                        fontFamily: 'Inter',
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isWaiting ? const Color(0xFFFEF2F2) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isWaiting ? 'MENUNGGU TRANSFER' : 'SIAP PAKAI',
                        style: TextStyle(
                          fontSize: AppTypography.sizeMicro,
                          fontWeight: FontWeight.w700,
                          color: isWaiting ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isWaiting
                      ? 'BRI Merauke: 0321-01-002847-53-1 (a.n MobilJuragan)'
                      : 'Kunci siap diserahterimakan di ${booking.pickupLocation}.',
                  style: TextStyle(
                    fontSize: AppTypography.sizeTiny,
                    color: isWaiting ? const Color(0xFFB45309) : const Color(0xFF15803D),
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          if (isWaiting) ...[
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                support.confirmPaymentFromChat(
                  booking: booking,
                  onAdvance: () {
                    bookingCtrl.confirmPaymentAndAdvance(booking.id);
                  },
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF15803D),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    content: Text(
                      'Pembayaran #${booking.id} berhasil diverifikasi! Unit siap digunakan.',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: AppTypography.sizeBody),
                    ),
                  ),
                );
                _scrollToBottom();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF15803D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(44, 32),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text(
                'Sudah Bayar',
                style: TextStyle(fontSize: AppTypography.sizeCaption, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTicketSummaryBanner(SupportTicketModel ticket) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.badgeNavyBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              ticket.id,
              style: const TextStyle(
                fontSize: AppTypography.sizeCaption,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppTypography.sizeBody,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                Text(
                  'Kategori: ${ticket.categoryLabel} • Status: ${ticket.status}',
                  style: const TextStyle(
                    fontSize: AppTypography.sizeTiny,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessageModel msg, SupportController controller) {
    final isUser = msg.isFromUser;
    final isSystemNotice = msg.senderName == 'Sistem';

    if (isSystemNotice) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg.message,
                style: const TextStyle(
                  fontSize: AppTypography.sizeCaption,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E40AF),
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
      );
    }

    final timeString = '${msg.timestamp.hour.toString().padLeft(2, '0')}.${msg.timestamp.minute.toString().padLeft(2, '0')} WIT';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Header Pengirim (Untuk Admin / AI)
          if (!isUser) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: msg.isAI ? AppColors.tealLight : AppColors.primaryNavy,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      msg.isAI ? Icons.headset_mic_rounded : Icons.person,
                      size: 12,
                      color: msg.isAI ? AppColors.primaryTeal : AppColors.textWhite,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Flexible: nama pengirim panjang menyusut dengan ellipsis
                // saat ukuran teks sistem diperbesar.
                Flexible(
                  child: Text(
                    msg.senderName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppTypography.sizeCaption,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],

          // Bubble Chat
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser
                  ? AppColors.primaryNavy
                  : (msg.isAI ? AppColors.cardWhite : const Color(0xFFF0FDF4)),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(isUser ? 14 : 2),
                bottomRight: Radius.circular(isUser ? 2 : 14),
              ),
              border: Border.all(
                color: isUser
                    ? AppColors.primaryNavy
                    : (msg.isAI ? AppColors.borderSubtle : const Color(0xFFBBF7D0)),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg.message,
                  style: TextStyle(
                    fontSize: AppTypography.sizeBodyLarge,
                    height: 1.4,
                    color: isUser ? AppColors.textWhite : AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    timeString,
                    style: TextStyle(
                      fontSize: AppTypography.sizeMicro,
                      color: isUser
                          ? AppColors.textWhite.withValues(alpha: 0.7)
                          : AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSuggestionsBar(
    List<String> suggestions,
    SupportController controller,
    BookingModel? booking,
    BookingController bookingCtrl,
  ) {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ActionChip(
            backgroundColor: AppColors.cardWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.borderSubtle),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            label: Text(
              suggestion,
              style: const TextStyle(
                fontSize: AppTypography.sizeCaption,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
            onPressed: () {
              if (suggestion == 'Konfirmasi Sudah Bayar' && booking != null) {
                controller.confirmPaymentFromChat(
                  booking: booking,
                  onAdvance: () {
                    bookingCtrl.confirmPaymentAndAdvance(booking.id);
                  },
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF15803D),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    content: Text(
                      'Pembayaran #${booking.id} berhasil diverifikasi! Unit siap digunakan.',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: AppTypography.sizeBody),
                    ),
                  ),
                );
              } else if (suggestion == 'Panggil Staf Lapangan' ||
                  suggestion == 'Panggil Staf Admin') {
                controller.handoffToAdmin(conversationKey: conversationKey);
              } else {
                controller.sendUserMessage(
                  text: suggestion,
                  conversationKey: conversationKey,
                );
              }
              _scrollToBottom();
            },
          );
        },
      ),
    );
  }

  Widget _buildComposerBar(SupportController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSendMessage(controller),
                    decoration: const InputDecoration(
                      hintText: 'Ketik pesan bantuan atau konfirmasi...',
                      hintStyle: TextStyle(
                        fontSize: AppTypography.sizeBodyLarge,
                        color: AppColors.textSecondary,
                        fontFamily: 'Inter',
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primaryTeal,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: AppColors.textWhite, size: 18),
                  onPressed: () => _handleSendMessage(controller),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Pesan terhubung langsung dengan staf operasional MobilJuragan Merauke.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTypography.sizeTiny,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
