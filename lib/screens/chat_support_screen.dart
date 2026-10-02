import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/booking_controller.dart';
import '../controllers/support_controller.dart';
import '../models/booking_model.dart';
import '../models/support_ticket_model.dart';
import '../theme/app_colors.dart';

/// Layanan Live Chat Bantuan Pelanggan (AI Assistant, Handoff Staf Operasional & Pembayaran)
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

  @override
  void initState() {
    super.initState();
    // Jika diarahkan untuk pembayaran, kirimkan pesan tagihan resmi oleh bot secara otomatis
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookingCtrl = context.read<BookingController>();
      final targetBooking = widget.booking ?? bookingCtrl.activeBooking;
      if (targetBooking != null &&
          targetBooking.status == BookingStatus.menungguPembayaran) {
        context.read<SupportController>().sendPaymentInstructionMessage(targetBooking);
        _scrollToBottom();
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

    controller.sendUserMessage(text);
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

    final currentBooking = widget.booking != null
        ? (bookingCtrl.bookingHistory.firstWhere(
            (b) => b.id == widget.booking!.id,
            orElse: () => widget.booking!,
          ))
        : bookingCtrl.activeBooking;

    final activeTicket = widget.ticket ?? (support.tickets.isNotEmpty ? support.tickets.first : null);

    final List<String> suggestions = currentBooking != null &&
            currentBooking.status == BookingStatus.menungguPembayaran
        ? [
            'Konfirmasi Sudah Bayar',
            'No. Rekening Bank BRI',
            'Lokasi jemput Bandara Mopah',
            'Panggil Staf Lapangan',
          ]
        : [
            'Lokasi jemput Bandara Mopah',
            'Konfirmasi armada siap',
            'Perpanjang durasi sewa',
            'Pertanyaan seputar BBM',
          ];

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
          children: [
            Text(
              currentBooking != null ? 'CS Pesanan #${currentBooking.id}' : 'Chat Bantuan CS',
              style: const TextStyle(
                fontSize: 15,
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
                Text(
                  support.isAiHandoffToAdmin
                      ? 'Staf Operasional Merauke (Online)'
                      : 'Customer Service MobilJuragan',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.tealLight,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (!support.isAiHandoffToAdmin)
            TextButton.icon(
              onPressed: () {
                support.handoffToAdmin();
                _scrollToBottom();
              },
              icon: const Icon(Icons.support_agent, color: AppColors.primaryTeal, size: 18),
              label: const Text(
                'Panggil Staf',
                style: TextStyle(
                  color: AppColors.primaryTeal,
                  fontSize: 12,
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
                      fontSize: 11,
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
            // Banner Tiket Bantuan jika ada
            if (activeTicket != null) _buildTicketSummaryBanner(activeTicket),

            // Card Aksi Pembayaran jika ada pesanan terkait
            if (currentBooking != null)
              _buildBookingPaymentCard(currentBooking, support, bookingCtrl),

            // Daftar Pesan Chat
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: support.chatMessages.length,
                itemBuilder: (context, index) {
                  final msg = support.chatMessages[index];
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isWaiting
                          ? 'Tagihan: Rp ${_formatRupiah(booking.totalCost)}'
                          : 'Pembayaran Lunas Diverifikasi',
                      style: TextStyle(
                        fontSize: 12,
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
                          fontSize: 9,
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
                    fontSize: 10,
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
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
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
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
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
                fontSize: 11,
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
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                Text(
                  'Kategori: ${ticket.categoryLabel} • Status: ${ticket.status}',
                  style: const TextStyle(
                    fontSize: 10,
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
                  fontSize: 11,
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

    final timeString = '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')} WIT';

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
                Text(
                  msg.senderName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
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
                    fontSize: 13,
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
                      fontSize: 9,
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
                fontSize: 11,
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
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
                    ),
                  ),
                );
              } else {
                controller.sendUserMessage(suggestion);
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
                        fontSize: 13,
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
              fontSize: 10,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
