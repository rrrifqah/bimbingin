import 'package:flutter/material.dart';
import '../models/lecturer.dart';
import '../models/student.dart';
import '../models/booking.dart';
import '../models/thesis_progress.dart';

class BimbinganProvider with ChangeNotifier {
  // Current logged in session
  String? _currentUserId;
  String? _currentUserRole;

  String? get currentUserId => _currentUserId;
  String? get currentUserRole => _currentUserRole;

  // Mock Lecturers
  final List<Lecturer> _lecturers = [
    Lecturer(
      id: '1985010101',
      name: 'Dr. Budi Santoso, M.Kom',
      department: 'Teknik Informatika',
      avatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
      availableSlots: ['09:00 WIB', '10:30 WIB', '14:00 WIB'],
    ),
    Lecturer(
      id: '1989020202',
      name: 'Siti Aminah, S.T., M.T.',
      department: 'Sistem Informasi',
      avatarUrl:
          'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=200',
      availableSlots: ['08:00 WIB', '10:00 WIB', '13:00 WIB', '15:00 WIB'],
    ),
    Lecturer(
      id: '1975030303',
      name: 'Prof. Dr. Andi Wijaya',
      department: 'Teknologi Informasi',
      avatarUrl:
          'https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&q=80&w=200',
      availableSlots: ['09:00 WIB', '11:00 WIB', '14:00 WIB'],
    ),
  ];

  // Mock Students
  final List<Student> _students = [
    Student(
      id: '1302200001',
      name: 'Andi Susanto',
      department: 'Teknik Informatika',
      thesisTitle: 'Implementasi Flutter untuk Sistem Booking Bimbingan Dosen',
      advisorId: '1985010101',
      daysWaiting: 5,
      daysRemaining: 65,
      progress: [
        ThesisProgress(
          chapterName: 'Bab 1: Pendahuluan',
          status: 'ACC',
          notes:
              'Pendahuluan sudah lengkap, batasan masalah sangat jelas. Lanjutkan ke Bab 2.',
          lastUpdated: DateTime.now().subtract(const Duration(days: 10)),
        ),
        ThesisProgress(
          chapterName: 'Bab 2: Tinjauan Pustaka',
          status: 'Revisi',
          notes:
              'Tambahkan studi literatur terbaru tentang Flutter State Management dan efisiensi booking.',
          lastUpdated: DateTime.now().subtract(const Duration(days: 4)),
        ),
        ThesisProgress(
          chapterName: 'Bab 3: Metodologi Penelitian',
          status: 'Belum Mulai',
          notes: '',
          lastUpdated: DateTime.now(),
        ),
        ThesisProgress(
          chapterName: 'Bab 4: Analisis & Perancangan',
          status: 'Belum Mulai',
          notes: '',
          lastUpdated: DateTime.now(),
        ),
        ThesisProgress(
          chapterName: 'Bab 5: Implementasi & Pengujian',
          status: 'Belum Mulai',
          notes: '',
          lastUpdated: DateTime.now(),
        ),
        ThesisProgress(
          chapterName: 'Bab 6: Penutup',
          status: 'Belum Mulai',
          notes: '',
          lastUpdated: DateTime.now(),
        ),
      ],
    ),
    Student(
      id: '1302205678',
      name: 'Rina Melati',
      department: 'Sistem Informasi',
      thesisTitle: 'Analisis Keamanan Sistem Autentikasi Menggunakan OAuth 2.0',
      advisorId: '1989020202',
      daysWaiting: 2,
      daysRemaining: 90,
      progress: [
        ThesisProgress(
          chapterName: 'Bab 1: Pendahuluan',
          status: 'Pending',
          notes: 'Sedang ditinjau oleh dosen pembimbing.',
          lastUpdated: DateTime.now().subtract(const Duration(days: 2)),
        ),
        ThesisProgress(
          chapterName: 'Bab 2: Tinjauan Pustaka',
          status: 'Belum Mulai',
          notes: '',
          lastUpdated: DateTime.now(),
        ),
        ThesisProgress(
          chapterName: 'Bab 3: Metodologi Penelitian',
          status: 'Belum Mulai',
          notes: '',
          lastUpdated: DateTime.now(),
        ),
        ThesisProgress(
          chapterName: 'Bab 4: Analisis & Perancangan',
          status: 'Belum Mulai',
          notes: '',
          lastUpdated: DateTime.now(),
        ),
        ThesisProgress(
          chapterName: 'Bab 5: Implementasi & Pengujian',
          status: 'Belum Mulai',
          notes: '',
          lastUpdated: DateTime.now(),
        ),
        ThesisProgress(
          chapterName: 'Bab 6: Penutup',
          status: 'Belum Mulai',
          notes: '',
          lastUpdated: DateTime.now(),
        ),
      ],
    ),
  ];

