import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/jadwal_model.dart';

class JadwalProvider with ChangeNotifier {
  List<JadwalModel> _jadwalList = [];
  bool _isLoading = false;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<JadwalModel> get jadwalList => _jadwalList;
  bool get isLoading => _isLoading;

  Future<void> fetchJadwalDosen(int dosenId) async {
    _isLoading = true;
    notifyListeners();
    _jadwalList = await _dbHelper.getJadwalByDosen(dosenId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchJadwalTersedia(int dosenId) async {
    _isLoading = true;
    notifyListeners();
    _jadwalList = await _dbHelper.getJadwalTersedia(dosenId);
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addJadwal(JadwalModel jadwal) async {
    try {
      int result = await _dbHelper.insertJadwal(jadwal);
      if (result > 0) {
        await fetchJadwalDosen(jadwal.dosenId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateStatusJadwal(int id, String status) async {
    try {
      int result = await _dbHelper.updateStatusJadwal(id, status);
      if (result > 0) {
        int index = _jadwalList.indexWhere((j) => j.id == id);
        if (index != -1) {
          _jadwalList[index] = _jadwalList[index].copyWith(status: status);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
