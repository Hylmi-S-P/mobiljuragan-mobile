import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/support_controller.dart';
import '../models/faq_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/daftar_geser_horizontal.dart';
import '../widgets/login_required_sheet.dart';
import 'chat_support_screen.dart';
import 'create_ticket_screen.dart';
import 'ticket_history_screen.dart';
import '../theme/app_typography.dart';

/// Halaman Pusat Bantuan Pelanggan dan Layanan Operasional Merauke (Frame 09)
class HelpCenterScreen extends StatefulWidget {
  final bool showBackButton;
  final bool isActive;

  const HelpCenterScreen({
    super.key,
    this.showBackButton = false,
    this.isActive = true,
  });

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen>
    with WidgetsBindingObserver {
  String _selectedCategory = 'Semua';
  String? _expandedFaqId;
  Timer? _ticketsPollingTimer;
  bool _sedangDiDepan = true;
  final PageController _activeTicketPageController = PageController();
  int _activeTicketPage = 0;

  /*
   * Daftar tiket disegarkan berkala sebagai jaring pengaman, bukan sebagai
   * sumber utama. Perubahan status yang penting sudah datang lewat SSE
   * saat percakapan dibuka, dan pelanggan bisa menarik daftar untuk menyegarkan
   * sendiri. Menyegarkan hanya berjalan saat tab aktif dan aplikasi di depan.
   */
  static const Duration _jedaSegarkanTiket = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final support = context.read<SupportController>();
      support.fetchFaqs();
      if (widget.isActive && context.read<AuthController>().isLoggedIn) {
        support.fetchTickets();
      }
    });

    if (widget.isActive) {
      _mulaiSegarkanTiket();
    }
  }

  @override
  void didUpdateWidget(covariant HelpCenterScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      if (mounted && context.read<AuthController>().isLoggedIn) {
        context.read<SupportController>().fetchTickets();
      }
      if (_sedangDiDepan) {
        _mulaiSegarkanTiket();
      }
    } else if (oldWidget.isActive && !widget.isActive) {
      _hentikanSegarkanTiket();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hentikanSegarkanTiket();
    _activeTicketPageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    /*
     * Aplikasi di latar belakang tidak perlu menyegarkan apa pun: tidak ada
     * yang melihat daftarnya, dan Android tetap membatasi jaringan di sana.
     * Saat kembali ke depan, daftar disegarkan sekali lalu jadwal dilanjutkan.
     */
    if (state == AppLifecycleState.resumed) {
      _sedangDiDepan = true;
      if (widget.isActive) {
        if (mounted && context.read<AuthController>().isLoggedIn) {
          context.read<SupportController>().fetchTickets();
        }
        _mulaiSegarkanTiket();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _sedangDiDepan = false;
      _hentikanSegarkanTiket();
    }
  }

  void _mulaiSegarkanTiket() {
    _hentikanSegarkanTiket();
    if (!widget.isActive || !_sedangDiDepan) return;
    _ticketsPollingTimer = Timer.periodic(_jedaSegarkanTiket, (_) {
      if (!mounted || !widget.isActive || !_sedangDiDepan) return;
      if (context.read<AuthController>().isLoggedIn) {
        context.read<SupportController>().fetchTickets();
      }
    });
  }

  void _hentikanSegarkanTiket() {
    _ticketsPollingTimer?.cancel();
    _ticketsPollingTimer = null;
  }

  List<FaqModel> _filterFaqs(List<FaqModel> allFaqs) {
    return allFaqs.where((faq) {
      return _selectedCategory == 'Semua' || faq.category == _selectedCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthController>().isLoggedIn;
    final support = context.watch<SupportController>();
    final categories = support.faqCategories;
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = 'Semua';
    }
    final faqs = _filterFaqs(support.faqs);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: CustomAppBar(
        title: 'Pusat Bantuan',
        stepSubtitle: 'Merauke • Layanan 24 jam',
        showBackButton: widget.showBackButton,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final supportCtrl = context.read<SupportController>();
            final loggedIn = context.read<AuthController>().isLoggedIn;
            await Future.wait([
              supportCtrl.fetchFaqs(force: true),
              if (loggedIn) supportCtrl.fetchTickets(force: true),
            ]);
          },
          color: AppColors.primaryNavy,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  16,
                  AppSpacing.screenH,
                  0,
                ),
                sliver: const SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Solusi kendala sewa armada dan layanan operasional Merauke.',
                        style: TextStyle(
                          fontSize: AppTypography.sizeBodyLarge,
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                sliver: _buildFaqSliver(faqs, categories),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  24,
                  AppSpacing.screenH,
                  20,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isLoggedIn) ...[
                        _buildUserTicketsSection(support),
                        const SizedBox(height: 24),
                      ],
                      _buildSupportChannelsSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(List<String> categories) {
    return DaftarGeserHorizontal(
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: EdgeInsets.only(right: cat == categories.last ? 0 : 8),
            child: ChoiceChip(
              label: Text(
                cat,
                style: TextStyle(
                  fontSize: AppTypography.sizeCaption,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.textWhite
                      : AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primaryNavy,
              backgroundColor: AppColors.cardWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primaryNavy
                      : AppColors.borderSubtle,
                ),
              ),
              showCheckmark: false,
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _selectedCategory = cat;
                    _expandedFaqId = null;
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSupportChannelsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hubungi Layanan Bantuan',
          style: TextStyle(
            fontSize: AppTypography.sizeTitle,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 10),
        _buildActionCards(),
        const SizedBox(height: 12),
        _buildCsInfoBanner(),
      ],
    );
  }

  Widget _buildCsInfoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.tealLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(
                Icons.support_agent_rounded,
                size: 20,
                color: AppColors.primaryTeal,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Layanan Bantuan Terpadu',
                  style: TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Sampaikan kendala Anda melalui tiket bantuan untuk ditangani asisten virtual atau admin operasional Merauke.',
                  style: TextStyle(
                    fontSize: AppTypography.sizeTiny,
                    height: 1.35,
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

  Widget _buildActionCards() {
    return InkWell(
      onTap: () {
        if (!context.read<AuthController>().isLoggedIn) {
          showLoginRequiredSheet(
            context: context,
            subtitle: 'Diperlukan untuk membuat tiket bantuan',
            description:
                'Masuk atau buat akun terlebih dahulu agar admin operasional dan asisten virtual dapat menindaklanjuti kendala Anda serta menyimpan riwayat percakapan.',
            onAuthenticated: () {
              if (!mounted) return;
              context.read<SupportController>().fetchTickets();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateTicketScreen()),
              );
            },
          );
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateTicketScreen()),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.tealLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(
                  Icons.assignment_late_outlined,
                  color: AppColors.primaryTeal,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buat Tiket Bantuan',
                    style: TextStyle(
                      fontSize: AppTypography.sizeBodyLarge,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Sampaikan pertanyaan atau kendala sewa armada untuk ditangani',
                    style: TextStyle(
                      fontSize: AppTypography.sizeCaption,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqSliver(List<FaqModel> faqs, List<String> categories) {
    return DecoratedSliver(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      sliver: SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wrap: jumlah topik turun ke baris berikutnya saat ukuran teks
                  // sistem diperbesar, bukan meluber ke kanan.
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      const Text(
                        'Pertanyaan Populer',
                        style: TextStyle(
                          fontSize: AppTypography.sizeTitle,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      Text(
                        '${faqs.length} Topik',
                        style: const TextStyle(
                          fontSize: AppTypography.sizeCaption,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryTeal,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryChips(categories),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.borderSubtle, height: 1),
                ],
              ),
            ),
            if (faqs.isEmpty)
              const SliverToBoxAdapter(
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Belum ada topik bantuan untuk kategori ini. Silakan hubungi CS langsung.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: AppTypography.sizeBody,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              )
            else
              SliverList.builder(
                itemCount: faqs.length,
                itemBuilder: (context, index) {
                  final faq = faqs[index];
                  final faqKey = faq.id.isNotEmpty ? faq.id : faq.question;
                  final isExpanded = _expandedFaqId == faqKey;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (index > 0)
                        const Divider(color: AppColors.borderSubtle, height: 1),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _expandedFaqId = isExpanded ? null : faqKey;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      faq.question,
                                      style: TextStyle(
                                        fontSize: AppTypography.sizeBody,
                                        fontWeight: isExpanded
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isExpanded
                                            ? AppColors.primaryNavy
                                            : AppColors.textPrimary,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    isExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    color: isExpanded
                                        ? AppColors.primaryNavy
                                        : AppColors.textSecondary,
                                    size: 20,
                                  ),
                                ],
                              ),
                              if (isExpanded) ...[
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 2,
                                    right: 8,
                                  ),
                                  child: Text(
                                    faq.answer,
                                    style: const TextStyle(
                                      fontSize: AppTypography.sizeBody,
                                      height: 1.45,
                                      color: AppColors.textSecondary,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTicketsSection(SupportController support) {
    /* Hanya tiket yang masih menerima pesan. Sejak wave 09 server menolak pesan
       pada tiket RESOLVED maupun CLOSED, jadi keduanya tidak boleh muncul di sini:
       menampilkannya sebagai "aktif" hanya menjanjikan percakapan yang sudah
       mati. Keduanya pindah ke Riwayat Tiket. */
    final activeTickets = support.tickets
        .where((t) => !t.isFinished && (t.bookingId == null || t.bookingId!.isEmpty))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  const Text(
                    'Tiket Bantuan Saya',
                    style: TextStyle(
                      fontSize: AppTypography.sizeTitle,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  if (activeTickets.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.statusWarningBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${activeTickets.length} Berjalan',
                        style: const TextStyle(
                          fontSize: AppTypography.sizeTiny,
                          fontWeight: FontWeight.w700,
                          color: AppColors.statusWarningFg,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) => const TicketHistoryScreen(),
                        ),
                      )
                      .then((_) {
                        if (mounted) {
                          context.read<SupportController>().fetchTickets();
                        }
                      });
                },
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Text(
                    'Riwayat Tiket Selesai ›',
                    style: TextStyle(
                      fontSize: AppTypography.sizeBody,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryTeal,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        if (activeTickets.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: Color(0xFF16A34A),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tidak ada kendala aktif. Armada Anda berjalan normal.',
                    style: TextStyle(
                      fontSize: AppTypography.sizeCaption,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          _buildPaginatedActiveTickets(activeTickets),
      ],
    );
  }

  Widget _buildPaginatedActiveTickets(List<dynamic> activeTickets) {
    const int pageSize = 3;
    final int totalPages = (activeTickets.length / pageSize).ceil();
    final int safePage = _activeTicketPage.clamp(0, totalPages - 1);

    if (totalPages <= 1) {
      return Column(
        children: [
          for (int i = 0; i < activeTickets.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _buildActiveTicketCard(activeTickets[i]),
          ],
        ],
      );
    }

    final textScale = (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1.0, 2.0);
    final hasAnyBookingCode = activeTickets.any((t) => t.bookingCode != null);
    final itemSlotHeight = (hasAnyBookingCode ? 54.0 : 34.0) * textScale + 30.0;
    final pageHeight = (itemSlotHeight * pageSize) + ((pageSize - 1) * 8.0);

    return Column(
      children: [
        SizedBox(
          height: pageHeight,
          child: PageView.builder(
            controller: _activeTicketPageController,
            itemCount: totalPages,
            onPageChanged: (page) {
              if (mounted) {
                setState(() => _activeTicketPage = page);
              }
            },
            itemBuilder: (context, pageIndex) {
              final start = pageIndex * pageSize;
              final end = (start + pageSize).clamp(0, activeTickets.length);
              final pageTickets = activeTickets.sublist(start, end);
              return SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < pageTickets.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      _buildActiveTicketCard(pageTickets[i]),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalPages, (pageIdx) {
            final isSelected = pageIdx == safePage;
            return InkWell(
              onTap: () {
                _activeTicketPageController.animateToPage(
                  pageIdx,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                );
              },
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryNavy
                        : AppColors.borderMedium,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildActiveTicketCard(dynamic ticket) {
    return InkWell(
      onTap: () {
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (_) => ChatSupportScreen(ticket: ticket),
              ),
            )
            .then((_) {
              if (mounted) {
                context.read<SupportController>().fetchTickets();
              }
            });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD97706),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Aktif',
                    style: TextStyle(
                      fontSize: AppTypography.sizeTiny,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB45309),
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
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
                  if (ticket.bookingCode != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Pesanan ${ticket.bookingCode}',
                      style: const TextStyle(
                        fontSize: AppTypography.sizeTiny,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryTeal,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

