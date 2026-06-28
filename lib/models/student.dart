import 'thesis_progress.dart';

class Student {
  final String id; // NIM
  final String name;
  final String department;
  final String thesisTitle;
  final String advisorId; // NIP
  final int daysWaiting;
  final int daysRemaining;
  final List<ThesisProgress> progress;

  Student({
    required this.id,
    required this.name,
    required this.department,
    required this.thesisTitle,
    required this.advisorId,
    required this.daysWaiting,
    required this.daysRemaining,
    required this.progress,
  });

  Student copyWith({
    int? daysWaiting,
    int? daysRemaining,
    List<ThesisProgress>? progress,
  }) {
    return Student(
      id: this.id,
      name: this.name,
      department: this.department,
      thesisTitle: this.thesisTitle,
      advisorId: this.advisorId,
      daysWaiting: daysWaiting ?? this.daysWaiting,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      progress: progress ?? this.progress,
    );
  }
}
