import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/booking_controller.dart';
import '../controllers/support_controller.dart';
import '../models/booking_model.dart';
import '../models/support_ticket_model.dart';
import 'create_ticket_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Layanan Live Chat Bantuan Pelanggan terisolasi per sesi pesanan/tiket (AI Assistant, Handoff Staf Operasional & Pembayaran)
class ChatSupportScreen extends StatefulWidget {
  final SupportTicketModel? ticket;
  final BookingModel? booking;

  const ChatSupportScreen({super.key, this.ticket, this.booking});

  @override
  State<ChatSupportScreen> createState() => _ChatSupportScreenState();
}

class _ChatSupportScreenState extends State<ChatSupportScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  Timer? _keyboardScrollTimer;
  SupportController? _supportController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _supportController = context.read<SupportController>();
  }

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
      /* Muat riwayat dari server saat layar dibuka.
       *
       * Tanpa ini, percakapan hanya hidup di memori aplikasi: menutup layar atau
       * memulai ulang aplikasi membuat riwayat hilang, padahal pesannya sudah
       * tersimpan di server. Balasan staf yang masuk saat layar tertutup pun tidak
       * akan pernah terlihat. */
      if (widget.ticket != null) {
        final support = context.read<SupportController>();
        support.muatRiwayatTiket(ticketId: widget.ticket!.id).then((_) {
          if (!mounted) return;
          final currentMsgs = support.getMessages(conversationKey);
          final hasAi = currentMsgs.any((m) => m.isAI);
          if (!hasAi && !support.isAiHandoffToAdminFor(conversationKey)) {
            support.inisialisasiResponAiTiket(ticket: widget.ticket!);
          }
        });

        /* Langganan peristiwa tiket.
         *
         * Backend sudah mengirim peristiwa setiap ada pesan atau perubahan
         * status, tetapi sebelumnya tidak ada klien yang mendengarkan. Akibatnya
         * balasan staf baru terlihat setelah layar dimuat ulang manual. */
        support.dengarkanTiket(
          ticketId: widget.ticket!.id,
          onPesanBaru: () {
            if (!mounted) return;
            support.muatRiwayatTiket(ticketId: widget.ticket!.id);
            _scrollToBottom();
          },
        );
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
    /* Sambungan peristiwa harus ditutup saat layar ditinggalkan. Tanpa ini,
         sambungan tetap hidup di latar belakang dan terus memakai baterai
         serta kuota. */
    if (widget.ticket != null) {
      _supportController?.berhentiDengarkanTiket(widget.ticket!.id);
    }

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

  /// Tiket yang sudah selesai/ditutup bersifat read-only.
  ///
  /// Server menolak pesan ke tiket final, jadi menampilkan kolom ketik hanya akan
  /// membuat pelanggan menulis pesan yang pasti gagal terkirim. Status diambil
  /// dari versi terbaru di controller (hasil muat ulang dari server), bukan dari
  /// objek yang dibawa saat layar dibuka — admin bisa menutup tiket kapan saja.
  SupportTicketModel? get _ticketFinal {
    final dasar = widget.ticket;
    if (dasar == null) return null;

    final support = _supportController ?? context.read<SupportController>();
    final terbaru = support.findTicket(dasar.id) ?? _withStatus(dasar, support.statusOf(dasar.id));
    return terbaru.isFinished ? terbaru : null;
  }

  /// Menempelkan status hasil muat ulang server ke tiket yang dibawa layar.
  static SupportTicketModel _withStatus(SupportTicketModel ticket, String? status) {
    if (status == null || status == ticket.status) return ticket;
    return ticket.copyWith(status: status);
  }

  void _handleSendMessage(SupportController controller) {
    if (_ticketFinal != null) return;

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    controller.sendUserMessage(text: text, conversationKey: conversationKey);
    _messageController.clear();
    _scrollToBottom();
  }

  void _openCreateTicket() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTicketScreen()));
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

    // activeTicket hanya ada jika layar ini memang dibuka untuk tiket keluhan tertentu
    final activeTicket = widget.ticket;

    /* Status tiket terbaru dari controller: admin bisa menutup tiket setelah
       layar ini terbuka, dan composer harus ikut terkunci tanpa perlu restart. */
    final liveTicket = activeTicket == null
        ? null
        : (support.findTicket(activeTicket.id) ??
              _withStatus(activeTicket, support.statusOf(activeTicket.id)));
    final isTicketFinal = liveTicket?.isFinished ?? false;

    // Ambil daftar pesan dan status handoff terisolasi untuk sesi saat ini
    final messages = support.getMessages(conversationKey);
    final isHandedOff =
        support.isAiHandoffToAdminFor(conversationKey) || (activeTicket?.isHandledByHuman ?? false);

    // Rekomendasi pesan cepat sesuai konteks sesi
    final List<String> suggestions;
    if (currentBooking != null) {
      if (currentBooking.status == BookingStatus.menungguPembayaran) {
        suggestions = ['No. Rekening Bank BRI', 'Lokasi jemput Bandara Mopah'];
      } else {
        suggestions = [
          'Lokasi jemput Bandara Mopah',
          'Konfirmasi armada siap',
          'Perpanjang durasi sewa',
          'Pertanyaan seputar BBM',
        ];
      }
    } else if (activeTicket != null) {
      /* Saran hanya untuk hal yang benar-benar bisa dijawab tiket ini. Opsi
         "Hubungkan ke staf operasional" dibuang dari sini: penawaran berbicara
         dengan staf akan datang dari AI saat percakapan tidak berprogress, dan
         menaruhnya permanen di layar membuatnya jadi tombol pelarian. */
      suggestions = ['Cek status penanganan', 'Ubah jadwal penjemputan'];
    } else {
      suggestions = ['Lokasi jemput Bandara Mopah', 'Verifikasi KTP & SIM A', 'Tarif sewa & supir'];
    }

    /* Judul header adalah judul tiket, bukan nomor tiket.
       Nomor tiket tidak memberi tahu apa pun tentang isi percakapan, sementara
       judul tiket justru satu-satunya pengingat konteks saat pelanggan punya
       beberapa tiket. Nomornya tetap tersedia di daftar riwayat bantuan. */
    final String screenTitle;
    final String screenSubtitle;

    if (currentBooking != null) {
      screenTitle = currentBooking.vehicle.name;
      screenSubtitle = isHandedOff
          ? 'Staf Operasional Merauke · online'
          : 'Asisten AI MobilJuragan · membalas otomatis';
    } else if (activeTicket != null) {
      screenTitle = (liveTicket ?? activeTicket).title;
      if (isTicketFinal) {
        /* Satu kata untuk satu keadaan. Server punya dua status akhir
           (RESOLVED lalu CLOSED), tetapi bagi pelanggan keduanya sama. */
        screenSubtitle = 'Tiket selesai · riwayat tersimpan';
      } else {
        screenSubtitle = isHandedOff
            ? 'Staf Operasional Merauke · online'
            : 'Asisten AI MobilJuragan · membalas otomatis';
      }
    } else {
      screenTitle = 'Bantuan MobilJuragan';
      screenSubtitle = isHandedOff
          ? 'Staf Operasional Merauke · online'
          : 'Asisten AI MobilJuragan · membalas otomatis';
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
        titleSpacing: 0,
        title: Row(
          children: [
            /* Avatar lawan bicara: penanda "sedang chat dengan siapa" yang lazim
               di aplikasi pesan. Sebelumnya peran ini dipegang badge di kanan
               sekaligus subjudul, jadi satu informasi ditulis dua kali. */
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isTicketFinal
                    ? const Color(0xFF334155)
                    : (isHandedOff ? const Color(0xFF065F46) : const Color(0xFF1E4B63)),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isTicketFinal
                      ? Icons.lock_outline_rounded
                      : (isHandedOff ? Icons.support_agent_rounded : Icons.smart_toy_outlined),
                  size: 18,
                  color: isHandedOff || isTicketFinal
                      ? AppColors.textWhite
                      : const Color(0xFF7DD3FC),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
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
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isTicketFinal
                              ? const Color(0xFF94A3B8)
                              : (isHandedOff ? const Color(0xFF22C55E) : const Color(0xFF38BDF8)),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          screenSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: AppTypography.sizeCaption,
                            color: Color(0xFFCBD5E1),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // Banner Tiket Bantuan HANYA muncul jika layar ini dibuka untuk tiket keluhan
          if (activeTicket != null) _buildTicketSummaryBanner(liveTicket ?? activeTicket),

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
              itemCount: messages.length + (support.isAiThinking(conversationKey) ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length) {
                  return _buildAiThinkingIndicator(maxBubbleWidth);
                }
                final msg = messages[index];

                /* Pengelompokan ala aplikasi pesan: nama pengirim dan avatar
                   hanya muncul pada pesan pertama rangkaian berurutan, dan sudut
                   bubble menyesuaikan posisi di dalam rangkaian. */
                final sebelum = index > 0 ? messages[index - 1] : null;
                final sesudah = index + 1 < messages.length ? messages[index + 1] : null;

                return _buildMessageItem(
                  msg,
                  maxBubbleWidth,
                  tampilkanKepala: !_sameSender(sebelum, msg),
                  ekorRapat: _sameSender(msg, sesudah),
                );
              },
            ),
          ),

          // Panel Bawah Terpadu (Saran Cepat + Input Pesan)
          _buildUnifiedBottomArea(
            suggestions: isTicketFinal ? const [] : suggestions,
            support: support,
            booking: currentBooking,
            bookingCtrl: bookingCtrl,
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
              onPressed: () async {
                /* Laporan diteruskan ke staf, bukan langsung melunasi pesanan.
                   Status pembayaran hanya berubah setelah admin memeriksa bukti
                   transfer di portal. */
                await support.confirmPaymentFromChat(booking: booking);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: support.pesanBelumTerkirim
                        ? const Color(0xFFB91C1C)
                        : const Color(0xFF15803D),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    content: Text(
                      support.pesanBelumTerkirim
                          ? 'Laporan belum terkirim. Periksa koneksi lalu coba lagi.'
                          : 'Laporan sudah dikirim. Staf akan memeriksa pembayaran Anda.',
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
              child: const Text('Sudah Bayar', style: AppTypography.captionBold),
            ),
          ],
        ],
      ),
    );
  }

  /// Keterangan konteks tiket di atas percakapan.
  ///
  /// Isinya hanya yang tidak terbaca dari layar lain: kategori dan status.
  /// Judul tiket sudah menjadi judul header, jadi mengulangnya di sini membuat
  /// satu layar menampilkan hal yang sama dua kali.
  Widget _buildTicketSummaryBanner(SupportTicketModel ticket) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle, width: 1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.label_outline_rounded, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${ticket.categoryLabel} · ${ticket.status}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: AppTypography.sizeCaption,
                color: AppColors.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiThinkingIndicator(double maxBubbleWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(color: AppColors.tealLight, shape: BoxShape.circle),
            child: const Center(
              child: Icon(Icons.smart_toy_outlined, size: 14, color: AppColors.primaryTeal),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: AppColors.borderSubtle, width: 1),
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
                  'Sedang menulis...',
                  style: TextStyle(
                    fontSize: AppTypography.sizeBody,
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

  /// Dua pesan dianggap satu rangkaian bila datang dari pihak yang sama dan
  /// tidak dipisahkan penanda sistem.
  bool _sameSender(ChatMessageModel? a, ChatMessageModel? b) {
    if (a == null || b == null) return false;
    if (a.senderName == 'Sistem' || b.senderName == 'Sistem') return false;
    return a.isFromUser == b.isFromUser && a.isAI == b.isAI && a.senderName == b.senderName;
  }

  Widget _buildMessageItem(
    ChatMessageModel msg,
    double maxBubbleWidth, {
    required bool tampilkanKepala,
    required bool ekorRapat,
  }) {
    final isUser = msg.isFromUser;

    if (msg.senderName == 'Sistem') {
      return _buildSystemNotice(msg);
    }

    final jam =
        '${msg.timestamp.hour.toString().padLeft(2, '0')}.'
        '${msg.timestamp.minute.toString().padLeft(2, '0')}';

    /* Sudut bubble: sisi dekat pengirim mengecil saat pesan menyambung, supaya
       rangkaian terbaca sebagai satu blok, bukan tumpukan kotak terpisah. */
    final radius = BorderRadius.only(
      topLeft: Radius.circular(isUser ? 16 : (tampilkanKepala ? 16 : 4)),
      topRight: Radius.circular(isUser ? (tampilkanKepala ? 16 : 4) : 16),
      bottomLeft: Radius.circular(isUser ? 16 : (ekorRapat ? 4 : 16)),
      bottomRight: Radius.circular(isUser ? (ekorRapat ? 4 : 16) : 16),
    );

    final warnaLatar = isUser
        ? AppColors.primaryNavy
        : (msg.isAI ? const Color(0xFFF1F5F9) : const Color(0xFFF0FDF4));
    final warnaGaris = isUser
        ? AppColors.primaryNavy
        : (msg.isAI ? AppColors.borderSubtle : const Color(0xFFBBF7D0));

    return Padding(
      padding: EdgeInsets.only(top: tampilkanKepala ? 10 : 2, bottom: ekorRapat ? 0 : 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          /* Kolom avatar selebar tetap: pesan lanjutan tetap sejajar walau
             avatarnya tidak digambar. */
          if (!isUser) ...[
            SizedBox(
              width: 24,
              height: 24,
              child: tampilkanKepala
                  ? Container(
                      decoration: BoxDecoration(
                        color: msg.isAI ? AppColors.tealLight : const Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          msg.isAI ? Icons.smart_toy_outlined : Icons.support_agent_rounded,
                          size: 14,
                          color: msg.isAI ? AppColors.primaryTeal : const Color(0xFF15803D),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (tampilkanKepala && !isUser)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 2),
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
                Container(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  padding: const EdgeInsets.fromLTRB(12, 9, 12, 7),
                  decoration: BoxDecoration(
                    color: warnaLatar,
                    borderRadius: radius,
                    border: Border.all(color: warnaGaris),
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
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
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
                            jam,
                            style: TextStyle(
                              fontSize: AppTypography.sizeMicro,
                              color: isUser
                                  ? AppColors.textWhite.withValues(alpha: 0.65)
                                  : AppColors.textMuted,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
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

  /// Penanda sistem (tiket dibuat, ditutup, dialihkan) tampil di tengah sebagai
  /// keterangan, bukan sebagai gelembung percakapan — tidak ada yang mengirimnya.
  Widget _buildSystemNotice(ChatMessageModel msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            msg.message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: AppTypography.sizeCaption,
              height: 1.35,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
        ),
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
                onPressed: () async {
                  if (suggestion == 'Konfirmasi Sudah Bayar' && booking != null) {
                    await controller.confirmPaymentFromChat(booking: booking);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: controller.pesanBelumTerkirim
                            ? const Color(0xFFB91C1C)
                            : const Color(0xFF15803D),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        content: Text(
                          controller.pesanBelumTerkirim
                              ? 'Laporan belum terkirim. Periksa koneksi lalu coba lagi.'
                              : 'Laporan sudah dikirim. Staf akan memeriksa pembayaran Anda.',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: AppTypography.sizeBody,
                          ),
                        ),
                      ),
                    );
                  } else {
                    controller.sendUserMessage(text: suggestion, conversationKey: conversationKey);
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

  Widget _buildComposerBar(SupportController controller) {
    final isHandedOff =
        controller.isAiHandoffToAdminFor(conversationKey) ||
        (widget.ticket?.isHandledByHuman ?? false);

    final finalTicket = _ticketFinal;
    if (finalTicket != null) {
      return _buildClosedComposer(finalTicket);
    }

    final adaTeks = _messageController.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.multiline,
              /* Enter mengirim, seperti aplikasi pesan pada umumnya. Di layar
                 sentuh, baris baru tetap bisa lewat tombol enter di keyboard
                 fisik dengan Shift. */
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSendMessage(controller),
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                fontSize: AppTypography.sizeBodyLarge,
                height: 1.4,
                fontFamily: 'Inter',
              ),
              decoration: InputDecoration(
                hintText: isHandedOff ? 'Tulis pesan untuk staf operasional' : 'Tulis pesan',
                hintStyle: const TextStyle(
                  fontSize: AppTypography.sizeBodyLarge,
                  color: AppColors.textMuted,
                  fontFamily: 'Inter',
                ),
                filled: true,
                fillColor: AppColors.surfaceLight,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          /* Tombol kirim hanya menyala saat ada isi. Sebelumnya selalu menyala
             dan menekannya tanpa teks tidak melakukan apa pun. */
          SizedBox(
            width: 44,
            height: 44,
            child: Material(
              color: adaTeks ? AppColors.primaryNavy : AppColors.surfaceLight,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: adaTeks ? () => _handleSendMessage(controller) : null,
                child: Icon(
                  Icons.send_rounded,
                  size: 19,
                  color: adaTeks ? AppColors.textWhite : AppColors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pengganti composer saat tiket sudah selesai: riwayat tetap terbaca,
  /// tapi tidak ada kolom ketik yang pasti ditolak server.
  Widget _buildClosedComposer(SupportTicketModel ticket) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Tiket sudah selesai',
                    style: const TextStyle(
                      fontSize: AppTypography.sizeCaption,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Riwayat percakapan tetap bisa dibaca. Untuk kendala baru, buat tiket baru.',
              style: TextStyle(
                fontSize: AppTypography.sizeTiny,
                color: AppColors.textSecondary,
                fontFamily: 'Inter',
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: _openCreateTicket,
                icon: const Icon(Icons.add_comment_outlined, size: 16),
                label: const Text(
                  'Buat Tiket Baru',
                  style: TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
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
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(top: BorderSide(color: AppColors.borderSubtle, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /* Saran cepat hanya berguna kalau pesan masih bisa dikirim. */
            if (_ticketFinal == null && suggestions.isNotEmpty)
              _buildQuickSuggestionsBar(suggestions, support, booking, bookingCtrl),
            _buildComposerBar(support),
          ],
        ),
      ),
    );
  }
}
