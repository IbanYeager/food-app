import 'package:flutter/material.dart';
import 'package:test_application/login_screen.dart';
import 'package:test_application/profile_screen.dart';
import 'package:test_application/register_screen.dart';
import 'package:test_application/home_screen.dart';
import 'package:test_application/cart_screen.dart';
import 'package:test_application/payment_screen.dart';
import 'package:test_application/success_screen.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Test Application",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/cart': (context) => const CartScreen(cartItems: cartItems),
        '/profile': (context) => const ProfileScreen(),
        '/payment': (context) => const PaymentScreen(),
        '/order_success': (context) => const SuccessScreen(),
      },
    );
  }
}
