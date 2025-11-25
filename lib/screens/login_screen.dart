// ===== lib/screens/login_screen.dart (MODIFIKASI) =====
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:test_application/screens/register_screen.dart';
import 'package:test_application/services/login_service.dart';
// 💡 IMPORT RUMAH BARU
import 'package:test_application/nav_shell.dart';
import 'package:test_application/courier_navigation_shell.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // ... (Controller dan animasi Anda tetap SAMA) ...
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // 💡 --- MODIFIKASI FUNGSI LOGIN HANDLER --- 💡
  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Identifier dan password tidak boleh kosong')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Panggil API login yang sudah dimodifikasi
      var res = await AuthService.login(
        emailController.text, // Ini adalah 'identifier'
        passwordController.text,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        // SUKSES LOGIN, SEKARANG CEK ROLE
        final String role = res['role'];

        if (role == 'customer') {
          // Navigasi ke Rumah Pelanggan
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const NavigationShell()),
          );
        } else if (role == 'courier') {
          // Navigasi ke Rumah Kurir
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CourierNavigationShell()),
          );
        } else {
          // Role tidak diketahui
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Role tidak dikenali: $role')),
          );
        }

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Terjadi kesalahan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal terhubung ke server: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  // ... (Sisa build method Anda (_buildHeader, _buildForm, dll) tetap SAMA) ...
  // ...
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          _buildHeader(textTheme, colorScheme),
                          const SizedBox(height: 40),
                          _buildForm(theme),
                          const SizedBox(height: 24),
                          _buildLoginButton(colorScheme, textTheme),
                          const Spacer(),
                          _buildFooter(context, textTheme, colorScheme),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme, ColorScheme colorScheme) {
    return Column(
      children: [
        const SizedBox(height: 100),
        Image.asset(
          'assets/images/Red and White Simple Food Logo.png',
          width: 250,
          height: 250,
        ),
        const SizedBox(height: 10),
        Text(
          'Masuk untuk melanjutkan',
          style: textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Column(
      children: [
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email atau No. HP', // 💡 Ubah label
            hintText: 'example@email.com',
            prefixIcon: Icon(Icons.person_outline, color: theme.colorScheme.primary),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.primary),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: theme.colorScheme.primary.withOpacity(0.7),
              ),
              onPressed: () {
                setState(() => _isPasswordVisible = !_isPasswordVisible);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(ColorScheme colorScheme, TextTheme textTheme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : const Text("Masuk"),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, TextTheme textTheme, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Belum punya akun?",
          style: textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterScreen()),
            );
            if (result == true && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Akun berhasil dibuat, silakan login"),
                ),
              );
            }
          },
          child: Text(
            'Buat Akun',
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}