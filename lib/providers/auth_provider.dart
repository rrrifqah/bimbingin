import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoggedIn = false;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('user_id');
    if (userId != null) {
      _currentUser = await _dbHelper.getUserById(userId);
      if (_currentUser != null) {
        _isLoggedIn = true;
      }
    }
    notifyListeners();
  }

  Future<bool> login(String nimNip, String password) async {
    final user = await _dbHelper.login(nimNip, password);
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

  Future<void> logout() async {
    _currentUser = null;
    _isLoggedIn = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    notifyListeners();
  }
}
