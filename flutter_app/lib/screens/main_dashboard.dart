import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../theme.dart';
import 'dashboard_view.dart';
import 'profile_view.dart';
import 'scanner_view.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardView(),
    ScannerView(),
    ProfileView(),
  ];

  void _onNav(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          boxShadow: AppTheme.bottomNavShadow,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onNav,
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: _NavIcon(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  isActive: _currentIndex == 0,
                ),
                label: t('dashboard'),
              ),
              BottomNavigationBarItem(
                icon: _NavIcon(
                  icon: Icons.qr_code_scanner_outlined,
                  activeIcon: Icons.qr_code_scanner_rounded,
                  isActive: _currentIndex == 1,
                ),
                label: t('scanner'),
              ),
              BottomNavigationBarItem(
                icon: _NavIcon(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  isActive: _currentIndex == 2,
                ),
                label: t('profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;

  const _NavIcon({
    required this.icon,
    required this.activeIcon,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(
          horizontal: isActive ? 14 : 0, vertical: isActive ? 5 : 0),
      decoration: BoxDecoration(
        color: isActive ? primary.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        isActive ? activeIcon : icon,
        size: 22,
      ),
    );
  }
}
