import 'package:hive/hive.dart';

part 'puppy.g.dart';

@HiveType(typeId: 2)
class Puppy extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String litterId;

  @HiveField(3)
  late DateTime dateOfBirth;

  @HiveField(4)
  late String gender; // 'Male' or 'Female'

  @HiveField(5)
  late String color;

  @HiveField(6)
  String? registrationNumber;

  @HiveField(7)
  String? buyerName;

  @HiveField(8)
  String? buyerContact;

  @HiveField(9)
  String? status; // 'Available', 'Sold', 'Reserved', 'Delivered'

  @HiveField(10)
  DateTime? soldDate;

  @HiveField(18)
  DateTime? deliveredDate;

  @HiveField(11)
  String? notes;

  @HiveField(12)
  late bool vaccinated;

  @HiveField(13)
  late bool dewormed;

  @HiveField(14)
  late bool microchipped;

  @HiveField(15)
  double? birthWeight;

  @HiveField(16)
  DateTime? birthTime;

  @HiveField(17)
  String? birthNotes;

  @HiveField(19)
  String? displayName; // Kallenavn for å skille valper (f.eks. "Blå", "Rød bånd")

  @HiveField(20)
  String? colorCode; // Fargekode for UI-skilling (f.eks. "#FF0000" for rød)

  Puppy({
    required this.id,
    required this.name,
    required this.litterId,
    required this.dateOfBirth,
    required this.gender,
    required this.color,
    this.registrationNumber,
    this.buyerName,
    this.buyerContact,
    this.status = 'Available',
    this.soldDate,
    this.deliveredDate,
    this.notes,
    this.vaccinated = false,
    this.dewormed = false,
    this.microchipped = false,
    this.birthWeight,
    this.birthTime,
    this.birthNotes,
    this.displayName,
    this.colorCode,
  });

  /// Hent visningsnavn for valpen (displayName hvis satt, ellers standard navn)
  String get effectiveDisplayName => displayName?.isNotEmpty == true ? displayName! : name;

  int getAgeInWeeks() {
    return DateTime.now().difference(dateOfBirth).inDays ~/ 7;
  }

  int getAgeInDays() {
    return DateTime.now().difference(dateOfBirth).inDays;
  }

  /// Serialize Puppy to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'litterId': litterId,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'color': color,
      'registrationNumber': registrationNumber,
      'buyerName': buyerName,
      'buyerContact': buyerContact,
      'status': status,
      'soldDate': soldDate?.toIso8601String(),
      'deliveredDate': deliveredDate?.toIso8601String(),
      'notes': notes,
      'vaccinated': vaccinated,
      'dewormed': dewormed,
      'microchipped': microchipped,
      'birthWeight': birthWeight,
      'birthTime': birthTime?.toIso8601String(),
      'birthNotes': birthNotes,
      'displayName': displayName,
      'colorCode': colorCode,
    };
  }

  /// Deserialize Puppy from Firebase JSON
  factory Puppy.fromJson(Map<String, dynamic> json) {
    return Puppy(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      litterId: json['litterId'] ?? '',
      dateOfBirth: json['dateOfBirth'] != null 
          ? DateTime.parse(json['dateOfBirth']) 
          : DateTime.now(),
      gender: json['gender'] ?? 'Male',
      color: json['color'] ?? '',
      registrationNumber: json['registrationNumber'],
      buyerName: json['buyerName'],
      buyerContact: json['buyerContact'],
      status: json['status'] ?? 'Available',
      soldDate: json['soldDate'] != null 
          ? DateTime.parse(json['soldDate']) 
          : null,
      deliveredDate: json['deliveredDate'] != null 
          ? DateTime.parse(json['deliveredDate']) 
          : null,
      notes: json['notes'],
      vaccinated: json['vaccinated'] ?? false,
      dewormed: json['dewormed'] ?? false,
      microchipped: json['microchipped'] ?? false,
      birthWeight: json['birthWeight'],
      birthTime: json['birthTime'] != null 
          ? DateTime.parse(json['birthTime']) 
          : null,
      birthNotes: json['birthNotes'],
      displayName: json['displayName'],
      colorCode: json['colorCode'],
    );
  }
}
