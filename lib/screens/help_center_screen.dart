import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/support_controller.dart';
import '../models/faq_model.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import 'chat_support_screen.dart';
import 'create_ticket_screen.dart';
import 'ticket_history_screen.dart';
import '../theme/app_typography.dart';

/// Halaman Pusat Bantuan Pelanggan dan Layanan Operasional Merauke (Frame 09)
class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  String _selectedCategory = 'Semua';
  int? _expandedFaqIndex;
  Timer? _ticketsPollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final support = context.read<SupportController>();
        support.fetchFaqs();
        support.fetchTickets();
      }
    });

    // Polling periodik 5 detik agar perubahan status tiket di dashboard otomatis tersinkron
    _ticketsPollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        context.read<SupportController>().fetchTickets();
      }
    });
  }

  @override
  void dispose() {
    _ticketsPollingTimer?.cancel();
    super.dispose();
  }

  List<FaqModel> _filterFaqs(List<FaqModel> allFaqs) {
    return allFaqs.where((faq) {
      return _selectedCategory == 'Semua' || faq.category == _selectedCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final support = context.watch<SupportController>();
    final categories = support.faqCategories;
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = 'Semua';
    }
    final faqs = _filterFaqs(support.faqs);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const CustomAppBar(
        title: 'MobilJuragan',
        stepSubtitle: 'Pusat Bantuan Merauke',
        showBackButton: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final supportCtrl = context.read<SupportController>();
            await Future.wait([
              supportCtrl.fetchFaqs(force: true),
              supportCtrl.fetchTickets(force: true),
            ]);
          },
          color: AppColors.primaryNavy,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                const Text(
                  'Pusat Bantuan',
                  style: TextStyle(
                    fontSize: AppTypography.sizeDisplay,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Solusi kendala sewa armada dan layanan operasional Merauke.',
                  style: TextStyle(
                    fontSize: AppTypography.sizeBodyLarge,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 18),

                // Seksi 1: Pertanyaan Populer (FAQ)
                _buildFaqSection(faqs, categories),
                const SizedBox(height: 24),

              // Seksi 2: Tiket Bantuan Saya
              _buildUserTicketsSection(support),
              const SizedBox(height: 24),

              // Seksi 3: Saluran Bantuan
              _buildSupportChannelsSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildCategoryChips(List<String> categories) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                cat,
                style: TextStyle(
                  fontSize: AppTypography.sizeCaption,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primaryNavy,
              backgroundColor: AppColors.cardWhite,
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
                    _expandedFaqIndex = null;
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
                  'Setiap tiket bantuan dijawab otomatis oleh asisten virtual dan dapat dialihkan ke staf operasional Merauke.',
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Buat Tiket Bantuan',
                        style: TextStyle(
                          fontSize: AppTypography.sizeBodyLarge,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Text(
                          'Respon AI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D4ED8),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  const Text(
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

  Widget _buildFaqSection(List<FaqModel> faqs, List<String> categories) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
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
          if (faqs.isEmpty) ...[
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Belum ada topik bantuan untuk kategori ini. Silakan hubungi CS langsung.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: AppTypography.sizeBody, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 10),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: faqs.length,
              separatorBuilder: (_, _) => const Divider(color: AppColors.borderSubtle, height: 1),
              itemBuilder: (context, index) {
                final faq = faqs[index];
                final isExpanded = _expandedFaqIndex == index;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _expandedFaqIndex = isExpanded ? null : index;
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
                                  fontWeight: isExpanded ? FontWeight.w700 : FontWeight.w500,
                                  color: isExpanded ? AppColors.primaryNavy : AppColors.textPrimary,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                            Icon(
                              isExpanded ? Icons.expand_less : Icons.expand_more,
                              color: isExpanded ? AppColors.primaryNavy : AppColors.textSecondary,
                              size: 20,
                            ),
                          ],
                        ),
                        if (isExpanded) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              faq.answer,
                              style: const TextStyle(
                                fontSize: AppTypography.sizeCaption,
                                height: 1.45,
                                color: AppColors.textPrimary,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserTicketsSection(SupportController support) {
    final activeTickets = support.tickets.where((t) => !t.isFinished).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
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
                if (activeTickets.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${activeTickets.length} Berjalan',
                      style: const TextStyle(
                        fontSize: AppTypography.sizeTiny,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB45309),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ],
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TicketHistoryScreen()),
                ).then((_) {
                  if (mounted) {
                    context.read<SupportController>().fetchTickets();
                  }
                });
              },
              child: const Text(
                'Riwayat Tiket ›',
                style: TextStyle(
                  fontSize: AppTypography.sizeBody,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryTeal,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
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
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activeTickets.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final ticket = activeTickets[index];
              return InkWell(
                onTap: () {
                  Navigator.of(context)
                      .push(
                    MaterialPageRoute(
                      builder: (_) => ChatSupportScreen(ticket: ticket),
                    ),
                  )
                      .then((_) {
                    if (context.mounted) {
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
                            Text(
                              'Aktif • ${ticket.status}',
                              style: const TextStyle(
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
                            const SizedBox(height: 2),
                            Text(
                              'ID: ${ticket.displayTicketNumber} • ${ticket.categoryLabel}',
                              style: const TextStyle(
                                fontSize: AppTypography.sizeTiny,
                                color: AppColors.textSecondary,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

