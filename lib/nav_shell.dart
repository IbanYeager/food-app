import 'package:flutter/material.dart';
import 'package:test_application/screens/cart_screen.dart';
import 'package:test_application/screens/home_screen.dart';
import 'package:test_application/screens/profile_screen.dart';
import 'package:test_application/services/cart_service.dart';

class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _selectedIndex = 0;

  // Daftar halaman yang akan ditampilkan
  static const List<Widget> _pages = <Widget>[
    HomeScreen(),
    CartPage(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  // Panggil fungsi ini untuk merefresh UI saat ada perubahan di cart
  void _onCartUpdated() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // Dengarkan perubahan pada cart untuk update badge notifikasi
    CartService().addListener(_onCartUpdated);
  }

  @override
  void dispose() {
    // Hapus listener untuk mencegah memory leak
    CartService().removeListener(_onCartUpdated);
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Tampilkan halaman yang sesuai dengan index yang dipilih
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      // Bottom Navigation Bar yang sudah dipisahkan
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart_rounded, size: 28),
                // Cek isi cart dari CartService
                if (CartService().cartItems.isNotEmpty)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '${CartService().cartItems.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: "Keranjang",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: "Profil",
          ),
        ],
      ),
    );
  }
}