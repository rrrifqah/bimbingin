import 'package:flutter/material.dart';
import 'mahasiswa_dashboard.dart';
import 'booking_screen.dart';
import 'progres_screen.dart';
// Import halaman profil bersama untuk semua role
import '../shared/profile_screen.dart';

/// Bottom navigation untuk role Mahasiswa.
/// Tab: Dashboard (Daftar Dosen), Booking, Progres, Profil
class MahasiswaMain extends StatefulWidget {
  const MahasiswaMain({super.key});

  @override
  State<MahasiswaMain> createState() => MahasiswaMainState();
}

class MahasiswaMainState extends State<MahasiswaMain> {
  int _currentIndex = 0;

  // Daftar halaman untuk bottom navigation mahasiswa
  // Target Waktu Bimbingan telah dihapus sesuai permintaan
  final List<Widget> _screens = [
    const MahasiswaDashboard(), // Dashboard → Daftar Dosen
    const BookingScreen(),      // Riwayat & Jadwal Booking
    const ProgresScreen(),      // Progres Skripsi
    const ProfileScreen(),      // Profil Mahasiswa
  ];

  void setIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: primaryColor,
          unselectedItemColor: const Color(0xFF9098B1),
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline_rounded),
              activeIcon: Icon(Icons.people_rounded),
              label: 'Dosen',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Booking',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Progres',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
