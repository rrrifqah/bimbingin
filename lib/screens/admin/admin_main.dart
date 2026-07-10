import 'package:flutter/material.dart';
import 'admin_dashboard.dart';
import 'kelola_mahasiswa_screen.dart';
import 'atur_pembimbing_screen.dart';
// Import halaman profil bersama untuk semua role
import '../shared/profile_screen.dart';
import '../../widgets/floating_curved_navbar.dart';

/// Bottom navigation untuk role Staff/Admin.
/// Menu: Booking, Kelola Data, Atur Pembimbing, Profil
class AdminMain extends StatefulWidget {
  const AdminMain({super.key});

  @override
  State<AdminMain> createState() => AdminMainState();
}

class AdminMainState extends State<AdminMain> {
  int _currentIndex = 0;

  // Daftar halaman untuk bottom navigation admin/staf
  final List<Widget> _screens = [
    const AdminDashboard(), // Kelola Booking
    const KelolaMahasiswaScreen(), // Kelola Mahasiswa
    const AturPembimbingScreen(), // Atur Dosen Pembimbing
    const ProfileScreen(), // Profil Staf
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
          Icons.dashboard_customize_outlined,
          Icons.manage_accounts_outlined,
          Icons.people_alt_outlined,
          Icons.person_outline_rounded,
        ],
      ),
    );
  }
}
