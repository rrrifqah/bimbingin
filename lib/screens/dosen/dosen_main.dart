import 'package:flutter/material.dart';
import 'dosen_dashboard.dart';
import 'jadwal_screen.dart';
import '../shared/profile_screen.dart';
import '../../widgets/floating_curved_navbar.dart';

class DosenMain extends StatefulWidget {
  const DosenMain({super.key});

  @override
  State<DosenMain> createState() => DosenMainState();
}

class DosenMainState extends State<DosenMain> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DosenDashboard(),
    const JadwalScreen(),
    const ProfileScreen(),
  ];

  void setIndex(int index) {
    setState(() => _currentIndex = index);
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
          Icons.dashboard_outlined,
          Icons.calendar_month_outlined,
          Icons.person_outline_rounded,
        ],
      ),
    );
  }
}
