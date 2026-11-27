import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';
import 'help_center_screen.dart';
import 'home_screen.dart';
import 'order_history_screen.dart';
import 'vehicle_selection_screen.dart';

/// Shell navigasi utama aplikasi
class MainNavigationScreen extends StatefulWidget {
  final int initialTabIndex;

  const MainNavigationScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentTabIndex;
  final Set<int> _tabSudahDibuka = <int>{};

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;
    _tabSudahDibuka.add(_currentTabIndex);
  }

  void _pindahTab(int index) {
    if (_currentTabIndex == index && _tabSudahDibuka.contains(index)) return;
    setState(() {
      _currentTabIndex = index;
      _tabSudahDibuka.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.cardWhite,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: IndexedStack(
          index: _currentTabIndex,
          children: [
            _tabSudahDibuka.contains(0)
                ? HomeScreen(
                    onNavigateToPesan: () => _pindahTab(1),
                    isActive: _currentTabIndex == 0,
                  )
                : const SizedBox.shrink(),
            _tabSudahDibuka.contains(1)
                ? const VehicleSelectionScreen(showBottomNav: true)
                : const SizedBox.shrink(),
            _tabSudahDibuka.contains(2)
                ? OrderHistoryScreen(onNavigateToPesan: () => _pindahTab(1))
                : const SizedBox.shrink(),
            _tabSudahDibuka.contains(3)
                ? HelpCenterScreen(isActive: _currentTabIndex == 3)
                : const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentTabIndex,
          onTap: _pindahTab,
        ),
      ),
    );
  }
}
