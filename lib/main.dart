import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_application/nav_shell.dart';
import 'package:test_application/providers/cart_provider.dart';
import 'package:test_application/screens/login_screen.dart';
import 'package:test_application/courier_navigation_shell.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => CartProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Application',
      theme: _buildTheme(),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Delay sedikit untuk efek splash screen
    await Future.delayed(const Duration(seconds: 2)); 
    final prefs = await SharedPreferences.getInstance();
    
    final String? role = prefs.getString('role');
    final int? userId = prefs.getInt('user_id');

    if (!mounted) return;

    // Cek validitas data login
    if (userId != null && userId > 0 && role != null) {
      if (role == 'customer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NavigationShell()),
        );
      } else if (role == 'courier') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CourierNavigationShell()),
        );
      } else {
        // Role aneh, lempar ke login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } else {
      // Belum login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Anda bisa ganti Icon ini dengan Logo Gambar Anda
            Image.asset('assets/images/image-removebg-preview.png', width: 150, height: 150),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: Color(0xFFF4511E),
            ),
          ],
        ),
      ),
    );
  }
}

ThemeData _buildTheme() {
  final baseTheme = ThemeData.light(useMaterial3: true);
  const primaryColor = Color(0xFFF4511E);
  const secondaryColor = Color(0xFFFFB74D);
  const backgroundColor = Color.fromARGB(255, 255, 255, 255);
  const textFieldFillColor = Color(0xFFF9F9F9);

  return baseTheme.copyWith(
    colorScheme: baseTheme.colorScheme.copyWith(
      primary: primaryColor,
      secondary: secondaryColor,
      background: backgroundColor,
      onPrimary: Colors.white,
    ),
    scaffoldBackgroundColor: backgroundColor,
    textTheme: baseTheme.textTheme.apply(
      fontFamily: 'Poppins',
      bodyColor: Colors.grey.shade800,
      displayColor: primaryColor,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: textFieldFillColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    ),
  );
}