import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bimbingan_provider.dart';
import '../../models/booking.dart';
import '../../models/student.dart';
import '../../models/lecturer.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BimbinganProvider>();
    final primaryColor = Theme.of(context).primaryColor;
    const Color textDark = Color(0xFF2D3142);
    const Color textGrey = Color(0xFF9098B1);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Kelola Booking Bimbingan',
          style: TextStyle(fontWeight: FontWeight.bold, color: textDark),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              provider.logout();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: textGrey,
          indicatorColor: primaryColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Antrian'),
            Tab(text: 'Disetujui'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Sub-header info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Colors.white,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, Staf Prodi! 👋',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Persetujuan jadwal bimbingan masuk dari mahasiswa.',
                    style: TextStyle(fontSize: 12, color: textGrey),
                  ),
                ],
              ),
            ),
            
            // Tab contents
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBookingList(
                    context, 
                    provider.bookings.where((b) => b.status == 'Pending').toList(),
                    showActions: true,
                  ),
                  _buildBookingList(
                    context, 
                    provider.bookings.where((b) => b.status == 'Approved').toList(),
                    showActions: false,
                  ),
                  _buildBookingList(
                    context, 
                    provider.bookings.where((b) => b.status == 'Rejected' || b.status == 'Completed').toList(),
                    showActions: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingList(BuildContext context, List<Booking> list, {required bool showActions}) {
    final provider = context.read<BimbinganProvider>();
    final primaryColor = Theme.of(context).primaryColor;
    const Color textDark = Color(0xFF2D3142);
    const Color textGrey = Color(0xFF9098B1);

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              'Tidak ada data booking di tab ini.',
              style: TextStyle(color: textGrey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final booking = list[index];

        // Find Student & Lecturer details
        final student = provider.students.firstWhere(
          (s) => s.id == booking.studentId,
          orElse: () => Student(
            id: booking.studentId,
            name: 'Mahasiswa',
            department: '',
            thesisTitle: '',
            advisorId: '',
            daysWaiting: 0,
            daysRemaining: 0,
            progress: [],
          ),
        );

        final lecturer = provider.lecturers.firstWhere(
          (l) => l.id == booking.lecturerId,
          orElse: () => Lecturer(
            id: booking.lecturerId,
            name: 'Dosen',
            department: '',
            avatarUrl: '',
            availableSlots: [],
          ),
        );

        Color badgeColor;
        switch (booking.status) {
          case 'Approved':
            badgeColor = Colors.green;
            break;
          case 'Rejected':
            badgeColor = Colors.red;
            break;
          case 'Completed':
            badgeColor = Colors.blue;
            break;
          default:
            badgeColor = Colors.orange;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: booking.status == 'Pending' 
                  ? Colors.orange.shade100 
                  : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge status & Code
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      booking.status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ),
                  Text(
                    booking.id,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textGrey),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Student & Lecturer details
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Text(
                      student.name.isNotEmpty ? student.name[0] : 'M',
                      style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 14),
                        ),
                        Text(
                          'NIM: ${student.id} | ${student.department}',
                          style: const TextStyle(color: textGrey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              const Divider(height: 1),
              const SizedBox(height: 8),

              // Dosen & Waktu
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded, size: 14, color: textGrey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Dosen: ${lecturer.name}',
                      style: const TextStyle(fontSize: 12, color: textDark, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: textGrey),
                  const SizedBox(width: 6),
                  Text(
                    'Waktu: ${booking.date} @ ${booking.timeSlot}',
                    style: const TextStyle(fontSize: 12, color: textDark, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: textGrey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Keperluan: ${booking.purpose}',
                      style: const TextStyle(fontSize: 12, color: textDark),
                    ),
                  ),
                ],
              ),

              // Actions
              if (showActions) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          provider.rejectBooking(booking.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Booking ditolak.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Tolak'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          provider.approveBooking(booking.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Booking disetujui.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text('Terima', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
