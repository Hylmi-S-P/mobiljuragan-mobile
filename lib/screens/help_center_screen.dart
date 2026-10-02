import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/support_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import 'chat_support_screen.dart';
import 'create_ticket_screen.dart';

/// Halaman Pusat Bantuan Pelanggan dan Layanan Operasional Merauke (Frame 09)
class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';
  int? _expandedFaqIndex;

  final List<String> _categories = [
    'Semua',
    'Booking & Sewa',
    'Pembayaran',
    'Armada',
  ];

  final List<Map<String, String>> _allFaqs = [
    {
      'category': 'Booking & Sewa',
      'question': 'Bagaimana prosedur penjemputan di Bandara Mopah Merauke?',
      'answer': 'Tim operasional kami akan menunggu di lobi kedatangan Bandara Mopah dengan papan nama penyewa atau menghubungi via WhatsApp 30 menit sebelum jadwal pesawat mendarat. Serah terima unit dilakukan langsung di area parkir bandara tanpa biaya tambahan antar-jemput.',
    },
    {
      'category': 'Booking & Sewa',
      'question': 'Bagaimana verifikasi dokumen KTP dan SIM A untuk lepas kunci?',
      'answer': 'Verifikasi dokumen fisik asli (KTP elektronik dan SIM A aktif) dilakukan langsung di kantor operasional MobilJuragan atau saat serah terima unit di titik penjemputan Merauke.',
    },
    {
      'category': 'Armada',
      'question': 'Bagaimana kebijakan bahan bakar (BBM) armada?',
      'answer': 'Mobil diserahterimakan dengan indikator BBM tertentu (umumnya terisi minimal setengah bar). Penyewa diharapkan mengembalikan unit dengan posisi BBM setara saat serah terima awal.',
    },
    {
      'category': 'Booking & Sewa',
      'question': 'Berapa tarif jasa pengemudi dan durasi kerjanya?',
      'answer': 'Jasa pengemudi lokal Merauke bertarif Rp 150.000 per hari dengan durasi pemakaian normal hingga 12 jam per hari dalam wilayah perkotaan Merauke dan sekitarnya.',
    },
    {
      'category': 'Pembayaran',
      'question': 'Metode pembayaran apa saja yang berlaku?',
      'answer': 'Pembayaran dilakukan melalui transfer rekening bank resmi (BRI / Mandiri) setelah admin mengonfirmasi rincian tarif final. Rincian tagihan dan konfirmasi pembayaran dikirimkan langsung oleh bot melalui Chat CS.',
    },
    {
      'category': 'Armada',
      'question': 'Apakah tersedia layanan darurat jika terjadi kendala armada di jalan?',
      'answer': 'Ya, MobilJuragan menyediakan layanan darurat 24 jam untuk wilayah Merauke Kota, Kurik, Tanah Miring, hingga Semangga. Hubungi nomor darurat operasional kami jika membutuhkan penanganan mekanik.',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filteredFaqs {
    final query = _searchController.text.toLowerCase().trim();
    return _allFaqs.where((faq) {
      final matchesCategory = _selectedCategory == 'Semua' || faq['category'] == _selectedCategory;
      final matchesQuery = query.isEmpty ||
          faq['question']!.toLowerCase().contains(query) ||
          faq['answer']!.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final support = context.watch<SupportController>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const CustomAppBar(
        title: 'MobilJuragan',
        stepSubtitle: 'Pusat Bantuan Merauke',
        showBackButton: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              const Text(
                'Pusat Bantuan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Cari solusi cepat atau hubungi layanan bantuan rental.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 16),

              // Search Bar FAQ
              _buildSearchBar(),
              const SizedBox(height: 14),

              // Filter Chips Kategori
              _buildCategoryChips(),
              const SizedBox(height: 20),

              // 3 Tombol Pintas / Action Cards
              _buildActionCards(),
              const SizedBox(height: 24),

              // Accordion FAQ Populer
              _buildFaqSection(),
              const SizedBox(height: 24),

              // Tiket Bantuan Saya (Jika ada tiket)
              _buildUserTicketsSection(support),
              const SizedBox(height: 24),

              // Tombol Utama Buat Tiket Bantuan
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CreateTicketScreen()),
                    );
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text(
                    'Buat Ticket Bantuan Baru',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: AppColors.textWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
        decoration: InputDecoration(
          hintText: 'Cari topik bantuan atau kata kunci...',
          hintStyle: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontFamily: 'Inter',
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                cat,
                style: TextStyle(
                  fontSize: 11,
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
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionCards() {
    return Row(
      children: [
        // Action 1: Live Chat
        Expanded(
          child: _buildActionCardItem(
            icon: Icons.chat_bubble_outline,
            label: 'Chat Bantuan',
            subtitle: 'AI & Staf Lapangan',
            color: AppColors.primaryNavy,
            bgColor: const Color(0xFFEFF6FF),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChatSupportScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),

        // Action 2: Buat Tiket
        Expanded(
          child: _buildActionCardItem(
            icon: Icons.confirmation_number_outlined,
            label: 'Buat Tiket',
            subtitle: 'Lapor Kendala Sewa',
            color: AppColors.primaryTeal,
            bgColor: AppColors.tealLight,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateTicketScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCardItem({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(icon, color: color, size: 20),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqSection() {
    final faqs = _filteredFaqs;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pertanyaan Populer',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                '${faqs.length} Topik',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryTeal,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderSubtle, height: 1),
          if (faqs.isEmpty) ...[
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Topik bantuan tidak ditemukan. Coba kata kunci lain atau hubungi CS langsung.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                                faq['question']!,
                                style: TextStyle(
                                  fontSize: 12,
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
                              faq['answer']!,
                              style: const TextStyle(
                                fontSize: 11,
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
    if (support.tickets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ticket Bantuan Saya',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChatSupportScreen()),
                );
              },
              child: const Text(
                'Lihat Chat ›',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryTeal,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: support.tickets.length > 2 ? 2 : support.tickets.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final ticket = support.tickets[index];
            return InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatSupportScreen(ticket: ticket),
                  ),
                );
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
                        color: ticket.status == 'Selesai'
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ticket.status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: ticket.status == 'Selesai'
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB45309),
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
                          const SizedBox(height: 2),
                          Text(
                            'ID: ${ticket.id} • ${ticket.categoryLabel}',
                            style: const TextStyle(
                              fontSize: 10,
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

