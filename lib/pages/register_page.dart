import 'package:flutter/material.dart';
import '../connection/auth_service.dart';
import '../widgets/custom_button.dart'; 
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void register() async {
    bool success = await AuthService().register(
      usernameController.text,
      emailController.text,
      passwordController.text,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Registrasi berhasil! Silakan login.")));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Registrasi gagal!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Registrasi")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: usernameController, decoration: InputDecoration(labelText: "Username")),
            TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: "Password"), obscureText: true),
            SizedBox(height: 20),
            CustomButton( // Gunakan tombol kustom
              text: "Register",
              onPressed: register,
              color: Colors.green, // Warna berbeda untuk tombol registrasi
            ),
          ],
        ),
      ),
    );
  }
}
