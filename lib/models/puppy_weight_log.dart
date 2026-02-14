import 'package:hive/hive.dart';

part 'puppy_weight_log.g.dart';

@HiveType(typeId: 3)
class PuppyWeightLog extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String puppyId;

  @HiveField(2)
  late DateTime logDate;

  @HiveField(3)
  late double weight; // in kg

  @HiveField(4)
  String? notes;

  PuppyWeightLog({
    required this.id,
    required this.puppyId,
    required this.logDate,
    required this.weight,
    this.notes,
  });

  /// Serialize to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'puppyId': puppyId,
      'logDate': logDate.toIso8601String(),
      'weight': weight,
      'notes': notes,
    };
  }

  /// Deserialize from Firebase JSON
  factory PuppyWeightLog.fromJson(Map<String, dynamic> json) {
    return PuppyWeightLog(
      id: json['id'] ?? '',
      puppyId: json['puppyId'] ?? '',
      logDate: json['logDate'] != null 
          ? DateTime.parse(json['logDate']) 
          : DateTime.now(),
      weight: (json['weight'] ?? 0.0).toDouble(),
      notes: json['notes'],
    );
  }
}
