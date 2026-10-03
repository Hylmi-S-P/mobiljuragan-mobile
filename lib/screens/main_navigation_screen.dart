import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          HomeScreen(
            onNavigateToPesan: () {
              setState(() {
                _currentTabIndex = 1;
              });
            },
          ),
          const VehicleSelectionScreen(showBottomNav: true),
          OrderHistoryScreen(
            onNavigateToPesan: () {
              setState(() {
                _currentTabIndex = 1;
              });
            },
          ),
          const HelpCenterScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
      ),
    );
  }
}
