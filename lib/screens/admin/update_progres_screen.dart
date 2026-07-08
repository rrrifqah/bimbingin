import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progres_provider.dart';
import '../../providers/target_provider.dart';
import '../../models/progres_model.dart';
import 'admin_main.dart';

class UpdateProgresScreen extends StatefulWidget {
  const UpdateProgresScreen({super.key});

  @override
  State<UpdateProgresScreen> createState() => _UpdateProgresScreenState();
}

class _UpdateProgresScreenState extends State<UpdateProgresScreen> {
  bool _dataLoaded = false;
  String _searchQuery = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dataLoaded) {
      _dataLoaded = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    // Sebagai admin, load semua progres mahasiswa
    // Namun untuk sekarang, kita menggunakan list semua mahasiswa di progres provider
    // Note: Provider belum memiliki getAllTahapAllMahasiswa, mari gunakan yang ada di daftar dosen
    // Kita akan buat fitur read-only, sehingga cukup menampilkan pesan atau jika provider mendukung
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Pantau Progres (Read Only)'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.visibility_rounded, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Sesuai ketentuan, Admin hanya memiliki akses Read-Only untuk progres mahasiswa.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
