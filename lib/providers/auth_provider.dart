import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/supabase_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoggedIn = false;
  final SupabaseService _service = SupabaseService();

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('user_id');
    if (userId != null) {
      _currentUser = await _service.getUserById(userId);
      if (_currentUser != null) {
        _isLoggedIn = true;
      }
    }
    notifyListeners();
  }

  Future<bool> login(String nimNip, String password) async {
    final user = await _service.login(nimNip, password);
    if (user != null) {
      _currentUser = user;
      _isLoggedIn = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', user.id!);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(UserModel user) async {
    try {
      final id = await _service.insertUser(user);
      if (id > 0) {
        final registeredUser = await _service.getUserById(id);
        if (registeredUser != null) {
          _currentUser = registeredUser;
          _isLoggedIn = true;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('user_id', registeredUser.id!);
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Memperbarui data profil pengguna (nama, jurusan) ke Supabase
  Future<bool> updateProfile(UserModel updatedUser) async {
    try {
      await _service.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _isLoggedIn = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    notifyListeners();
  }
}
