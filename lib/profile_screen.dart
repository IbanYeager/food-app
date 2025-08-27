import 'package:flutter/material.dart';
import '../utils/shared_pref.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profil Saya")),
      body: FutureBuilder<Map<String, dynamic>>(
        future: SharedPref.getUser(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(radius: 40, child: Text(user['nama'][0])),
                const SizedBox(height: 10),
                Text(user['nama'], style: const TextStyle(fontSize: 18)),
                Text(user['email']),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    await SharedPref.clearUser();
                    Navigator.pushReplacementNamed(context, "/login");
                  },
                  child: const Text("Logout"),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
