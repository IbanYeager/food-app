import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as p;

class EditProfileScreen extends StatefulWidget {
  // 💡 Terima Role dari halaman sebelumnya
  final String role; 
  const EditProfileScreen({super.key, this.role = 'customer'});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController namaController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController noHpController = TextEditingController();
  final TextEditingController passwordController = TextEditingController(); // 💡 Controller Password

  File? _image;
  String? _imageUrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadDataUser();
  }

  Future<void> _loadDataUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      namaController.text = prefs.getString("nama") ?? "";
      emailController.text = prefs.getString("email") ?? "";
      noHpController.text = prefs.getString("no_hp") ?? "";
      _imageUrl = prefs.getString("foto");
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    
    if (picked != null) {
      // 1. Ambil file asli
      File originalFile = File(picked.path);
      
      // 2. Siapkan path untuk file hasil convert (JPG)
      final dir = await path_provider.getTemporaryDirectory();
      final targetPath = p.join(dir.absolute.path, "temp_${DateTime.now().millisecondsSinceEpoch}.jpg");

      // 3. Kompres & Convert ke JPG
      var result = await FlutterImageCompress.compressAndGetFile(
        originalFile.absolute.path, 
        targetPath,
        quality: 70, // Kualitas 70% (Cukup bagus tapi size kecil)
        format: CompressFormat.jpeg, // Paksa jadi JPEG
      );

      // 4. Simpan file hasil convert ke state
      if (result != null) {
        setState(() {
          _image = File(result.path); // File ini sekarang formatnya .jpg
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("user_id") ?? 0;

    setState(() => _loading = true);

    try {
      var request = http.MultipartRequest(
        "POST",
        // 💡 GANTI KE API BARU
        Uri.parse("http://192.168.1.6/test_application/api/update_profile_unified.php"),
      );

      request.fields['id'] = userId.toString();
      request.fields['role'] = widget.role; // 💡 Kirim Role
      request.fields['nama'] = namaController.text;
      request.fields['email'] = emailController.text;
      request.fields['no_hp'] = noHpController.text;
      
      // 💡 Kirim password hanya jika diisi
      if (passwordController.text.isNotEmpty) {
        request.fields['password'] = passwordController.text;
      }

      if (_image != null) {
        request.files.add(await http.MultipartFile.fromPath('foto', _image!.path));
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        if (data["status"] == "success") {
          final user = data["data"];

          // Simpan data baru ke SharedPreferences
          await prefs.setString("nama", user["nama"]);
          await prefs.setString("email", user["email"] ?? "");
          await prefs.setString("no_hp", user["no_hp"]);
          await prefs.setString("foto", user["foto"] ?? "");

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil berhasil diperbarui")));
            Navigator.pop(context, true); // Kembali dengan sukses
          }
        } else {
          throw Exception(data["message"]);
        }
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    } finally {
      if(mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profil")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _image != null
                      ? FileImage(_image!) as ImageProvider
                      : (_imageUrl != null && _imageUrl!.isNotEmpty 
                          ? NetworkImage(_imageUrl!) 
                          : const AssetImage('assets/images/profil.png') as ImageProvider), // Default image
                  child: const Align(
                      alignment: Alignment.bottomRight,
                      child: CircleAvatar(radius: 18, child: Icon(Icons.camera_alt, size: 18))),
                ),
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: namaController,
                decoration: const InputDecoration(labelText: "Nama Lengkap", prefixIcon: Icon(Icons.person)),
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 10),
              
              TextFormField(
                controller: noHpController,
                decoration: const InputDecoration(labelText: "Nomor HP", prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // 💡 FIELD PASSWORD BARU
              const Divider(),
              const Text("Ganti Password (Opsional)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password Baru",
                  prefixIcon: Icon(Icons.lock),
                  helperText: "Kosongkan jika tidak ingin mengganti password",
                  border: OutlineInputBorder()
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
                  child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text("Simpan Perubahan"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}