import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progres_provider.dart';
import '../../providers/booking_provider.dart';
import 'mahasiswa_main.dart';
import '../../database/supabase_service.dart';
import '../../models/user_model.dart';

class MahasiswaDashboard extends StatefulWidget {
  const MahasiswaDashboard({super.key});

  @override
  State<MahasiswaDashboard> createState() => _MahasiswaDashboardState();
}

class _MahasiswaDashboardState extends State<MahasiswaDashboard> {
  bool _dataLoaded = false;

  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _allDosen = [];
  List<UserModel> _filteredDosenList = [];
  final Map<int, bool> _availabilityCache = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dataLoaded) {
      _dataLoaded = true;
      _loadData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getRandomColorForDosen(UserModel doc) {
    final int hash = doc.nama.hashCode;
    final List<Color> colors = [
      const Color(0xFF3B4FE4),
      const Color(0xFF22C55E),
      const Color(0xFFEF4444),
      const Color(0xFFF59E0B),
      const Color(0xFF6C63FF),
      const Color(0xFFEC4899),
      const Color(0xFF8B5CF6),
      const Color(0xFF14B8A6),
      const Color(0xFFF97316),
    ];
    return colors[hash.abs() % colors.length];
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    // Load thesis progress to get title if available
    await context.read<ProgresProvider>().fetchTahapMahasiswa(user.id!);

    // Load lecturers list and apply shared preference sorting
    await _loadDosenList();
  }

  Future<void> _loadDosenList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastClickedId = prefs.getInt('last_clicked_dosen_id');

      final supabase = SupabaseService();
      final lecturers = await supabase.getAllDosen();

      if (lastClickedId != null) {
        final lastClickedIndex = lecturers.indexWhere((l) => l.id == lastClickedId);
        if (lastClickedIndex != -1) {
          final lastClickedDosen = lecturers.removeAt(lastClickedIndex);
          lecturers.insert(0, lastClickedDosen);
        }
      }

      if (mounted) {
        setState(() {
          _allDosen = lecturers;
          _filterDosenList(_searchController.text);
        });
      }

      // Load availability in background
      for (final doc in lecturers) {
        if (!_availabilityCache.containsKey(doc.id)) {
          supabase.dosenPunyaJadwal(doc.id!).then((available) {
            if (mounted) {
              setState(() {
                _availabilityCache[doc.id!] = available;
              });
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading lecturers: $e");
    }
  }

  void _filterDosenList(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredDosenList = List.from(_allDosen);
      });
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    setState(() {
      _filteredDosenList = _allDosen.where((doc) {
        return doc.nama.toLowerCase().contains(lowercaseQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final progresProvider = context.watch<ProgresProvider>();
    final user = auth.currentUser;
    final primaryColor = Theme.of(context).primaryColor;
    const Color textDark = Color(0xFF2D3142);
    const Color textGrey = Color(0xFF9098B1);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final tahapList = progresProvider.tahapMahasiswa;
    final judulSkripsi = tahapList.isNotEmpty ? tahapList.first.judulSkripsi : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Halo 👋,',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: textGrey,
                                  fontWeight: FontWeight.w500),
                            ),
                            Text(
                              user.nama,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'NIM: ${user.nimNip} | ${user.jurusan}',
                              style: const TextStyle(
                                  fontSize: 12, color: textGrey),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final nav = Navigator.of(context);
                          await context.read<AuthProvider>().logout();
                          nav.popUntil((route) => route.isFirst);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.logout_rounded,
                              color: Colors.redAccent, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Title of thesis card
                if (judulSkripsi.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryColor.withValues(alpha: 0.85)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.menu_book_rounded,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Judul Skripsi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '"$judulSkripsi"',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Search Bar Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      _filterDosenList(value);
                    },
                    decoration: InputDecoration(
                      hintText: "Cari nama dosen pembimbing...",
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9098B1)),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF3B4FE4)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                _filterDosenList('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3B4FE4), width: 1.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3B4FE4), width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // List Dosen
                _allDosen.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : _filteredDosenList.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 32.0),
                              child: Text(
                                "Dosen tidak ditemukan",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filteredDosenList.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final doc = _filteredDosenList[index];
                              final hasSchedule = _availabilityCache[doc.id] ?? false;

                              // Decode base64 image if available
                              ImageProvider? imageProvider;
                              if (doc.foto != null && doc.foto!.isNotEmpty) {
                                try {
                                  imageProvider = MemoryImage(base64Decode(doc.foto!));
                                } catch (_) {}
                              }

                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () async {
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.setInt('last_clicked_dosen_id', doc.id!);

                                      if (!context.mounted) return;

                                      setState(() {
                                        final indexInAll = _allDosen.indexWhere((l) => l.id == doc.id);
                                        if (indexInAll != -1) {
                                          final clicked = _allDosen.removeAt(indexInAll);
                                          _allDosen.insert(0, clicked);
                                        }
                                        _filterDosenList(_searchController.text);
                                      });

                                      context.read<BookingProvider>().setSelectedDosenForBooking(doc);
                                      
                                      final rootState = context.findAncestorStateOfType<MahasiswaMainState>();
                                      if (rootState != null) {
                                        rootState.setIndex(1);
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 30, // 60x60
                                            backgroundImage: imageProvider,
                                            backgroundColor: imageProvider == null
                                                ? _getRandomColorForDosen(doc)
                                                : null,
                                            child: imageProvider == null
                                                ? Text(
                                                    doc.nama.isNotEmpty ? doc.nama[0].toUpperCase() : 'D',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 24,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  doc.nama,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: Color(0xFF2D3142),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  doc.jurusan,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: hasSchedule
                                                        ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                                                        : Colors.grey.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    hasSchedule ? 'Tersedia' : 'Penuh',
                                                    style: TextStyle(
                                                      color: hasSchedule ? const Color(0xFF22C55E) : Colors.grey.shade600,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
