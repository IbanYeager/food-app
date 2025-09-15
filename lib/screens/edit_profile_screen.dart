import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController namaController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController noHpController = TextEditingController();

  File? _image;
  String? _imageUrl; // 👈 Variabel untuk menyimpan URL foto yang sudah ada
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadDataUser();
  }

  /// Memuat data user dari SharedPreferences
  Future<void> _loadDataUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      namaController.text = prefs.getString("nama") ?? "";
      emailController.text = prefs.getString("email") ?? "";
      noHpController.text = prefs.getString("no_hp") ?? "";
      // 👈 Memuat URL foto yang tersimpan
      _imageUrl = prefs.getString("foto");
    });
  }

  /// Menampilkan bottom sheet untuk pilih sumber foto
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Galeri"),
                onTap: () async {
                  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    setState(() => _image = File(picked.path));
                  }
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text("Kamera"),
                onTap: () async {
                  final picked = await ImagePicker().pickImage(source: ImageSource.camera);
                  if (picked != null) {
                    setState(() => _image = File(picked.path));
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Mengirim data ke server untuk menyimpan profil
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("user_id") ?? 0;

    setState(() => _loading = true);

    try {
      var request = http.MultipartRequest(
        "POST",
        // ⚠️ Pastikan IP Address ini benar dan bisa diakses dari HP Anda
        Uri.parse("http://192.168.1.6/TEST_APPLICATION/api/update_user.php"),
      );

      request.fields['id'] = userId.toString();
      request.fields['nama'] = namaController.text;
      request.fields['email'] = emailController.text;
      request.fields['no_hp'] = noHpController.text;

      if (_image != null) {
        request.files.add(await http.MultipartFile.fromPath('foto', _image!.path));
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      print("Update Response: $responseBody");

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);

        if (data["status"] == "success") {
          final user = data["data"];

          // simpan data terbaru ke lokal
          await prefs.setString("nama", user["nama"]);
          await prefs.setString("email", user["email"]);
          await prefs.setString("no_hp", user["no_hp"]);
          // ❗️ Pastikan PHP mengembalikan URL lengkap
          await prefs.setString("foto", user["foto"] ?? "");

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Profil berhasil diperbarui")),
            );
            Navigator.pop(context, true); // kembali & kasih sinyal sukses
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["message"] ?? "Gagal update")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("Error update profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: $e")),
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profil")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    // ⭐️ INI BAGIAN UTAMA YANG DIPERBAIKI ⭐️
                    backgroundImage: _image != null
                        ? FileImage(_image!) as ImageProvider // 1. Tampilkan gambar baru jika ada
                        : _imageUrl != null && _imageUrl!.isNotEmpty
                            ? NetworkImage(_imageUrl!) // 2. Tampilkan gambar dari server jika ada
                            : null, // 3. Jika tidak ada, biarkan kosong agar child tampil
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.edit, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: namaController,
                decoration: const InputDecoration(labelText: "Nama"),
                validator: (val) =>
                    val == null || val.isEmpty ? "Nama tidak boleh kosong" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: noHpController,
                decoration: const InputDecoration(labelText: "No HP"),
                validator: (val) =>
                    val == null || val.isEmpty ? "Nomor HP wajib diisi" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (val) =>
                    val == null || !val.contains("@") ? "Email tidak valid" : null,
              ),
              const SizedBox(height: 30),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text("Simpan Perubahan"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}