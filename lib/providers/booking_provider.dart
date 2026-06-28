import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/booking_model.dart';
import '../models/jadwal_model.dart';

class BookingProvider with ChangeNotifier {
  List<BookingModel> _bookingList = [];
  bool _isLoading = false;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<BookingModel> get bookingList => _bookingList;
  bool get isLoading => _isLoading;

  Future<void> fetchBookingByMahasiswa(int mahasiswaId) async {
    _isLoading = true;
    notifyListeners();
    _bookingList = await _dbHelper.getBookingByMahasiswa(mahasiswaId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchBookingByDosen(int dosenId) async {
    _isLoading = true;
    notifyListeners();
    _bookingList = await _dbHelper.getBookingByDosen(dosenId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAllBooking() async {
    _isLoading = true;
    notifyListeners();
    _bookingList = await _dbHelper.getAllBooking();
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createBooking(BookingModel booking) async {
    try {
      int result = await _dbHelper.insertBooking(booking);
      if (result > 0) {
        // Also update jadwal status to penuh
        await _dbHelper.updateStatusJadwal(booking.jadwalId, 'penuh');
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateStatusBooking(int id, String status, String? catatan) async {
    try {
      int result = await _dbHelper.updateStatusBooking(id, status, catatan);
      if (result > 0) {
        // Update local list
        int index = _bookingList.indexWhere((b) => b.id == id);
        if (index != -1) {
          _bookingList[index] = _bookingList[index].copyWith(
            status: status,
            catatanStaf: catatan,
          );
          notifyListeners();
        }
        
        // If rejected, free up the schedule
        if (status == 'rejected') {
          BookingModel? booking = await _dbHelper.getBookingById(id);
          if (booking != null) {
            await _dbHelper.updateStatusJadwal(booking.jadwalId, 'tersedia');
          }
        }
        
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
