import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bimbingan_provider.dart';
import '../../models/lecturer.dart';

class KelolaJadwalScreen extends StatefulWidget {
  const KelolaJadwalScreen({super.key});

  @override
  State<KelolaJadwalScreen> createState() => _KelolaJadwalScreenState();
}

class _KelolaJadwalScreenState extends State<KelolaJadwalScreen> {
  String? _selectedLecturerId;
  final TextEditingController _slotController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _slotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BimbinganProvider>();
    final lecturers = provider.lecturers;
    final primaryColor = Theme.of(context).primaryColor;
    const Color textDark = Color(0xFF2D3142);
    const Color textGrey = Color(0xFF9098B1);

    // Set default lecturer if null
    if (_selectedLecturerId == null && lecturers.isNotEmpty) {
      _selectedLecturerId = lecturers.first.id;
    }

    final selectedLecturer = lecturers.firstWhere(
      (l) => l.id == _selectedLecturerId,
      orElse: () => lecturers.first,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Kelola Jadwal Dosen',
          style: TextStyle(fontWeight: FontWeight.bold, color: textDark),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input form card
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Input Slot Jadwal Baru',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                    ),
                    const SizedBox(height: 16),

                    // Lecturer Dropdown
                    const Text(
                      'Pilih Dosen',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textDark),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedLecturerId,
                          isExpanded: true,
                          items: lecturers.map((Lecturer l) {
                            return DropdownMenuItem<String>(
                              value: l.id,
                              child: Text(l.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedLecturerId = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Time Slot Input
                    const Text(
                      'Slot Waktu (contoh: 09:00 WIB, 11:00 WIB)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textDark),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _slotController,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Masukkan slot waktu bimbingan...',
                        hintStyle: const TextStyle(color: textGrey, fontWeight: FontWeight.normal),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Harap isi slot waktu bimbingan';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final slotText = _slotController.text.trim();
                            
                            provider.addLecturerSlot(_selectedLecturerId!, slotText);
                            _slotController.clear();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Slot "$slotText" berhasil ditambahkan untuk ${selectedLecturer.name}.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Tambahkan Slot', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // List of slots card
            Text(
              'Slot Waktu Aktif (${selectedLecturer.name})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
            ),
            const SizedBox(height: 12),

            if (selectedLecturer.availableSlots.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                alignment: Alignment.center,
                child: const Text('Belum ada slot waktu untuk dosen ini.', style: TextStyle(color: textGrey)),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: selectedLecturer.availableSlots.length,
                itemBuilder: (context, index) {
                  final slot = selectedLecturer.availableSlots[index];

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: primaryColor.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      slot,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
