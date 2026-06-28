import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/bimbingan_provider.dart';
import '../../models/student.dart';

class UpdateProgresScreen extends StatefulWidget {
  const UpdateProgresScreen({super.key});

  @override
  State<UpdateProgresScreen> createState() => _UpdateProgresScreenState();
}

class _UpdateProgresScreenState extends State<UpdateProgresScreen> {
  String? _selectedStudentId;
  String _selectedChapter = 'Bab 1: Pendahuluan';
  String _selectedStatus = 'ACC';
  final TextEditingController _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<String> _chapters = [
    'Bab 1: Pendahuluan',
    'Bab 2: Tinjauan Pustaka',
    'Bab 3: Metodologi Penelitian',
    'Bab 4: Analisis & Perancangan',
    'Bab 5: Implementasi & Pengujian',
    'Bab 6: Penutup',
  ];

  final List<String> _statuses = ['ACC', 'Revisi', 'Pending', 'Belum Mulai'];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BimbinganProvider>();
    final students = provider.students;
    final primaryColor = Theme.of(context).primaryColor;
    const Color textDark = Color(0xFF2D3142);
    const Color textGrey = Color(0xFF9098B1);

    if (_selectedStudentId == null && students.isNotEmpty) {
      _selectedStudentId = students.first.id;
    }

    final selectedStudent = students.firstWhere(
      (s) => s.id == _selectedStudentId,
      orElse: () => students.first,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Update Progres Mahasiswa',
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
            // Form Card
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
                      'Input Pembaruan Bab',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                    ),
                    const SizedBox(height: 16),

                    // Student Dropdown
                    const Text(
                      'Pilih Mahasiswa',
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
                          value: _selectedStudentId,
                          isExpanded: true,
                          items: students.map((Student s) {
                            return DropdownMenuItem<String>(
                              value: s.id,
                              child: Text('${s.name} (${s.id})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedStudentId = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Chapter Dropdown & Status Selector in Row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pilih Bab',
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
                                    value: _selectedChapter,
                                    isExpanded: true,
                                    items: _chapters.map((String val) {
                                      return DropdownMenuItem<String>(
                                        value: val,
                                        child: Text(val.split(':')[0], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedChapter = value;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Status Baru',
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
                                    value: _selectedStatus,
                                    isExpanded: true,
                                    items: _statuses.map((String val) {
                                      return DropdownMenuItem<String>(
                                        value: val,
                                        child: Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedStatus = value;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Notes input
                    const Text(
                      'Catatan / Feedback Tambahan',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textDark),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Tuliskan catatan perbaikan atau detail ACC...',
                        hintStyle: const TextStyle(color: textGrey, fontWeight: FontWeight.normal),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.all(12),
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
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            provider.updateThesisProgress(
                              _selectedStudentId!,
                              _selectedChapter,
                              _selectedStatus,
                              _notesController.text.trim(),
                            );
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Progres "$_selectedChapter" untuk ${selectedStudent.name} berhasil diperbarui.'),
                                backgroundColor: Colors.green,
                              ),
                            );

                            _notesController.clear();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Update Progres', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Current progress status review
            Text(
              'Detail Progres Saat Ini (${selectedStudent.name})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
            ),
            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: selectedStudent.progress.length,
              itemBuilder: (context, index) {
                final p = selectedStudent.progress[index];

                Color statusColor;
                switch (p.status) {
                  case 'ACC':
                    statusColor = Colors.green;
                    break;
                  case 'Revisi':
                    statusColor = Colors.red;
                    break;
                  case 'Pending':
                    statusColor = Colors.orange;
                    break;
                  default:
                    statusColor = Colors.grey;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 40,
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.chapterName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark),
                            ),
                            if (p.status != 'Belum Mulai' && p.notes.isNotEmpty)
                              Text(
                                p.notes,
                                style: const TextStyle(fontSize: 11, color: textGrey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            else
                              Text(
                                p.status == 'Belum Mulai' ? 'Belum Mulai' : 'Belum ada catatan',
                                style: const TextStyle(fontSize: 11, color: textGrey),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p.status,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ),
                    ],
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
