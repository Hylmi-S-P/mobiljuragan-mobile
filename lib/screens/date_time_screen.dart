import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/booking_controller.dart';
import '../models/vehicle_model.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import 'rental_options_screen.dart';

/// Layar pemilihan jadwal tanggal dan durasi sewa
class DateTimeScreen extends StatefulWidget {
  final VehicleModel vehicle;

  const DateTimeScreen({
    super.key,
    required this.vehicle,
  });

  @override
  State<DateTimeScreen> createState() => _DateTimeScreenState();
}

class _DateTimeScreenState extends State<DateTimeScreen> {
  late DateTime _displayedMonth;
  late DateTime _selectedDate;
  
  String _selectedTime = '09.00 WIT';
  String _timeDescription = 'Pagi hari';
  int _durationDays = 2;

  final List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  final List<String> _dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  void initState() {
    super.initState();
    final booking = context.read<BookingController>();
    _displayedMonth = DateTime(booking.selectedDate.year, booking.selectedDate.month, 1);
    _selectedDate = booking.selectedDate;
    _selectedTime = booking.selectedTime;
    _durationDays = booking.durationDays.clamp(1, 30);
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const CustomAppBar(
        title: 'Tanggal & Waktu',
        stepSubtitle: 'Langkah 3 dari 5',
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 14),
                  _buildInteractiveCalendarCard(),
                  const SizedBox(height: 14),
                  _buildScheduleConfigCard(),
                  const SizedBox(height: 14),
                  _buildRentalPolicyNotice(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          _buildStickyCTA(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tentukan Jadwal Rental',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Pilih tanggal mulai sewa dan durasi pemakaian.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.tealLight,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Jadwal Fleksibel',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryTeal,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveCalendarCard() {
    final int daysInMonth = DateUtils.getDaysInMonth(
      _displayedMonth.year,
      _displayedMonth.month,
    );

    final DateTime firstDayOfMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      1,
    );
    final int startingWeekday = firstDayOfMonth.weekday;

    final String monthName = _monthNames[_displayedMonth.month - 1];
    final String formattedYear = _displayedMonth.year.toString();
    final DateTime returnDate = _selectedDate.add(Duration(days: _durationDays));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: _previousMonth,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.borderSubtle, width: 1),
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$monthName $formattedYear',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _nextMonth,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.borderSubtle, width: 1),
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const Text(
                'Bulan terpilih',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryTeal,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _dayNames.map((day) {
              return SizedBox(
                width: 36,
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          _buildDatesGrid(daysInMonth, startingWeekday, returnDate),
          const SizedBox(height: 14),
          _buildCalendarLegend(returnDate),
        ],
      ),
    );
  }

  Widget _buildDatesGrid(int totalDays, int startingWeekday, DateTime returnDate) {
    final int emptyLeadingDays = startingWeekday - 1;
    final int totalGridItems = emptyLeadingDays + totalDays;

    final DateTime startDayOnly = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    final DateTime endDayOnly = DateTime(
      returnDate.year,
      returnDate.month,
      returnDate.day,
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalGridItems,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 0,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {
        if (index < emptyLeadingDays) {
          return const SizedBox.shrink();
        }

        final int day = index - emptyLeadingDays + 1;
        final DateTime currentDayOnly = DateTime(
          _displayedMonth.year,
          _displayedMonth.month,
          day,
        );

        final bool isStartDate = currentDayOnly.isAtSameMomentAs(startDayOnly);
        final bool isEndDate = currentDayOnly.isAtSameMomentAs(endDayOnly);
        final bool isInRange = currentDayOnly.isAfter(startDayOnly) &&
            currentDayOnly.isBefore(endDayOnly);

        return InkWell(
          onTap: () {
            setState(() {
              _selectedDate = DateTime(
                _displayedMonth.year,
                _displayedMonth.month,
                day,
              );
            });
          },
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pita penghubung tanggal sewa
              if (isInRange)
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    color: AppColors.primaryTeal.withValues(alpha: 0.12),
                  ),
                )
              else if (isStartDate && _durationDays > 0)
                Positioned(
                  right: 0,
                  top: 3,
                  bottom: 3,
                  left: 17,
                  child: Container(
                    color: AppColors.primaryTeal.withValues(alpha: 0.12),
                  ),
                )
              else if (isEndDate && _durationDays > 0)
                Positioned(
                  left: 0,
                  top: 3,
                  bottom: 3,
                  right: 17,
                  child: Container(
                    color: AppColors.primaryTeal.withValues(alpha: 0.12),
                  ),
                ),

              // Lingkaran penanda tanggal
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isStartDate
                      ? AppColors.primaryTeal
                      : isEndDate
                          ? AppColors.primaryNavy
                          : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    day.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: (isStartDate || isEndDate)
                          ? FontWeight.w700
                          : isInRange
                              ? FontWeight.w600
                              : FontWeight.w500,
                      color: (isStartDate || isEndDate)
                          ? AppColors.textWhite
                          : isInRange
                              ? AppColors.primaryNavy
                              : AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendarLegend(DateTime returnDate) {
    final startFormatted =
        '${_selectedDate.day} ${_monthNames[_selectedDate.month - 1].substring(0, 3)}';
    final returnFormatted =
        '${returnDate.day} ${_monthNames[returnDate.month - 1].substring(0, 3)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primaryTeal,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Mulai: $startFormatted',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primaryNavy,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Selesai: $returnFormatted',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryNavy,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.tealLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$_durationDays Hari',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryTeal,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  TimeOfDay _parseTimeOfDay(String timeStr) {
    try {
      final clean = timeStr.replaceAll(' WIT', '').trim();
      final parts = clean.contains(':') ? clean.split(':') : clean.split('.');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }


  String _getTimeDescription(int hour) {
    if (hour >= 5 && hour < 11) {
      return 'Pagi hari';
    } else if (hour >= 11 && hour < 15) {
      return 'Siang hari';
    } else if (hour >= 15 && hour < 18) {
      return 'Sore hari';
    } else {
      return 'Malam hari';
    }
  }

  void _applyTime(String timeStr, {String? desc}) {
    final parsed = _parseTimeOfDay(timeStr);
    final description = desc ?? _getTimeDescription(parsed.hour);
    setState(() {
      _selectedTime = timeStr;
      _timeDescription = description;
    });
  }

  void _showSessionTimePickerSheet() {
    final morningSlots = [
      {'time': '06.00 WIT', 'desc': 'Pagi hari'},
      {'time': '07.00 WIT', 'desc': 'Pagi hari'},
      {'time': '07.30 WIT', 'desc': 'Pagi hari'},
      {'time': '08.00 WIT', 'desc': 'Pagi hari'},
      {'time': '08.30 WIT', 'desc': 'Pagi hari'},
      {'time': '09.00 WIT', 'desc': 'Pagi hari'},
      {'time': '09.30 WIT', 'desc': 'Pagi hari'},
      {'time': '10.00 WIT', 'desc': 'Pagi hari'},
      {'time': '10.30 WIT', 'desc': 'Pagi hari'},
    ];

    final afternoonSlots = [
      {'time': '11.00 WIT', 'desc': 'Siang hari'},
      {'time': '11.30 WIT', 'desc': 'Siang hari'},
      {'time': '12.00 WIT', 'desc': 'Siang hari'},
      {'time': '12.30 WIT', 'desc': 'Siang hari'},
      {'time': '13.00 WIT', 'desc': 'Siang hari'},
      {'time': '13.30 WIT', 'desc': 'Siang hari'},
      {'time': '14.00 WIT', 'desc': 'Siang hari'},
      {'time': '14.30 WIT', 'desc': 'Siang hari'},
    ];

    final eveningSlots = [
      {'time': '15.00 WIT', 'desc': 'Sore hari'},
      {'time': '15.30 WIT', 'desc': 'Sore hari'},
      {'time': '16.00 WIT', 'desc': 'Sore hari'},
      {'time': '16.30 WIT', 'desc': 'Sore hari'},
      {'time': '17.00 WIT', 'desc': 'Sore hari'},
      {'time': '17.30 WIT', 'desc': 'Sore hari'},
      {'time': '18.00 WIT', 'desc': 'Sore hari'},
    ];

    final nightSlots = [
      {'time': '19.00 WIT', 'desc': 'Malam hari'},
      {'time': '19.30 WIT', 'desc': 'Malam hari'},
      {'time': '20.00 WIT', 'desc': 'Malam hari'},
      {'time': '20.30 WIT', 'desc': 'Malam hari'},
      {'time': '21.00 WIT', 'desc': 'Malam hari'},
      {'time': '22.00 WIT', 'desc': 'Malam hari'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderSubtle,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pilih Jam Penjemputan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontFamily: 'Inter',
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Format 24 Jam (WIT) sesuai waktu kedatangan',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _buildSessionGroup(
                    sheetContext: sheetContext,
                    icon: Icons.wb_sunny_outlined,
                    sessionTitle: 'Pagi Hari (06.00 - 10.30 WIT)',
                    slots: morningSlots,
                  ),
                  const SizedBox(height: 14),

                  _buildSessionGroup(
                    sheetContext: sheetContext,
                    icon: Icons.wb_sunny_rounded,
                    sessionTitle: 'Siang Hari (11.00 - 14.30 WIT)',
                    slots: afternoonSlots,
                  ),
                  const SizedBox(height: 14),

                  _buildSessionGroup(
                    sheetContext: sheetContext,
                    icon: Icons.wb_twilight_rounded,
                    sessionTitle: 'Sore Hari (15.00 - 18.00 WIT)',
                    slots: eveningSlots,
                  ),
                  const SizedBox(height: 14),

                  _buildSessionGroup(
                    sheetContext: sheetContext,
                    icon: Icons.nightlight_round,
                    sessionTitle: 'Malam Hari (19.00 - 22.00 WIT)',
                    slots: nightSlots,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSessionGroup({
    required BuildContext sheetContext,
    required IconData icon,
    required String sessionTitle,
    required List<Map<String, String>> slots,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primaryTeal),
            const SizedBox(width: 6),
            Text(
              sessionTitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: slots.map((item) {
            final time = item['time']!;
            final desc = item['desc']!;
            final isSelected = _selectedTime == time;

            return InkWell(
              onTap: () {
                _applyTime(time, desc: desc);
                Navigator.pop(sheetContext);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryNavy : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryNavy : AppColors.borderSubtle,
                    width: 1,
                  ),
                ),
                child: Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildScheduleConfigCard() {
    final quickTimes = [
      '08.00 WIT',
      '09.00 WIT',
      '10.00 WIT',
      '13.00 WIT',
      '16.00 WIT',
      '19.00 WIT',
    ];

    final quickDays = [
      {'label': '1 Hari', 'days': 1},
      {'label': '2 Hari', 'days': 2},
      {'label': '3 Hari', 'days': 3},
      {'label': '5 Hari', 'days': 5},
      {'label': '1 Minggu (7 Hari)', 'days': 7},
      {'label': '2 Minggu (14 Hari)', 'days': 14},
      {'label': '1 Bulan (30 Hari)', 'days': 30},
    ];

    final returnDate = _selectedDate.add(Duration(days: _durationDays));
    final returnDayName = _dayNames[returnDate.weekday - 1];
    final formattedReturnDate =
        '$returnDayName, ${returnDate.day.toString().padLeft(2, '0')} ${_monthNames[returnDate.month - 1]} ${returnDate.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Waktu Mulai Penjemputan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: AppColors.primaryTeal,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Waktu Mulai Penjemputan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _showSessionTimePickerSheet,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_filled_rounded,
                        size: 13,
                        color: AppColors.primaryTeal,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Jam Lain',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryTeal,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Pilihan Chip Waktu
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...quickTimes.map((time) {
                  final isSelected = _selectedTime == time;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => _applyTime(time),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryNavy : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryNavy : AppColors.borderSubtle,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          time,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                InkWell(
                  onTap: _showSessionTimePickerSheet,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primaryTeal.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.more_time_rounded, size: 14, color: AppColors.primaryTeal),
                        SizedBox(width: 4),
                        Text(
                          'Jam Lain...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryTeal,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Waktu terpilih: $_selectedTime (Sesi $_timeDescription)',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 14),

          // 2. Durasi Sewa
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 16,
                      color: AppColors.primaryNavy,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Durasi Sewa',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontFamily: 'Inter',
                            ),
                          ),
                          Text(
                            'Sewa harian hingga 30 hari',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  InkWell(
                    onTap: _durationDays > 1
                        ? () {
                            setState(() => _durationDays--);
                          }
                        : null,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _durationDays > 1 ? AppColors.surfaceLight : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _durationDays > 1 ? AppColors.borderSubtle : Colors.transparent,
                        ),
                      ),
                      child: Icon(
                        Icons.remove_rounded,
                        size: 16,
                        color: _durationDays > 1 ? AppColors.primaryNavy : AppColors.textMuted,
                      ),
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 64),
                    alignment: Alignment.center,
                    child: Text(
                      '$_durationDays Hari',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _durationDays < 30
                        ? () {
                            setState(() => _durationDays++);
                          }
                        : null,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _durationDays < 30 ? AppColors.surfaceLight : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _durationDays < 30 ? AppColors.borderSubtle : Colors.transparent,
                        ),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        size: 16,
                        color: _durationDays < 30 ? AppColors.primaryTeal : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Pilihan Chip Durasi Hari
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: quickDays.map((item) {
                final days = item['days'] as int;
                final label = item['label'] as String;
                final isSelected = _durationDays == days;

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _durationDays = days;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryNavy : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryNavy : AppColors.borderSubtle,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),

          // 3. Ringkasan Pengembalian Armada
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.event_available_rounded,
                  size: 16,
                  color: Color(0xFF16A34A),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kembali: $formattedReturnDate pukul $_selectedTime',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF166534),
                          fontFamily: 'Inter',
                        ),
                      ),
                      Text(
                        'Durasi total $_durationDays hari sewa (${_durationDays * 24} jam penuh)',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF15803D),
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

  Widget _buildRentalPolicyNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primaryTeal),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Hitungan sewa berlaku 24 jam sejak serah terima di Merauke. Opsi layanan supir atau lepas kunci dipilih pada langkah berikutnya.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.4,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyCTA() {
    final returnDate = _selectedDate.add(Duration(days: _durationDays));
    final formattedDate =
        '${_selectedDate.day} ${_monthNames[_selectedDate.month - 1].substring(0, 3)}';
    final formattedReturn =
        '${returnDate.day} ${_monthNames[returnDate.month - 1].substring(0, 3)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(top: BorderSide(color: AppColors.borderSubtle, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Periode Sewa',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
                Text(
                  '$_durationDays Hari ($formattedDate - $formattedReturn)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<BookingController>().setSchedule(
                          date: _selectedDate,
                          time: _selectedTime,
                          durationDays: _durationDays,
                        );
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RentalOptionsScreen(
                          vehicle: widget.vehicle,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: AppColors.textWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text(
                    'Lanjutkan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
