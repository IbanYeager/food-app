import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:test_application/home_screen.dart';
import 'package:test_application/services/login_service.dart';
import 'package:test_application/styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Masuk', style: TextStyles.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            Center(
              child: SvgPicture.asset(
                'assets/images/openmoji_pot-of-food.svg',
                width: 200,
                height: 200,
              ),
            ),
            const SizedBox(height: 10.0),
            const Text(
              'Login',
              style: TextStyle(
                fontSize: 34.0,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: Color(0XFFC57E1B),
              ),
            ),
            const SizedBox(height: 20),

            // Email
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Nomor Telp & Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SvgPicture.asset(
                      'assets/images/iconamoon_profile.svg',
                      width: 20,
                      height: 20,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Password
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SvgPicture.asset(
                      'assets/images/material-symbols_lock-outline.svg',
                      width: 20,
                      height: 20,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Tombol Login
            ElevatedButton(
              onPressed: () async {
                var res = await AuthService.login(
                  emailController.text,
                  passwordController.text,
                );

                if (res['success'] == true) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res['message'])),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0XFFF3C623),
                padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Masuk",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0XFFC57E1B),
                ),
              ),
            ),

            const SizedBox(height: 230),

            // Tombol Buat Akun
            Column(
              children: [
                const Text("Belum Punya Akun?"),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0XFFF3C623),
                    padding: const EdgeInsets.symmetric(horizontal: 165, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // TODO: pindah ke halaman register
                  },
                  child: const Text(
                    "Buat Akun",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0XFFC57E1B),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
