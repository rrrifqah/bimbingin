import 'package:flutter/material.dart';
import 'mahasiswa_dashboard.dart';
import 'progres_screen.dart';
// Import halaman profil bersama untuk semua role
import '../shared/profile_screen.dart';
import '../../widgets/floating_curved_navbar.dart';

/// Bottom navigation untuk role Mahasiswa.
/// Tab: Dashboard (Daftar Dosen), Progres, Profil
class MahasiswaMain extends StatefulWidget {
  const MahasiswaMain({super.key});

  @override
  State<MahasiswaMain> createState() => MahasiswaMainState();
}

class MahasiswaMainState extends State<MahasiswaMain> {
  int _currentIndex = 0;

  // Daftar halaman untuk bottom navigation mahasiswa
  // Booking dihapus: mahasiswa booking langsung dari card dosen di dashboard
  final List<Widget> _screens = [
    const MahasiswaDashboard(), // Dashboard → Daftar Dosen & Booking
    const ProgresScreen(), // Progres Skripsi
    const ProfileScreen(), // Profil Mahasiswa
  ];

  void setIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: FloatingCurvedNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          Icons.people_outline_rounded,
          Icons.analytics_outlined,
          Icons.person_outline_rounded,
        ],
      ),
    );
  }
}
