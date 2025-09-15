import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_application/screens/login_screen.dart';
import 'package:test_application/nav_shell.dart'; // Import NavShell yang sudah dibuat

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Application',
      theme: _buildTheme(), // Memanggil fungsi tema
      // Ganti 'home' dengan AuthWrapper untuk cek status login
      home: const AuthWrapper(), 
      debugShowCheckedModeBanner: false,
    );
  }
}

// Widget baru untuk memeriksa status otentikasi/login
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Panggil fungsi pengecekan saat widget pertama kali dibuat
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Tunggu sesaat untuk UX yang lebih baik (opsional)
    await Future.delayed(const Duration(seconds: 1)); 

    final prefs = await SharedPreferences.getInstance();
    // Kita cek apakah ada data 'nama' yang tersimpan
    // Ini menandakan pengguna sudah pernah login
    final bool isLoggedIn = prefs.getString('nama')?.isNotEmpty ?? false;

    if (!mounted) return; // Pastikan widget masih ada di tree

    // Ganti halaman sesuai status login tanpa bisa kembali (back)
    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NavigationShell()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan layar loading saat pengecekan berlangsung
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFF4511E), // Warna primary
        ),
      ),
    );
  }
}


// Fungsi untuk membangun tema aplikasi (Tidak ada perubahan, sudah bagus)
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
    scaffoldBackgroundColor: backgroundColor, // Set latar belakang utama
    textTheme: baseTheme.textTheme.apply(
      fontFamily: 'Poppins',
      bodyColor: Colors.grey.shade800,
      displayColor: primaryColor,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: textFieldFillColor,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
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
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    ),
  );
}