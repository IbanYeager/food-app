import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:test_application/screens/register_screen.dart';
import 'package:test_application/services/login_service.dart';
import 'package:test_application/nav_shell.dart';
// Hapus import styles.dart jika gaya terpusat di ThemeData
// import 'package:test_application/styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// ✨ BARU: Tambahkan 'SingleTickerProviderStateMixin' untuk animasi
class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // ✨ BARU: Controller dan animasi untuk efek fade-in
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
    _animationController.forward(); // Mulai animasi
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _animationController.dispose(); // Jangan lupa dispose controller animasi
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Sembunyikan keyboard saat tombol ditekan
    FocusScope.of(context).unfocus();

    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password tidak boleh kosong')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      var res = await AuthService.login(
        emailController.text,
        passwordController.text,
      );

      if (!mounted) return;


      if (res['success'] == true) {
        // Ganti HomeScreen() dengan NavigationShell()
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NavigationShell()), // <-- Navigasi yang Benar
        );
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

  @override
  Widget build(BuildContext context) {
    // ✨ BARU: Mengambil tema dari context untuk konsistensi
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // ✨ BARU: Background color dari tema
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
                  // ✨ BARU: Bungkus dengan FadeTransition untuk animasi
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          // ✨ BARU: Kode dipecah agar lebih rapi
                          _buildHeader(textTheme, colorScheme),
                          const SizedBox(height: 40),
                          _buildForm(theme),
                          const SizedBox(height: 24),
                          _buildLoginButton(colorScheme, textTheme),
                          const Spacer(), // ✨ PENTING: Mendorong footer ke bawah
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

  // ✨ BARU: Widget Header
  Widget _buildHeader(TextTheme textTheme, ColorScheme colorScheme) {
    return Column(
      children: [
        const SizedBox(height: 60),
        SvgPicture.asset(
          'assets/images/openmoji_pot-of-food.svg',
          width: 120,
          height: 120,
        ),
        const SizedBox(height: 20),
        Text(
          'Selamat Datang!',
          style: textTheme.headlineLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Masuk untuk melanjutkan',
          style: textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // ✨ BARU: Widget Form
  Widget _buildForm(ThemeData theme) {
    return Column(
      children: [
        // Email TextField
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'example@email.com',
            prefixIcon: Icon(Icons.person_outline, color: theme.colorScheme.primary),
          ),
        ),
        const SizedBox(height: 16),
        // Password TextField
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

  // ✨ BARU: Widget Tombol Login
  Widget _buildLoginButton(ColorScheme colorScheme, TextTheme textTheme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          // ✨ BARU: Warna dari tema
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

  // ✨ BARU: Widget Footer (Link ke Register)
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