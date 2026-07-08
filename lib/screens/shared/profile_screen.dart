import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';

/// Halaman Profil Pengguna
/// Menampilkan foto profil, nama, email, role, dan tombol edit/logout.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;

  /// Menampilkan bottom sheet untuk memilih sumber foto (galeri/kamera)
  void _showPhotoPickerSheet(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Ganti Foto Profil',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 20),
                // Pilihan: Galeri
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.photo_library_outlined, color: primaryColor),
                  ),
                  title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Pilih foto dari galeri perangkat'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const Divider(height: 1),
                // Pilihan: Kamera
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_outlined, color: Colors.green),
                  ),
                  title: const Text('Ambil Foto', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Foto menggunakan kamera'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                if (context.read<AuthProvider>().currentUser?.foto != null) ...[
                  const Divider(height: 1),
                  // Pilihan: Hapus foto
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                    title: const Text('Hapus Foto', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _removePhoto();
                    },
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Memilih gambar dari sumber yang ditentukan (galeri/kamera) dan menyimpannya sebagai Base64
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 500, // Batasi resolusi agar string base64 tidak terlalu besar
        maxHeight: 500,
        imageQuality: 70, // Kompresi agar optimal
      );

      if (pickedFile != null && mounted) {
        setState(() => _isLoading = true);
        
        final bytes = await pickedFile.readAsBytes();
        final base64Image = base64Encode(bytes);
        
        final auth = context.read<AuthProvider>();
        final user = auth.currentUser;
        
        if (user != null) {
          final updatedUser = user.copyWith(foto: base64Image);
          final success = await auth.updateProfile(updatedUser);
          
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success ? 'Foto profil berhasil diperbarui!' : 'Gagal memperbarui foto profil'),
                backgroundColor: success ? Colors.green : Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih foto: Izin ditolak atau format tidak didukung.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Menghapus foto profil dari database
  Future<void> _removePhoto() async {
    setState(() => _isLoading = true);
    
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    
    if (user != null) {
      // Create a map to force null for foto, since copyWith ignores nulls in this implementation
      // Or we can manually set it in Supabase, but copyWith is fine if we adapt it or directly use a new object.
      // Wait, our UserModel.copyWith does: `foto: foto ?? this.foto`. So passing null won't erase it.
      // We'll create a new UserModel instance without the foto.
      final updatedUser = UserModel(
        id: user.id,
        nama: user.nama,
        nimNip: user.nimNip,
        email: user.email,
        password: user.password,
        role: user.role,
        jurusan: user.jurusan,
        foto: null, // explicitly null
      );
      
      final success = await auth.updateProfile(updatedUser);
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Foto profil dihapus.' : 'Gagal menghapus foto.'),
            backgroundColor: success ? Colors.orange : Colors.red,
          ),
        );
      }
    }
  }

  /// Menampilkan dialog edit profil (nama, jurusan)
  void _showEditProfileDialog(BuildContext context, UserModel user) {
    final primaryColor = Theme.of(context).primaryColor;
    final namaCtrl = TextEditingController(text: user.nama);
    final jurusanCtrl = TextEditingController(text: user.jurusan);
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.edit_outlined, color: primaryColor),
                  const SizedBox(width: 8),
                  const Text('Edit Profil', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Field Nama
                  TextField(
                    controller: namaCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Field Jurusan
                  TextField(
                    controller: jurusanCtrl,
                    decoration: InputDecoration(
                      labelText: 'Jurusan / Bagian',
                      prefixIcon: const Icon(Icons.school_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Batal', style: TextStyle(color: Color(0xFF9098B1))),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (namaCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Nama tidak boleh kosong!'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                          setDialogState(() => isSubmitting = true);
                          // Update user data via AuthProvider
                          final updatedUser = user.copyWith(
                            nama: namaCtrl.text.trim(),
                            jurusan: jurusanCtrl.text.trim(),
                          );
                          
                          final success = await context.read<AuthProvider>().updateProfile(updatedUser);
                          
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Profil berhasil diperbarui!' : 'Gagal memperbarui profil'),
                              backgroundColor: success ? Colors.green : Colors.red,
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Proses logout pengguna
  Future<void> _doLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF9098B1))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isLoading = true);
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      // Navigasi kembali ke halaman login dan bersihkan semua route
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  /// Helper: mendapatkan label role dalam Bahasa Indonesia
  String _getRoleLabel(String role) {
    switch (role) {
      case 'mahasiswa': return 'Mahasiswa';
      case 'dosen': return 'Dosen Pembimbing';
      case 'staf': return 'Staf / Admin';
      default: return role;
    }
  }

  /// Helper: mendapatkan warna badge role
  Color _getRoleColor(String role) {
    switch (role) {
      case 'mahasiswa': return const Color(0xFF3B4FE4);
      case 'dosen': return const Color(0xFF22C55E);
      case 'staf': return const Color(0xFFF59E0B);
      default: return Colors.grey;
    }
  }

  /// Helper: mendapatkan ikon role
  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'mahasiswa': return Icons.school_rounded;
      case 'dosen': return Icons.person_rounded;
      case 'staf': return Icons.admin_panel_settings_rounded;
      default: return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final primaryColor = Theme.of(context).primaryColor;
    const Color textDark = Color(0xFF2D3142);
    const Color textGrey = Color(0xFF9098B1);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final roleColor = _getRoleColor(user.role);
    final roleLabel = _getRoleLabel(user.role);
    final roleIcon = _getRoleIcon(user.role);
    
    // Check if foto is a valid base64 image string
    ImageProvider? imageProvider;
    if (user.foto != null && user.foto!.isNotEmpty) {
        try {
            imageProvider = MemoryImage(base64Decode(user.foto!));
        } catch (_) {
            // Invalid base64, keep it null
        }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Profil Saya',
          style: TextStyle(fontWeight: FontWeight.bold, color: textDark),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ===== AVATAR SECTION =====
                Center(
                  child: Stack(
                    children: [
                      // Foto profil
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryColor.withOpacity(0.3), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: imageProvider != null
                              ? Image(image: imageProvider, fit: BoxFit.cover, errorBuilder: (_,__,___) => _buildDefaultAvatar(user.nama, primaryColor))
                              : _buildDefaultAvatar(user.nama, primaryColor),
                        ),
                      ),
                      // Tombol edit foto
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _showPhotoPickerSheet(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Nama pengguna
                Text(
                  user.nama,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Badge Role
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: roleColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(roleIcon, color: roleColor, size: 16),
                      const SizedBox(width: 6),
                      Text(roleLabel, style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ===== INFO CARD =====
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      // NIM/NIP
                      _buildInfoRow(
                        icon: Icons.badge_outlined,
                        label: 'NIM / NIP',
                        value: user.nimNip,
                        primaryColor: primaryColor,
                      ),
                      const Divider(height: 24),
                      // Email
                      _buildInfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: user.email,
                        primaryColor: primaryColor,
                      ),
                      const Divider(height: 24),
                      // Jurusan
                      _buildInfoRow(
                        icon: Icons.school_outlined,
                        label: 'Jurusan / Bagian',
                        value: user.jurusan,
                        primaryColor: primaryColor,
                      ),
                      const Divider(height: 24),
                      // Role
                      _buildInfoRow(
                        icon: Icons.verified_user_outlined,
                        label: 'Peran',
                        value: roleLabel,
                        primaryColor: primaryColor,
                        valueColor: roleColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ===== TOMBOL EDIT PROFIL =====
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditProfileDialog(context, user),
                    icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                    label: const Text(
                      'Edit Profil',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      shadowColor: primaryColor.withOpacity(0.3),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ===== TOMBOL LOGOUT =====
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _doLogout,
                    icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
                    label: const Text(
                      'Logout',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Versi app
                const Text('Bimbingin v1.0.0', style: TextStyle(fontSize: 11, color: textGrey)),
              ],
            ),
          ),
          
          if (_isLoading)
            Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator())
            )
        ],
      ),
    );
  }

  /// Widget baris informasi profil
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color primaryColor,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: primaryColor, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF9098B1), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? const Color(0xFF2D3142)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Widget avatar default (inisial nama)
  Widget _buildDefaultAvatar(String nama, Color primaryColor) {
    return Container(
      color: primaryColor.withOpacity(0.15),
      child: Center(
        child: Text(
          nama.isNotEmpty ? nama[0].toUpperCase() : 'U',
          style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: primaryColor),
        ),
      ),
    );
  }
}
