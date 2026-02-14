import 'package:hive/hive.dart';

part 'vaccine.g.dart';

@HiveType(typeId: 11)
class Vaccine extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String dogId;

  @HiveField(2)
  late String name; // e.g., 'DHPPL', 'Rabies', 'Lepto'

  @HiveField(3)
  late DateTime dateTaken;

  @HiveField(4)
  DateTime? nextDueDate;

  @HiveField(5)
  bool reminderEnabled = true;

  @HiveField(6)
  int? reminderDaysBeforeDue; // Alert this many days before next vaccine is due

  @HiveField(7)
  String? veterinarian;

  @HiveField(8)
  String? notes;

  Vaccine({
    required this.id,
    required this.dogId,
    required this.name,
    required this.dateTaken,
    this.nextDueDate,
    this.reminderEnabled = true,
    this.reminderDaysBeforeDue = 30,
    this.veterinarian,
    this.notes,
  });

  bool isDueForReminder() {
    if (!reminderEnabled || nextDueDate == null) return false;
    
    final daysUntilDue = reminderDaysBeforeDue ?? 30;
    final reminderDate = nextDueDate!.subtract(Duration(days: daysUntilDue));
    
    return DateTime.now().isAfter(reminderDate) && DateTime.now().isBefore(nextDueDate!.add(Duration(days: 1)));
  }

  bool isOverdue() {
    if (nextDueDate == null) return false;
    return DateTime.now().isAfter(nextDueDate!);
  }

  /// Serialize Vaccine to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dogId': dogId,
      'name': name,
      'dateTaken': dateTaken.toIso8601String(),
      'nextDueDate': nextDueDate?.toIso8601String(),
      'reminderEnabled': reminderEnabled,
      'reminderDaysBeforeDue': reminderDaysBeforeDue,
      'veterinarian': veterinarian,
      'notes': notes,
    };
  }

  /// Deserialize Vaccine from Firebase JSON
  factory Vaccine.fromJson(Map<String, dynamic> json) {
    return Vaccine(
      id: json['id'] ?? '',
      dogId: json['dogId'] ?? '',
      name: json['name'] ?? '',
      dateTaken: json['dateTaken'] != null 
          ? DateTime.parse(json['dateTaken']) 
          : DateTime.now(),
      nextDueDate: json['nextDueDate'] != null 
          ? DateTime.parse(json['nextDueDate']) 
          : null,
      reminderEnabled: json['reminderEnabled'] ?? true,
      reminderDaysBeforeDue: json['reminderDaysBeforeDue'] ?? 30,
      veterinarian: json['veterinarian'],
      notes: json['notes'],
    );
  }
}
