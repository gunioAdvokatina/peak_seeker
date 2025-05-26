import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> login(String email, String password, bool rememberMe) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (rememberMe) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('email', email);
    }
    return userCredential.user;
  }

  Future<User?> register(String email, String password, String username) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await userCredential.user?.updateDisplayName(username);
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('email', email);
    return userCredential.user;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    await _auth.signOut();
  }
}
