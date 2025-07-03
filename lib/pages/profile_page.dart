import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../connection/auth_service.dart'; 

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? username;
  String? email;
  String? profileImageUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  void fetchProfile() async {
    // Ambil token dari AuthService atau shared_preferences
    final token = await AuthService().getToken(); // kamu sesuaikan implementasinya
    if (token == null) {
      // Misal redirect ke login karena token tidak ditemukan
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    final userData = await UserService().getProfile(token);

    if (userData != null) {
      setState(() {
        username = userData['username'];
        email = userData['email'];
        profileImageUrl = userData['profile_picture'];
        isLoading = false;
      });
    } else {
      // handle gagal
      setState(() => isLoading = false);
    }
  }

  void _logout() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profil Saya")),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: profileImageUrl != null && profileImageUrl!.isNotEmpty
                        ? NetworkImage(profileImageUrl!)
                        : AssetImage('assets/default_profile.png') as ImageProvider,
                  ),
                  SizedBox(height: 16),
                  Text(username ?? '-', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(email ?? '-', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _logout,
                    child: Text("Logout"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  )
                ],
              ),
      ),
    );
  }
}
