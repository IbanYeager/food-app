// ===== lib/screens/register_screen.dart (MODIFIKASI PENUH) =====
import 'package:flutter/material.dart';
import 'package:test_application/services/login_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // 💡 BARU: State untuk menyimpan role
  String _selectedRole = 'customer'; // Default

  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  // 💡 --- MODIFIKASI FUNGSI REGISTER --- 💡
  Future<void> _register() async {
    // 1. Validasi data umum
    if (nameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama, No. HP, dan Password wajib diisi")),
      );
      return;
    }

    // 2. Validasi email (hanya jika customer)
    String email = emailController.text;
    if (_selectedRole == 'customer' && email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email wajib diisi untuk pelanggan")),
      );
      return;
    }

    setState(() => isLoading = true);

    // 3. Panggil service dengan role
    var res = await AuthService.register(
      nameController.text,
      email, // Email akan kosong jika mendaftar sebagai kurir
      passwordController.text,
      phoneController.text,
      _selectedRole, // Kirim role yang dipilih
    );

    setState(() => isLoading = false);

    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registrasi ${res['message']}")),
      );
      Navigator.pop(context, true); // Kembali ke login
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? "Gagal registrasi")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buat Akun")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 💡 --- UI PEMILIHAN ROLE BARU --- 💡
            Text(
              "Daftar sebagai:",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            RadioListTile<String>(
              title: const Text("Pelanggan (Customer)"),
              value: 'customer',
              groupValue: _selectedRole,
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text("Kurir (Driver)"),
              value: 'courier',
              groupValue: _selectedRole,
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
            ),
            const Divider(height: 20),
            // ------------------------------------

            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nama Lengkap"),
            ),
            const SizedBox(height: 10),

            // 💡 Sembunyikan/Tampilkan Email berdasarkan Role
            if (_selectedRole == 'customer')
              Column(
                children: [
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: "Email"),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),
                ],
              ),

            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "Nomor HP"),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _register,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : const Text("Daftar"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}