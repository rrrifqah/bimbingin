class ThesisProgress {
  final String chapterName; // e.g., "Bab 1: Pendahuluan"
  final String status; // 'ACC', 'Revisi', 'Belum Mulai', 'Pending'
  final String notes; // Notes from lecturer or staff
  final DateTime lastUpdated;

  ThesisProgress({
    required this.chapterName,
    required this.status,
    required this.notes,
    required this.lastUpdated,
  });

  ThesisProgress copyWith({
    String? status,
    String? notes,
    DateTime? lastUpdated,
  }) {
    return ThesisProgress(
      chapterName: chapterName,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
