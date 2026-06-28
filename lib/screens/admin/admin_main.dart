import 'package:flutter/material.dart';
import 'admin_dashboard.dart';
import 'kelola_jadwal_screen.dart';
import 'update_progres_screen.dart';

class AdminMain extends StatefulWidget {
  const AdminMain({super.key});

  @override
  State<AdminMain> createState() => AdminMainState();
}

class AdminMainState extends State<AdminMain> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AdminDashboard(),
    const KelolaJadwalScreen(),
    const UpdateProgresScreen(),
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
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.approval_outlined),
              activeIcon: Icon(Icons.approval),
              label: 'Persetujuan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_task_rounded),
              activeIcon: Icon(Icons.add_task_rounded),
              label: 'Kelola Jadwal',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.edit_note_rounded),
              activeIcon: Icon(Icons.edit_note_rounded),
              label: 'Update Progres',
            ),
          ],
        ),
      ),
    );
  }
}
