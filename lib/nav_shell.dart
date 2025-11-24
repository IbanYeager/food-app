  // ===== lib/nav_shell.dart (MODIFIKASI) =====

  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import 'package:test_application/providers/cart_provider.dart';
  import 'package:test_application/screens/cart_screen.dart';
  import 'package:test_application/screens/home_screen.dart';
  import 'package:test_application/screens/profile_screen.dart';
  import 'package:test_application/screens/order_history_screen.dart';
  // 💡 1. HAPUS FAVORITE
  // import 'package:test_application/screens/favorite_screen.dart'; 
  // 💡 2. IMPORT CHAT LIST
  import 'package:test_application/screens/chat_list_screen.dart'; 

  class NavigationShell extends StatefulWidget {
    const NavigationShell({super.key});

    @override
    State<NavigationShell> createState() => _NavigationShellState();
  }

  class _NavigationShellState extends State<NavigationShell> {
    int _selectedIndex = 2; // Tetap mulai di Home

    static const Color primaryColor = Color(0xFFF4511E);
    static const double _fabSize = 64.0;
    static const double _navBarHeight = 60.0;
    
    // 💡 3. GANTI HALAMAN FAVORITE DENGAN CHAT
    final List<Widget> _pages = const [
      ChatListScreen(), // <--- Ganti di sini
      CartPage(),
      HomeScreen(),
      OrderHistoryScreen(),
      ProfileScreen(),
    ];

    void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    Widget _buildIconItem(IconData icon, int index, {double size = 28.0}) {
      // ... (Fungsi ini tidak berubah)
      return Expanded(
        child: GestureDetector(
          onTap: () => _onItemTapped(index),
          child: Container(
            color: Colors.transparent,
            child: Icon(icon, color: Colors.white, size: size),
          ),
        ),
      );
    }

    Widget _buildCartItem(int index, CartProvider cartProvider) {
      // ... (Fungsi ini tidak berubah)
      final int cartCount = cartProvider.itemCount; 

      return Expanded(
        child: GestureDetector(
          onTap: () => _onItemTapped(index),
          child: Container(
            color: Colors.transparent,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart, color: Colors.white, size: 28),
                if (cartCount > 0)
                  Positioned(
                    top: -5,
                    right: 15,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 255, 255, 255),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    
    @override
    Widget build(BuildContext context) {
      final screenWidth = MediaQuery.of(context).size.width;
      const double horizontalPadding = 24.0;
      final double navBarWidth = screenWidth - (horizontalPadding * 2);
      final double itemWidth = navBarWidth / 5;
      final double fabLeftPosition = (_selectedIndex * itemWidth) + (itemWidth / 2) - (_fabSize / 2);

      return Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          
          // 💡 4. GANTI IKON FAVORITE DENGAN IKON CHAT
          final List<Widget> allItems = [
            _buildIconItem(Icons.chat_bubble_outline, 0), // <--- Ganti di sini
            _buildCartItem(1, cartProvider),
            _buildIconItem(Icons.home, 2),
            _buildIconItem(Icons.history, 3),
            _buildIconItem(Icons.person, 4),
          ];

          final List<Widget> leftItems = allItems.sublist(0, _selectedIndex);
          final List<Widget> rightItems = allItems.sublist(_selectedIndex + 1);

          // ... (Sisa kode Scaffold Anda tidak perlu diubah)
          return Scaffold(
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
              child: _pages[_selectedIndex],
            ),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8.0),
              child: SizedBox(
                height: _navBarHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Row(
                      children: [
                        if (leftItems.isNotEmpty)
                          Expanded(
                            flex: leftItems.length,
                            child: Container(
                              height: _navBarHeight,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Row(children: leftItems),
                            ),
                          ),
                        
                        const SizedBox(width: _fabSize + 16),
                        
                        if (rightItems.isNotEmpty)
                          Expanded(
                            flex: rightItems.length,
                            child: Container(
                              height: _navBarHeight,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Row(children: rightItems),
                            ),
                          ),
                      ],
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      top: -24,
                      left: fabLeftPosition,
                      child: GestureDetector(
                        onTap: () => _onItemTapped(_selectedIndex),
                        child: Container(
                          width: _fabSize,
                          height: _fabSize,
                          decoration: const BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
                            ],
                          ),
                          child: allItems[_selectedIndex],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
  }