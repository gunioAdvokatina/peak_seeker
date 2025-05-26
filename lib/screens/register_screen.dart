import 'package:flutter/material.dart';
import 'package:peak_seeker/screens/home_screen.dart';
import 'package:peak_seeker/screens/login_screen.dart';
import 'package:peak_seeker/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  void register() async {
    try {
      final user = await AuthService().register(
        emailController.text.trim(),
        passwordController.text.trim(),
        usernameController.text.trim(),
      );
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo_light.png',
              height: 100,
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Имейл'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Потребителско име'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Парола'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: register,
              child: const Text('Регистрация'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Вече имаш акаунт? Влез'),
            ),
          ],
        ),
      ),
    );
  }
}
