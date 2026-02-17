import 'package:hive/hive.dart';

part 'dog.g.dart';

@HiveType(typeId: 1)
class Dog extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String breed;

  @HiveField(3)
  late String color;

  @HiveField(4)
  late DateTime dateOfBirth;

  @HiveField(5)
  late String gender; // 'Male' or 'Female'

  @HiveField(6)
  String? registrationNumber;

  @HiveField(7)
  String? notes;

  @HiveField(8)
  String? damId; // Mother's ID

  @HiveField(9)
  String? sireId; // Father's ID

  @HiveField(10)
  List<DateTime> heatCycles = []; // Heat cycle dates for females

  @HiveField(11)
  String? healthInfoId; // Reference to HealthInfo object

  @HiveField(12)
  List<String>? vaccineIds; // List of Vaccine object IDs

  @HiveField(13)
  List<String> championships = []; // Liste over championater/titler

  @HiveField(14)
  DateTime? deathDate; // Death date for the dog

  @HiveField(15)
  bool isPedigreeOnly = false; // True for dogs that only exist in pedigrees

  @HiveField(16)
  bool tilleggskravCompleted = false; // NKK tilleggskrav for NO UCH fulfilled

  Dog({
    required this.id,
    required this.name,
    required this.breed,
    required this.color,
    required this.dateOfBirth,
    required this.gender,
    this.registrationNumber,
    this.notes,
    this.damId,
    this.sireId,
    this.heatCycles = const [],
    this.healthInfoId,
    this.vaccineIds,
    this.championships = const [],
    this.deathDate,
    this.isPedigreeOnly = false,
    this.tilleggskravCompleted = false,
  });

  int getAgeInYears() {
    final endDate = deathDate ?? DateTime.now();
    return endDate.difference(dateOfBirth).inDays ~/ 365;
  }

  int getAgeInMonths() {
    final now = deathDate ?? DateTime.now();
    final months =
        (now.year - dateOfBirth.year) * 12 + (now.month - dateOfBirth.month);
    return months;
  }

  /// Calculate the average interval between heat cycles in days
  double? getAverageHeatCycleInterval() {
    if (heatCycles.length < 2) return null;
    
    final sortedCycles = List<DateTime>.from(heatCycles)..sort();
    final intervals = <int>[];
    
    for (int i = 1; i < sortedCycles.length; i++) {
      final interval = sortedCycles[i].difference(sortedCycles[i - 1]).inDays;
      intervals.add(interval);
    }
    
    if (intervals.isEmpty) return null;
    
    return intervals.reduce((a, b) => a + b) / intervals.length;
  }

  /// Estimate the next heat cycle date based on average interval
  DateTime? getNextEstimatedHeatCycle() {
    if (heatCycles.isEmpty) return null;
    
    // Find the most recent heat cycle date
    final mostRecentCycle = heatCycles.reduce((a, b) => a.isAfter(b) ? a : b);
    
    final averageInterval = getAverageHeatCycleInterval();
    if (averageInterval == null) {
      // If no average available, use default 6 months (180 days)
      return mostRecentCycle.add(const Duration(days: 180));
    }
    
    return mostRecentCycle.add(Duration(days: averageInterval.round()));
  }

  /// Serialize Dog to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'color': color,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'registrationNumber': registrationNumber,
      'notes': notes,
      'damId': damId,
      'sireId': sireId,
      'heatCycles': heatCycles.map((d) => d.toIso8601String()).toList(),
      'healthInfoId': healthInfoId,
      'vaccineIds': vaccineIds,
      'championships': championships,
      'deathDate': deathDate?.toIso8601String(),
      'isPedigreeOnly': isPedigreeOnly,
      'tilleggskravCompleted': tilleggskravCompleted,
    };
  }

  /// Deserialize Dog from Firebase JSON
  factory Dog.fromJson(Map<String, dynamic> json) {
    return Dog(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      breed: json['breed'] ?? '',
      color: json['color'] ?? '',
      dateOfBirth: json['dateOfBirth'] != null 
          ? DateTime.parse(json['dateOfBirth']) 
          : DateTime.now(),
      gender: json['gender'] ?? 'Male',
      registrationNumber: json['registrationNumber'],
      notes: json['notes'],
      damId: json['damId'],
      sireId: json['sireId'],
      heatCycles: (json['heatCycles'] as List<dynamic>?)
              ?.map((d) => DateTime.parse(d as String))
              .toList() ??
          [],
      healthInfoId: json['healthInfoId'],
      vaccineIds: (json['vaccineIds'] as List<dynamic>?)?.cast<String>(),
      championships: (json['championships'] as List<dynamic>?)?.cast<String>() ?? [],
      deathDate: json['deathDate'] != null 
          ? DateTime.parse(json['deathDate']) 
          : null,
      isPedigreeOnly: json['isPedigreeOnly'] ?? false,
      tilleggskravCompleted: json['tilleggskravCompleted'] ?? false,
    );
  }
}
