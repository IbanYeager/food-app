// ===== lib/courier_navigation_shell.dart (PERBAIKAN) =====
import 'package:flutter/material.dart';
import 'package:test_application/screens/courier/courier_dashboard_screen.dart'; 
import 'package:test_application/screens/profile_screen.dart';
import 'package:test_application/screens/chat_list_screen.dart'; 
import 'package:test_application/screens/courier/courier_history_screen.dart';

class CourierNavigationShell extends StatefulWidget {
  const CourierNavigationShell({super.key});

  @override
  State<CourierNavigationShell> createState() => _CourierNavigationShellState();
}

class _CourierNavigationShellState extends State<CourierNavigationShell> {
  int _selectedIndex = 0; 

  // Daftar Halaman (Ada 4)
  static const List<Widget> _pages = <Widget>[
    CourierDashboardScreen(), // Index 0
    ChatListScreen(),         // Index 1
    CourierHistoryScreen(),   // Index 2 (Riwayat)
    ProfileScreen(),          // Index 3
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Penting agar label muncul semua jika >3 item
        items: const <BottomNavigationBarItem>[
          // 1. Dashboard
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          // 2. Chat
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Pesan',
          ),
          // 3. Riwayat (INI YANG DITAMBAHKAN) 💡
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          // 4. Profil
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepOrange, 
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}