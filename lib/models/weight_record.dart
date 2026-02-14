import 'package:hive/hive.dart';

part 'weight_record.g.dart';

@HiveType(typeId: 27)
class WeightRecord extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String dogId;

  @HiveField(2)
  late DateTime date;

  @HiveField(3)
  late double weightKg; // Vekt i kg

  @HiveField(4)
  String? notes;

  WeightRecord({
    required this.id,
    required this.dogId,
    required this.date,
    required this.weightKg,
    this.notes,
  });

  /// Konverter til gram
  int get weightGrams => (weightKg * 1000).round();

  /// Formattert vekt
  String get formattedWeight {
    if (weightKg < 1) {
      return '$weightGrams g';
    } else if (weightKg < 10) {
      return '${weightKg.toStringAsFixed(2)} kg';
    } else {
      return '${weightKg.toStringAsFixed(1)} kg';
    }
  }

  /// Serialize WeightRecord to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dogId': dogId,
      'date': date.toIso8601String(),
      'weightKg': weightKg,
      'notes': notes,
    };
  }

  /// Deserialize WeightRecord from Firebase JSON
  factory WeightRecord.fromJson(Map<String, dynamic> json) {
    return WeightRecord(
      id: json['id'] ?? '',
      dogId: json['dogId'] ?? '',
      date: json['date'] != null 
          ? DateTime.parse(json['date']) 
          : DateTime.now(),
      weightKg: (json['weightKg'] ?? 0).toDouble(),
      notes: json['notes'],
    );
  }
}
