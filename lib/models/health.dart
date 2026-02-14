import 'package:hive/hive.dart';

part 'health.g.dart';

@HiveType(typeId: 10)
class HealthInfo extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String dogId;

  @HiveField(2)
  String? hdStatus; // 'A', 'B', 'C', 'D', 'E' or null

  @HiveField(3)
  DateTime? hdDate;

  @HiveField(4)
  int? adStatus; // 0=fri, 1=svak, 2=moderat, 3=sterk

  @HiveField(5)
  DateTime? adDate;

  @HiveField(6)
  String? patellaStatus; // 'Normal', 'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4' or null

  @HiveField(7)
  DateTime? patellaDate;

  @HiveField(8)
  String? notes;

  HealthInfo({
    required this.id,
    required this.dogId,
    this.hdStatus,
    this.hdDate,
    this.adStatus,
    this.adDate,
    this.patellaStatus,
    this.patellaDate,
    this.notes,
  });

  bool hasAnyHealthInfo() {
    return hdStatus != null || adStatus != null || patellaStatus != null;
  }

  /// Serialize HealthInfo to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dogId': dogId,
      'hdStatus': hdStatus,
      'hdDate': hdDate?.toIso8601String(),
      'adStatus': adStatus,
      'adDate': adDate?.toIso8601String(),
      'patellaStatus': patellaStatus,
      'patellaDate': patellaDate?.toIso8601String(),
      'notes': notes,
    };
  }

  /// Deserialize HealthInfo from Firebase JSON
  factory HealthInfo.fromJson(Map<String, dynamic> json) {
    return HealthInfo(
      id: json['id'] ?? '',
      dogId: json['dogId'] ?? '',
      hdStatus: json['hdStatus'],
      hdDate: json['hdDate'] != null 
          ? DateTime.parse(json['hdDate']) 
          : null,
      adStatus: json['adStatus'],
      adDate: json['adDate'] != null 
          ? DateTime.parse(json['adDate']) 
          : null,
      patellaStatus: json['patellaStatus'],
      patellaDate: json['patellaDate'] != null 
          ? DateTime.parse(json['patellaDate']) 
          : null,
      notes: json['notes'],
    );
  }
}
