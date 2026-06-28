import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/progres_model.dart';

class ProgresProvider with ChangeNotifier {
  ProgresModel? _currentProgres;
  List<ProgresModel> _allProgres = [];
  bool _isLoading = false;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  ProgresModel? get currentProgres => _currentProgres;
  List<ProgresModel> get allProgres => _allProgres;
  bool get isLoading => _isLoading;

  Future<void> fetchProgresMahasiswa(int mahasiswaId) async {
    _isLoading = true;
    notifyListeners();
    _currentProgres = await _dbHelper.getPregresByMahasiswa(mahasiswaId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAllProgresByDosen(int dosenId) async {
    _isLoading = true;
    notifyListeners();
    _allProgres = await _dbHelper.getAllProgresByDosen(dosenId);
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateProgres(ProgresModel progres) async {
    try {
      int result;
      if (progres.id != null) {
        result = await _dbHelper.updateProgres(progres);
      } else {
        result = await _dbHelper.insertProgres(progres);
      }
      
      if (result > 0) {
        if (_currentProgres?.mahasiswaId == progres.mahasiswaId) {
          _currentProgres = progres;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
