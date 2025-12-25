import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Sign Up method
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    setLoading(true);
    final result = await _authService.signUp(
      name: name,
      email: email,
      password: password,
    );
    setLoading(false);
    return result;
  }

  // Sign In method (THIS WAS MISSING!)
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    setLoading(true);
    final result = await _authService.signIn(
      email: email,
      password: password,
    );
    setLoading(false);
    return result;
  }

  // Sign Out method
  Future<void> signOut() async {
    await _authService.signOut();
    notifyListeners();
  }
}
