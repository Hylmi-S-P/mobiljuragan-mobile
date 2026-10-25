import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/support_controller.dart';
import '../models/support_ticket_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/custom_app_bar.dart';
import 'chat_support_screen.dart';

/// Layar Arsip dan Riwayat Tiket Bantuan Pelanggan
class TicketHistoryScreen extends StatefulWidget {
  const TicketHistoryScreen({super.key});

  @override
  State<TicketHistoryScreen> createState() => _TicketHistoryScreenState();
}

class _TicketHistoryScreenState extends State<TicketHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SupportController>().fetchTickets();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final support = context.watch<SupportController>();
    final historyTickets = support.tickets.where((t) => t.isFinished).toList();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const CustomAppBar(
        title: 'Riwayat Bantuan',
        stepSubtitle: 'Arsip Tiket & Sesi Chat Selesai',
        showBackButton: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<SupportController>().fetchTickets(force: true),
          color: AppColors.primaryNavy,
          child: historyTickets.isEmpty
              ? LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: _buildEmptyState(context),
                    ),
                  ),
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: historyTickets.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final ticket = historyTickets[index];
                    return _buildHistoryCard(context, ticket);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 32,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Riwayat Tiket',
              style: TextStyle(
                fontSize: AppTypography.sizeHeading,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tiket kendala atau percakapan bantuan yang telah selesai ditangani tim operasional akan tersimpan di halaman ini sebagai arsip.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTypography.sizeBody,
                height: 1.4,
                color: AppColors.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text(
                'Kembali ke Pusat Bantuan',
                style: TextStyle(
                  fontSize: AppTypography.sizeBody,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryNavy,
                side: const BorderSide(color: AppColors.borderSubtle),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, SupportTicketModel ticket) {
    final formattedDate =
        '${ticket.createdAt.day.toString().padLeft(2, '0')}/${ticket.createdAt.month.toString().padLeft(2, '0')}/${ticket.createdAt.year}';
    final isClosed = ticket.isClosed;

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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge & Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isClosed ? const Color(0xFFF1F5F9) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isClosed ? const Color(0xFFCBD5E1) : const Color(0xFFBBF7D0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isClosed ? Icons.lock_outline_rounded : Icons.check_circle_rounded,
                        size: 12,
                        color: isClosed ? const Color(0xFF475569) : const Color(0xFF15803D),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isClosed ? 'Ditutup' : 'Selesai',
                        style: TextStyle(
                          fontSize: AppTypography.sizeTiny,
                          fontWeight: FontWeight.w700,
                          color: isClosed ? const Color(0xFF475569) : const Color(0xFF15803D),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              ticket.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: AppTypography.sizeBodyLarge,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 6),

            // Description Preview
            Text(
              ticket.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: AppTypography.sizeCaption,
                height: 1.35,
                color: AppColors.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.borderSubtle, height: 1),
            const SizedBox(height: 10),

            // Footer metadata & Call to Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ID: ${ticket.displayTicketNumber} • ${ticket.categoryLabel}',
                  style: const TextStyle(
                    fontSize: AppTypography.sizeTiny,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Buka Chat',
                      style: TextStyle(
                        fontSize: AppTypography.sizeCaption,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryTeal,
                        fontFamily: 'Inter',
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.primaryTeal,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
