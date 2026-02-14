import 'package:hive/hive.dart';

part 'temperature_record.g.dart';

@HiveType(typeId: 9)
class TemperatureRecord extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String litterId; // Reference to the litter

  @HiveField(2)
  late DateTime dateTime;

  @HiveField(3)
  late double temperature; // In Celsius

  @HiveField(4)
  String? notes;

  TemperatureRecord({
    required this.id,
    required this.litterId,
    required this.dateTime,
    required this.temperature,
    this.notes,
  });

  // Helper to get temperature reading time
  String getTimeString() {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Serialize to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'litterId': litterId,
      'dateTime': dateTime.toIso8601String(),
      'temperature': temperature,
      'notes': notes,
    };
  }

  /// Deserialize from Firebase JSON
  factory TemperatureRecord.fromJson(Map<String, dynamic> json) {
    return TemperatureRecord(
      id: json['id'] ?? '',
      litterId: json['litterId'] ?? '',
      dateTime: json['dateTime'] != null 
          ? DateTime.parse(json['dateTime']) 
          : DateTime.now(),
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      notes: json['notes'],
    );
  }
}
