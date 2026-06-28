import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bimbingan_provider.dart';
import '../../models/student.dart';
import '../../models/lecturer.dart';
import 'mahasiswa_main.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _selectedDateIndex = 1; // Default: Selasa
  String? _selectedTimeSlot;
  final TextEditingController _purposeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<Map<String, String>> _dates = [
    {'hari': 'Senin', 'tanggal': '25', 'bulan': 'Mei 2026'},
    {'hari': 'Selasa', 'tanggal': '26', 'bulan': 'Mei 2026'},
    {'hari': 'Rabu', 'tanggal': '27', 'bulan': 'Mei 2026'},
    {'hari': 'Kamis', 'tanggal': '28', 'bulan': 'Mei 2026'},
    {'hari': 'Jumat', 'tanggal': '29', 'bulan': 'Mei 2026'},
  ];

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BimbinganProvider>();
    final student = provider.currentStudent;
    final primaryColor = Theme.of(context).primaryColor;
    const Color textDark = Color(0xFF2D3142);
    const Color textGrey = Color(0xFF9098B1);

    if (student == null) {
      return const Scaffold(
        body: Center(child: Text('Data Mahasiswa Tidak Ditemukan')),
      );
    }

    // Student's advisor
    final advisor = provider.lecturers.firstWhere(
      (l) => l.id == student.advisorId,
      orElse: () => provider.lecturers.first,
    );

    final selectedDateMap = _dates[_selectedDateIndex];
    final selectedDateStr = '${selectedDateMap['hari']}, ${selectedDateMap['tanggal']} ${selectedDateMap['bulan']}';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Booking Jadwal',
          style: TextStyle(fontWeight: FontWeight.bold, color: textDark),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Advisor Info Card
              const Text(
                'Dosen Pembimbing Anda',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(advisor.avatarUrl),
                      radius: 30,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            advisor.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            advisor.department,
                            style: const TextStyle(fontSize: 12, color: textGrey),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'NIP: ${advisor.id}',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Calendar Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pilih Tanggal Pertemuan',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
                  ),
                  Text(
                    'Mei 2026',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 85,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _dates.length,
                  itemBuilder: (context, index) {
                    bool isSelected = _selectedDateIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDateIndex = index;
                          _selectedTimeSlot = null; // Reset time slot on date change
                        });
                      },
                      child: Container(
                        width: 72,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected ? null : Border.all(color: Colors.grey.shade200),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _dates[index]['hari']!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white70 : textGrey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _dates[index]['tanggal']!,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Time Slot Grid
              Text(
                'Pilih Slot Waktu (${selectedDateMap['hari']})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
              ),
              const SizedBox(height: 12),
              
              if (advisor.availableSlots.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('Dosen tidak memiliki slot aktif.', style: TextStyle(color: textGrey)),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: advisor.availableSlots.length,
                  itemBuilder: (context, index) {
                    final slot = advisor.availableSlots[index];
                    
                    // Check if this slot is already booked for this lecturer on this date
                    final isBooked = provider.bookings.any(
                      (b) => b.lecturerId == advisor.id &&
                             b.date == selectedDateStr &&
                             b.timeSlot == slot &&
                             (b.status == 'Approved' || b.status == 'Pending' || b.status == 'Completed')
                    );

                    final isSelected = _selectedTimeSlot == slot;

                    return InkWell(
                      onTap: isBooked
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Slot waktu ini sudah dibooking. Silakan pilih slot lain.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          : () {
                              setState(() {
                                _selectedTimeSlot = slot;
                              });
                            },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isBooked 
                              ? Colors.grey.shade100 
                              : (isSelected ? primaryColor : Colors.white),
                          border: Border.all(
                            color: isBooked
                                ? Colors.grey.shade200
                                : (isSelected ? primaryColor : Colors.grey.shade300),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              slot,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isBooked
                                    ? Colors.grey.shade400
                                    : (isSelected ? Colors.white : primaryColor),
                              ),
                            ),
                            if (isBooked)
                              const Text(
                                'Booked',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),

              // Booking Purpose Form
              const Text(
                'Keperluan Konsultasi',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _purposeController,
                maxLines: 4,
                style: const TextStyle(fontSize: 14, color: textDark, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Tuliskan detail pembahasan bimbingan (misal: Konsultasi perbaikan bab 1, review metodologi penelitian)...',
                  hintStyle: const TextStyle(color: textGrey, fontWeight: FontWeight.normal),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: primaryColor, width: 1.5),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Harap isi keperluan konsultasi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (_selectedTimeSlot == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Harap pilih slot waktu bimbingan!'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      // Create booking via Provider
                      provider.createBooking(
                        student.id,
                        advisor.id,
                        selectedDateStr,
                        _selectedTimeSlot!,
                        _purposeController.text,
                      );

                      // Dialog / feedback
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 28),
                              SizedBox(width: 8),
                              Text('Sukses Booking!'),
                            ],
                          ),
                          content: Text(
                            'Jadwal Anda dengan ${advisor.name} pada hari $selectedDateStr pukul $_selectedTimeSlot telah diajukan ke Staf/Admin.',
                            style: const TextStyle(fontSize: 14),
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context); // Pop dialog
                                // Clear inputs
                                _purposeController.clear();
                                setState(() {
                                  _selectedTimeSlot = null;
                                });
                                // Go back to dashboard
                                final parentState = context.findAncestorStateOfType<MahasiswaMainState>();
                                if (parentState != null) {
                                  parentState.setIndex(0); // Switch to Dashboard tab
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('OK', style: TextStyle(color: Colors.white)),
                            )
                          ],
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: primaryColor.withOpacity(0.3),
                  ),
                  child: const Text(
                    'Ajukan Jadwal Bimbingan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