  // Mock Bookings
  final List<Booking> _bookings = [
    Booking(
      id: 'B001',
      studentId: '1302200001',
      lecturerId: '1985010101',
      date: 'Senin, 25 Mei 2026',
      timeSlot: '09:00 WIB',
      purpose: 'Konsultasi revisi Bab 2 mengenai diagram kelas.',
      status: 'Pending',
    ),
    Booking(
      id: 'B002',
      studentId: '1302205678',
      lecturerId: '1989020202',
      date: 'Selasa, 26 Mei 2026',
      timeSlot: '10:00 WIB',
      purpose: 'Diskusi rancangan pustaka OAuth dan rumusan masalah.',
      status: 'Approved',
    ),
    Booking(
      id: 'B003',
      studentId: '1302200001',
      lecturerId: '1985010101',
      date: 'Jumat, 22 Mei 2026',
      timeSlot: '14:00 WIB',
      purpose: 'Asistensi Bab 1 Pendahuluan (Selesai).',
      status: 'Completed',
    ),
  ];

  // Getters
  List<Lecturer> get lecturers => _lecturers;
  List<Student> get students => _students;
  List<Booking> get bookings => _bookings;

  // Active user details helper
  Student? get currentStudent {
    if (_currentUserRole == 'Mahasiswa' && _currentUserId != null) {
      return _students.firstWhere(
        (s) =>
            s.id == _currentUserId ||
            s.name.toLowerCase() == _currentUserId!.toLowerCase(),
        orElse: () => _students.first,
      );
    }
    return null;
  }

  Lecturer? get currentLecturer {
    if (_currentUserRole == 'Dosen' && _currentUserId != null) {
      return _lecturers.firstWhere(
        (l) =>
            l.id == _currentUserId ||
            l.name.toLowerCase() == _currentUserId!.toLowerCase(),
        orElse: () => _lecturers.first,
      );
    }
    return null;
  }

  // Authentication
  bool login(String username, String role) {
    if (username.trim().isEmpty) return false;

    _currentUserRole = role;
    if (role == 'Mahasiswa') {
      // Find match or use first student for test simplicity
      final match = _students.firstWhere(
        (s) =>
            s.id == username ||
            s.name.toLowerCase().contains(username.toLowerCase()),
        orElse: () => _students.first,
      );
      _currentUserId = match.id;
    } else if (role == 'Dosen') {
      final match = _lecturers.firstWhere(
        (l) =>
            l.id == username ||
            l.name.toLowerCase().contains(username.toLowerCase()),
        orElse: () => _lecturers.first,
      );
      _currentUserId = match.id;
    } else {
      // Admin/Staf
      _currentUserId = 'ADMIN';
    }
    notifyListeners();
    return true;
  }

  void logout() {
    _currentUserId = null;
    _currentUserRole = null;
    notifyListeners();
  }

  // Bookings
  void createBooking(
    String studentId,
    String lecturerId,
    String date,
    String timeSlot,
    String purpose,
  ) {
    final newId = 'B${(_bookings.length + 1).toString().padLeft(3, '0')}';
    final booking = Booking(
      id: newId,
      studentId: studentId,
      lecturerId: lecturerId,
      date: date,
      timeSlot: timeSlot,
      purpose: purpose,
      status: 'Pending',
    );
    _bookings.add(booking);

    // Increment student waiting days
    final studentIndex = _students.indexWhere((s) => s.id == studentId);
    if (studentIndex != -1) {
      _students[studentIndex] = _students[studentIndex].copyWith(
        daysWaiting: _students[studentIndex].daysWaiting + 1,
      );
    }
    notifyListeners();
  }

  void approveBooking(String bookingId) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index] = _bookings[index].copyWith(status: 'Approved');
      notifyListeners();
    }
  }

  void rejectBooking(String bookingId) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index] = _bookings[index].copyWith(status: 'Rejected');
      notifyListeners();
    }
  }

  void validateAttendance(String bookingId) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index] = _bookings[index].copyWith(status: 'Completed');
      notifyListeners();
    }
  }

  // Schedule Slot Management
  void addLecturerSlot(String lecturerId, String timeSlot) {
    final index = _lecturers.indexWhere((l) => l.id == lecturerId);
    if (index != -1) {
      final updatedSlots = List<String>.from(_lecturers[index].availableSlots);
      if (!updatedSlots.contains(timeSlot)) {
        updatedSlots.add(timeSlot);
        _lecturers[index] = _lecturers[index].copyWith(
          availableSlots: updatedSlots,
        );
        notifyListeners();
      }
    }
  }

  // Thesis Progress Management
  void updateThesisProgress(
    String studentId,
    String chapterName,
    String status,
    String notes,
  ) {
    final studentIndex = _students.indexWhere((s) => s.id == studentId);
    if (studentIndex != -1) {
      final updatedProgress = _students[studentIndex].progress.map((tp) {
        if (tp.chapterName == chapterName) {
          return tp.copyWith(
            status: status,
            notes: notes,
            lastUpdated: DateTime.now(),
          );
        }
        return tp;
      }).toList();

      _students[studentIndex] = _students[studentIndex].copyWith(
        progress: updatedProgress,
      );
      notifyListeners();
    }
  }
}
