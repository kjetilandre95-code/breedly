import 'package:hive/hive.dart';

part 'medical_treatment.g.dart';

/// Type of medical treatment
enum TreatmentType {
  deworming,    // Ormekur
  flea,         // Loppemiddel
  tick,         // Flåttmiddel
  heartworm,    // Hjerteorm
  medication,   // Annen medisin
  supplement,   // Kosttilskudd
  other,        // Annet
}

@HiveType(typeId: 25)
class MedicalTreatment extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String dogId;

  @HiveField(2)
  late String name; // Navn på behandling/medisin

  @HiveField(3)
  late String treatmentType; // 'deworming', 'flea', 'tick', 'heartworm', 'medication', 'supplement', 'other'

  @HiveField(4)
  late DateTime dateGiven;

  @HiveField(5)
  DateTime? nextDueDate; // Neste dose-dato

  @HiveField(6)
  int? intervalDays; // Intervall mellom doser i dager

  @HiveField(7)
  String? dosage; // Dosering

  @HiveField(8)
  String? manufacturer; // Produsent/merke

  @HiveField(9)
  String? batchNumber; // Batchnummer

  @HiveField(10)
  bool reminderEnabled = true;

  @HiveField(11)
  int? reminderDaysBefore; // Varsle X dager før

  @HiveField(12)
  String? notes;

  @HiveField(13)
  String? veterinarian;

  MedicalTreatment({
    required this.id,
    required this.dogId,
    required this.name,
    required this.treatmentType,
    required this.dateGiven,
    this.nextDueDate,
    this.intervalDays,
    this.dosage,
    this.manufacturer,
    this.batchNumber,
    this.reminderEnabled = true,
    this.reminderDaysBefore = 7,
    this.notes,
    this.veterinarian,
  });

  bool isDue() {
    if (nextDueDate == null) return false;
    return DateTime.now().isAfter(nextDueDate!);
  }

  bool isDueForReminder() {
    if (!reminderEnabled || nextDueDate == null) return false;
    
    final daysUntilDue = reminderDaysBefore ?? 7;
    final reminderDate = nextDueDate!.subtract(Duration(days: daysUntilDue));
    
    return DateTime.now().isAfter(reminderDate) && DateTime.now().isBefore(nextDueDate!);
  }

  int? daysUntilDue() {
    if (nextDueDate == null) return null;
    return nextDueDate!.difference(DateTime.now()).inDays;
  }

  String get treatmentTypeDisplay {
    switch (treatmentType) {
      case 'deworming': return 'Ormekur';
      case 'flea': return 'Loppemiddel';
      case 'tick': return 'Flåttmiddel';
      case 'heartworm': return 'Hjerteorm';
      case 'medication': return 'Medisin';
      case 'supplement': return 'Kosttilskudd';
      case 'other': return 'Annet';
      default: return treatmentType;
    }
  }

  /// Serialize MedicalTreatment to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dogId': dogId,
      'name': name,
      'treatmentType': treatmentType,
      'dateGiven': dateGiven.toIso8601String(),
      'nextDueDate': nextDueDate?.toIso8601String(),
      'intervalDays': intervalDays,
      'dosage': dosage,
      'manufacturer': manufacturer,
      'batchNumber': batchNumber,
      'reminderEnabled': reminderEnabled,
      'reminderDaysBefore': reminderDaysBefore,
      'notes': notes,
      'veterinarian': veterinarian,
    };
  }

  /// Deserialize MedicalTreatment from Firebase JSON
  factory MedicalTreatment.fromJson(Map<String, dynamic> json) {
    return MedicalTreatment(
      id: json['id'] ?? '',
      dogId: json['dogId'] ?? '',
      name: json['name'] ?? '',
      treatmentType: json['treatmentType'] ?? 'other',
      dateGiven: json['dateGiven'] != null 
          ? DateTime.parse(json['dateGiven']) 
          : DateTime.now(),
      nextDueDate: json['nextDueDate'] != null 
          ? DateTime.parse(json['nextDueDate']) 
          : null,
      intervalDays: json['intervalDays'],
      dosage: json['dosage'],
      manufacturer: json['manufacturer'],
      batchNumber: json['batchNumber'],
      reminderEnabled: json['reminderEnabled'] ?? true,
      reminderDaysBefore: json['reminderDaysBefore'] ?? 7,
      notes: json['notes'],
      veterinarian: json['veterinarian'],
    );
  }
}
