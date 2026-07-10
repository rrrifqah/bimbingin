class Booking {
  final String id;
  final String studentId;
  final String lecturerId;
  final String date; // e.g., "Senin, 24 Mei 2026"
  final String timeSlot; // e.g., "10:00 WIB"
  final String purpose; // Consultation details
  final String status; // 'Pending', 'Approved', 'Rejected', 'Completed'

  Booking({
    required this.id,
    required this.studentId,
    required this.lecturerId,
    required this.date,
    required this.timeSlot,
    required this.purpose,
    required this.status,
  });

  Booking copyWith({String? status}) {
    return Booking(
      id: id,
      studentId: studentId,
      lecturerId: lecturerId,
      date: date,
      timeSlot: timeSlot,
      purpose: purpose,
      status: status ?? this.status,
    );
  }
}
