class Lecturer {
  final String id; // NIP
  final String name;
  final String department;
  final String avatarUrl;
  final List<String> availableSlots; // List of times, e.g., ["09:00 WIB", "10:30 WIB"]

  Lecturer({
    required this.id,
    required this.name,
    required this.department,
    required this.avatarUrl,
    required this.availableSlots,
  });

  Lecturer copyWith({
    List<String>? availableSlots,
  }) {
    return Lecturer(
      id: this.id,
      name: this.name,
      department: this.department,
      avatarUrl: this.avatarUrl,
      availableSlots: availableSlots ?? this.availableSlots,
    );
  }
}
