import 'dart:async';
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
  Timer? _keyboardScrollTimer;
  Timer? _ticketPollingTimer;

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
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _keyboardScrollTimer?.cancel();
        // Beri jeda 350ms agar animasi keyboard bawaan OS selesai sepenuhnya
        // sebelum scroll, menghindari konflik animasi dan getaran layar (jitter)
        _keyboardScrollTimer = Timer(const Duration(milliseconds: 350), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutQuad,
            );
          }
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.ticket != null) {
        context.read<SupportController>().refreshTicketConversation(widget.ticket!.id);

        // Polling periodik untuk mengambil balasan staf operasional nyata dari dashboard
        _ticketPollingTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
          if (mounted && widget.ticket != null) {
            context.read<SupportController>().refreshTicketConversation(widget.ticket!.id);
          }
        });
      }

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
    _ticketPollingTimer?.cancel();
    _keyboardScrollTimer?.cancel();
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
    final maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.78;
    final support = context.watch<SupportController>();
    final bookingCtrl = context.watch<BookingController>();

    // Isolasi state: currentBooking hanya ada jika layar ini memang dibuka untuk booking tertentu
    final currentBooking = widget.booking != null
        ? (bookingCtrl.bookingHistory.firstWhere(
            (b) => b.id == widget.booking!.id,
            orElse: () => widget.booking!,
          ))
        : null;

    // activeTicket membaca secara reaktif dari state support.tickets
    final activeTicket = widget.ticket != null
        ? support.tickets.firstWhere(
            (t) => t.id == widget.ticket!.id,
            orElse: () => widget.ticket!,
          )
        : null;

    // Ambil daftar pesan dan status handoff terisolasi untuk sesi saat ini
    final messages = support.getMessages(conversationKey);
    final isHandedOff = activeTicket != null || support.isAiHandoffToAdminFor(conversationKey);

    // Rekomendasi pesan cepat sesuai konteks sesi
    final List<String> suggestions;
    if (currentBooking != null) {
      if (currentBooking.status == BookingStatus.menungguPembayaran) {
        suggestions = [
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
      if (activeTicket.isFinished) {
        suggestions = const [];
      } else {
        suggestions = [
          'Status penanganan',
          'Kirim foto kendala',
          'Posisi armada saat ini',
        ];
      }
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
      screenTitle = 'Tiket #${activeTicket.displayTicketNumber}';
      screenSubtitle = isHandedOff
          ? 'Staf Penanganan Aktif (Online)'
          : 'Kategori: ${activeTicket.categoryLabel}';
    } else {
      screenTitle = 'Tanya Cepat CS';
      screenSubtitle = isHandedOff
          ? 'Staf Operasional Merauke (Online)'
          : 'Asisten AI MobilJuragan (Online)';
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
                // Flexible + ellipsis: subjudul menyusut agar tidak menabrak tombol aksi
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
          if (activeTicket != null)
            if (activeTicket.isClosed)
              Container(
                margin: const EdgeInsets.only(right: 14),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF475569), width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 12, color: Color(0xFF94A3B8)),
                    SizedBox(width: 4),
                    Text(
                      'Ditutup',
                      style: TextStyle(
                        fontSize: AppTypography.sizeCaption,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE2E8F0),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              )
            else if (activeTicket.isResolved)
              Container(
                margin: const EdgeInsets.only(right: 12),
                child: OutlinedButton.icon(
                  onPressed: () => _confirmCloseTicket(context, activeTicket),
                  icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 15),
                  label: const Text(
                    'Tutup Permanen',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: AppTypography.sizeCaption,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF22C55E), width: 1.1),
                    backgroundColor: const Color(0xFF166534).withValues(alpha: 0.35),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(44, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(right: 12),
                child: OutlinedButton.icon(
                  onPressed: () => _confirmCloseTicket(context, activeTicket),
                  icon: const Icon(Icons.check_circle_outline, color: Color(0xFFFCA5A5), size: 15),
                  label: const Text(
                    'Tutup Tiket',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: AppTypography.sizeCaption,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF4444), width: 1.1),
                    backgroundColor: const Color(0xFF991B1B).withValues(alpha: 0.35),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(44, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              )
          else if (!isHandedOff)
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: OutlinedButton.icon(
                onPressed: () {
                  support.handoffToAdmin(conversationKey: conversationKey);
                  _scrollToBottom();
                },
                icon: const Icon(Icons.support_agent_rounded, color: Color(0xFF5EEAD4), size: 16),
                label: const Text(
                  'Panggil Staf',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: AppTypography.sizeCaption,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF14B8A6), width: 1.2),
                  backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.35),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(44, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            )
          else if (activeTicket == null)
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: OutlinedButton.icon(
                onPressed: () {
                  support.returnToAi(conversationKey: conversationKey);
                  _scrollToBottom();
                },
                icon: const Icon(Icons.smart_toy_outlined, color: Color(0xFF93C5FD), size: 15),
                label: const Text(
                  'Mode AI',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: AppTypography.sizeCaption,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF3B82F6), width: 1.1),
                  backgroundColor: const Color(0xFF1E3A8A).withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(44, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF064E3B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF059669), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Staf Aktif',
                    style: TextStyle(
                      fontSize: AppTypography.sizeCaption,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6EE7B7),
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      body: Column(
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
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: messages.length + (support.isAiThinkingFor(conversationKey) ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < messages.length) {
                  final msg = messages[index];
                  return _buildMessageItem(msg, support, maxBubbleWidth);
                }
                return _buildAiThinkingBubble(maxBubbleWidth);
              },
            ),
          ),

          // Panel Bawah Terpadu (Saran Cepat + Input Pesan)
          _buildUnifiedBottomArea(
            suggestions: suggestions,
            support: support,
            booking: currentBooking,
            bookingCtrl: bookingCtrl,
            activeTicket: activeTicket,
          ),
        ],
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
                style: AppTypography.captionBold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTicketSummaryBanner(SupportTicketModel ticket) {
    Color statusColor;
    Color statusBg;
    if (ticket.isClosed) {
      statusColor = const Color(0xFF475569);
      statusBg = const Color(0xFFF1F5F9);
    } else if (ticket.isResolved) {
      statusColor = const Color(0xFF15803D);
      statusBg = const Color(0xFFDCFCE7);
    } else if (ticket.status == 'Diproses') {
      statusColor = const Color(0xFFB45309);
      statusBg = const Color(0xFFFEF3C7);
    } else {
      statusColor = const Color(0xFF1D4ED8);
      statusBg = const Color(0xFFDBEAFE);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.badgeNavyBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ticket.displayTicketNumber,
                  style: const TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ticket.status,
                  style: TextStyle(
                    fontSize: AppTypography.sizeTiny,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
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
                      'Kategori: ${ticket.categoryLabel}',
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
          if (ticket.isResolved) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 18,
                    color: Color(0xFFB45309),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kendala Selesai (Masa Tenggang 24 Jam)',
                          style: TextStyle(
                            fontSize: AppTypography.sizeCaption,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF92400E),
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Staf operasional telah menyelesaikan kendala Anda. Tiket ini akan ditutup permanen secara otomatis setelah 24 jam. Jika kendala sudah tuntas, Anda dapat langsung menutupnya.',
                          style: TextStyle(
                            fontSize: AppTypography.sizeTiny,
                            color: Color(0xFF78350F),
                            fontFamily: 'Inter',
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            onPressed: () => _confirmCloseTicket(context, ticket),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB45309),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Tutup Tiket Sekarang',
                              style: TextStyle(
                                fontSize: AppTypography.sizeTiny,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (ticket.isClosed) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: Color(0xFF475569),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tiket bantuan ini telah ditutup permanen. Riwayat percakapan tersimpan sebagai arsip.',
                      style: TextStyle(
                        fontSize: AppTypography.sizeTiny,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildMessageItem(ChatMessageModel msg, SupportController controller, double maxBubbleWidth) {
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
                      msg.isAI ? Icons.smart_toy_outlined : Icons.person,
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
                if (msg.isAI) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFBAE6FD), width: 0.8),
                    ),
                    child: const Text(
                      'Bot AI',
                      style: TextStyle(
                        fontSize: AppTypography.sizeMicro,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0369A1),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
          ],

          // Bubble Chat
          Container(
            constraints: BoxConstraints(
              maxWidth: maxBubbleWidth,
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pesan yang gagal sampai ke server diberi penanda supaya
                      // pelanggan tidak menunggu balasan atas pesan yang tidak
                      // pernah diterima tim.
                      if (msg.isFailed) ...[
                        Icon(
                          Icons.error_outline_rounded,
                          size: 12,
                          color: isUser ? const Color(0xFFFCA5A5) : const Color(0xFFB42318),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Gagal terkirim',
                          style: TextStyle(
                            fontSize: AppTypography.sizeMicro,
                            fontWeight: FontWeight.w600,
                            color: isUser ? const Color(0xFFFCA5A5) : const Color(0xFFB42318),
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        timeString,
                        style: TextStyle(
                          fontSize: AppTypography.sizeMicro,
                          color: isUser
                              ? AppColors.textWhite.withValues(alpha: 0.7)
                              : AppColors.textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiThinkingBubble(double maxBubbleWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppColors.tealLight,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.smart_toy_outlined,
                    size: 12,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Asisten AI MobilJuragan',
                style: TextStyle(
                  fontSize: AppTypography.sizeCaption,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFBAE6FD), width: 0.8),
                ),
                child: const Text(
                  'Bot AI',
                  style: TextStyle(
                    fontSize: AppTypography.sizeMicro,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0369A1),
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(2),
                bottomRight: Radius.circular(14),
              ),
              border: Border.all(color: AppColors.borderSubtle, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Asisten AI sedang menyusun jawaban...',
                  style: TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
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

  Widget _buildQuickSuggestionsBar(
    List<String> suggestions,
    SupportController controller,
    BookingModel? booking,
    BookingController bookingCtrl,
  ) {
    return Container(
      height: 42,
      padding: const EdgeInsets.only(top: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: suggestions.map((suggestion) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                backgroundColor: const Color(0xFFF1F5F9),
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
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildComposerBar(SupportController controller, SupportTicketModel? activeTicket) {
    final hint = activeTicket != null && activeTicket.isResolved
        ? 'Ketik sanggahan jika kendala belum selesai...'
        : 'Ketik pesan bantuan atau konfirmasi...';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: const TextStyle(
                        fontSize: AppTypography.sizeBodyLarge,
                        color: AppColors.textSecondary,
                        fontFamily: 'Inter',
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

  /// Panel Bawah Terpadu: Menggabungkan saran pesan cepat dan kolom input
  /// dalam satu container atomic dengan ClampingScrollPhysics dan SafeArea
  /// agar terangkat secara mulus tanpa jitter saat keyboard muncul.
  Widget _buildUnifiedBottomArea({
    required List<String> suggestions,
    required SupportController support,
    required BookingModel? booking,
    required BookingController bookingCtrl,
    required SupportTicketModel? activeTicket,
  }) {
    if (activeTicket != null && activeTicket.isClosed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: const BoxDecoration(
          color: AppColors.cardWhite,
          border: Border(
            top: BorderSide(color: AppColors.borderSubtle, width: 1),
          ),
        ),
        child: const SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Tiket telah ditutup permanen. Ruang percakapan ini tersimpan sebagai arsip.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (suggestions.isNotEmpty)
              _buildQuickSuggestionsBar(suggestions, support, booking, bookingCtrl),
            _buildComposerBar(support, activeTicket),
          ],
        ),
      ),
    );
  }

  void _confirmCloseTicket(BuildContext context, SupportTicketModel ticket) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Tutup Tiket Bantuan',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: AppTypography.sizeTitle,
          ),
        ),
        content: const Text(
          'Apakah kendala Anda sudah terselesaikan? Setelah tiket ditutup, status akan berubah menjadi Ditutup dan percakapan akan diarsipkan ke Riwayat Bantuan.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: AppTypography.sizeBody,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final support = context.read<SupportController>();
              await support.closeTicket(ticket.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Tiket bantuan berhasil ditutup dan dipindahkan ke Riwayat Bantuan.',
                      style: TextStyle(fontFamily: 'Inter'),
                    ),
                    backgroundColor: Color(0xFF15803D),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: AppColors.textWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Tutup Tiket Sekarang',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
