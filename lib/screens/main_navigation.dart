import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fabisy/screens/updated_mobile_home_screen.dart';
import 'package:fabisy/screens/new_catalog_screen.dart';
import 'package:fabisy/screens/video_screen.dart';
import 'package:fabisy/screens/profile_screen.dart';

class BottomNavigationController extends GetxController {
  var selectedIndex = 0.obs;
  
  void changePage(int index) {
    selectedIndex.value = index;
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  late final BottomNavigationController _bottomNavController;

  @override
  void initState() {
    super.initState();
    _bottomNavController = Get.put(BottomNavigationController());
  }
  
  final List<Widget> _screens = [
    const UpdatedMobileHomeScreen(),
    const NewCatalogScreen(),
    const VideoScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _bottomNavController.changePage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    final items = [
      {'icon': Icons.home, 'label': 'Home'},
      {'icon': Icons.search, 'label': 'Catalog'},
      {'icon': Icons.play_circle_outline, 'label': 'Video'},
      {'icon': Icons.person_outline, 'label': 'Profile'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == _selectedIndex;
              
              return GestureDetector(
                onTap: () => _onItemTapped(index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 24,
                      color: isSelected ? const Color(0xFFEC1380) : const Color(0xFF6B7280),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? const Color(0xFFEC1380) : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
