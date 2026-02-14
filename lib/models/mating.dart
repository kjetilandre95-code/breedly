import 'package:hive/hive.dart';

part 'mating.g.dart';

@HiveType(typeId: 13)
class Mating extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String sireId; // Hannhundens ID

  @HiveField(2)
  late String damId; // Tispens ID

  @HiveField(3)
  String? damName; // Tispens navn (for visning)

  @HiveField(4)
  late DateTime matingDate; // Parringsdato

  @HiveField(5)
  int? puppyCount; // Antall valper (kan være null hvis ukjent)

  @HiveField(6)
  String? notes; // Eventuelle notater

  @HiveField(7)
  String? litterId; // Link til kull hvis det finnes

  Mating({
    required this.id,
    required this.sireId,
    required this.damId,
    this.damName,
    required this.matingDate,
    this.puppyCount,
    this.notes,
    this.litterId,
  });

  /// Serialize Mating to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sireId': sireId,
      'damId': damId,
      'damName': damName,
      'matingDate': matingDate.toIso8601String(),
      'puppyCount': puppyCount,
      'notes': notes,
      'litterId': litterId,
    };
  }

  /// Deserialize Mating from Firebase JSON
  factory Mating.fromJson(Map<String, dynamic> json) {
    return Mating(
      id: json['id'] ?? '',
      sireId: json['sireId'] ?? '',
      damId: json['damId'] ?? '',
      damName: json['damName'],
      matingDate: json['matingDate'] != null 
          ? DateTime.parse(json['matingDate']) 
          : DateTime.now(),
      puppyCount: json['puppyCount'],
      notes: json['notes'],
      litterId: json['litterId'],
    );
  }
}
