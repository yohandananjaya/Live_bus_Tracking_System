import 'dart:ui'; // 🔥 Blur effect එකට මේක අනිවාර්යයි
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'bookings_screen.dart';
import 'notifications_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const MapScreen(),
    const BookingsScreen(),
    const NotificationsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Navigation Bar එක යටින් පේන්න මේක අනිවාර්යයි
      body: _screens[_currentIndex],
      
      // 🔥 Transparent Theme Colored Navigation Bar
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.blue[900]!.withOpacity(0.3), // Shadow එකත් නිල් පාටට ගැලපෙන්න හැදුවා
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          // 🔥 ClipRRect සහ BackdropFilter මගින් විනිවිද පෙනෙන (Blur) පෙනුම ලබාදේ
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Blur එකේ ප්‍රමාණය
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  // App එකේ Theme Color එකට ගැලපෙන නිල් පාට සහ 85% ක විනිවිද භාවය (Opacity)
                  color: Colors.blue[900]!.withOpacity(0.85),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                    _buildNavItem(1, Icons.map_rounded, Icons.map_outlined, 'Map'),
                    _buildNavItem(2, Icons.confirmation_number_rounded, Icons.confirmation_number_outlined, 'Bookings'),
                    _buildNavItem(3, Icons.notifications_rounded, Icons.notifications_outlined, 'Alerts'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // අයිකන් සහ ටෙක්ස්ට් එක හදන Custom Widget එක
  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              // Select උනාම සුදු පාටින් කොටුවක් පෙන්වයි
              color: isSelected ? Colors.white.withOpacity(0.25) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? Colors.white : Colors.white60, // නිල් පසුබිමට කැපිලා පේන්න සුදු පාට
              size: 26,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}