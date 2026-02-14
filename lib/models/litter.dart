import 'package:hive/hive.dart';
import 'package:breedly/models/puppy.dart';

part 'litter.g.dart';

@HiveType(typeId: 0)
class Litter extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String damId; // Mother's ID

  @HiveField(2)
  late String sireId; // Father's ID

  @HiveField(3)
  late String damName;

  @HiveField(4)
  late String sireName;

  @HiveField(5)
  late DateTime dateOfBirth;

  @HiveField(6)
  late int numberOfPuppies;

  @HiveField(7)
  late String breed;

  @HiveField(8)
  String? expectedNumberOfMales;

  @HiveField(9)
  String? expectedNumberOfFemales;

  @HiveField(10)
  late int actualMalesCount;

  @HiveField(11)
  late int actualFemalesCount;

  @HiveField(12)
  String? notes;

  @HiveField(13)
  late bool isWeaned;

  @HiveField(14)
  DateTime? weanedDate;

  @HiveField(15)
  late bool isReadyForSale;

  @HiveField(16)
  DateTime? readyForSaleDate;

  @HiveField(17)
  String? registrationNumber;

  @HiveField(18)
  DateTime? damMatingDate;

  @HiveField(19)
  DateTime? estimatedDueDate;

  @HiveField(20)
  String? damHealthTests;

  @HiveField(21)
  String? sireHealthTests;

  Litter({
    required this.id,
    required this.damId,
    required this.sireId,
    required this.damName,
    required this.sireName,
    required this.dateOfBirth,
    required this.numberOfPuppies,
    required this.breed,
    this.expectedNumberOfMales,
    this.expectedNumberOfFemales,
    this.actualMalesCount = 0,
    this.actualFemalesCount = 0,
    this.notes,
    this.isWeaned = false,
    this.weanedDate,
    this.isReadyForSale = false,
    this.readyForSaleDate,
    this.registrationNumber,
    this.damMatingDate,
    this.estimatedDueDate,
    this.damHealthTests,
    this.sireHealthTests,
  });

  int getAgeInWeeks() {
    return DateTime.now().difference(dateOfBirth).inDays ~/ 7;
  }

  int getAgeInDays() {
    return DateTime.now().difference(dateOfBirth).inDays;
  }

  int getTotalPuppiesCount() {
    return actualMalesCount + actualFemalesCount;
  }

  String getStatus() {
    if (dateOfBirth.isAfter(DateTime.now())) return 'Planlagt';
    if (isReadyForSale) return 'Klar for salg';
    if (isWeaned) return 'Avvendt';
    if (getAgeInWeeks() >= 4) return 'Avvenning';
    if (getAgeInWeeks() >= 2) return 'Vokser';
    return 'Nyfødt';
  }

  /// Calculate actual male count from registered puppies in this litter
  int getActualMalesCountFromPuppies() {
    try {
      final puppyBox = Hive.box<Puppy>('puppies');
      return puppyBox.values
          .where((puppy) => puppy.litterId == id && puppy.gender == 'Male')
          .length;
    } catch (e) {
      // If there's any error accessing puppies, return the stored count
      return actualMalesCount;
    }
  }

  /// Calculate actual female count from registered puppies in this litter
  int getActualFemalesCountFromPuppies() {
    try {
      final puppyBox = Hive.box<Puppy>('puppies');
      return puppyBox.values
          .where((puppy) => puppy.litterId == id && puppy.gender == 'Female')
          .length;
    } catch (e) {
      // If there's any error accessing puppies, return the stored count
      return actualFemalesCount;
    }
  }

  /// Get total puppies count from registered puppies
  int getTotalPuppiesCountFromPuppies() {
    return getActualMalesCountFromPuppies() + getActualFemalesCountFromPuppies();
  }

  /// Serialize Litter to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'damId': damId,
      'sireId': sireId,
      'damName': damName,
      'sireName': sireName,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'numberOfPuppies': numberOfPuppies,
      'breed': breed,
      'expectedNumberOfMales': expectedNumberOfMales,
      'expectedNumberOfFemales': expectedNumberOfFemales,
      'actualMalesCount': actualMalesCount,
      'actualFemalesCount': actualFemalesCount,
      'notes': notes,
      'isWeaned': isWeaned,
      'weanedDate': weanedDate?.toIso8601String(),
      'isReadyForSale': isReadyForSale,
      'readyForSaleDate': readyForSaleDate?.toIso8601String(),
      'registrationNumber': registrationNumber,
      'damMatingDate': damMatingDate?.toIso8601String(),
      'estimatedDueDate': estimatedDueDate?.toIso8601String(),
      'damHealthTests': damHealthTests,
      'sireHealthTests': sireHealthTests,
    };
  }

  /// Deserialize Litter from Firebase JSON
  factory Litter.fromJson(Map<String, dynamic> json) {
    return Litter(
      id: json['id'] ?? '',
      damId: json['damId'] ?? '',
      sireId: json['sireId'] ?? '',
      damName: json['damName'] ?? '',
      sireName: json['sireName'] ?? '',
      dateOfBirth: json['dateOfBirth'] != null 
          ? DateTime.parse(json['dateOfBirth']) 
          : DateTime.now(),
      numberOfPuppies: json['numberOfPuppies'] ?? 0,
      breed: json['breed'] ?? '',
      expectedNumberOfMales: json['expectedNumberOfMales'],
      expectedNumberOfFemales: json['expectedNumberOfFemales'],
      actualMalesCount: json['actualMalesCount'] ?? 0,
      actualFemalesCount: json['actualFemalesCount'] ?? 0,
      notes: json['notes'],
      isWeaned: json['isWeaned'] ?? false,
      weanedDate: json['weanedDate'] != null 
          ? DateTime.parse(json['weanedDate']) 
          : null,
      isReadyForSale: json['isReadyForSale'] ?? false,
      readyForSaleDate: json['readyForSaleDate'] != null 
          ? DateTime.parse(json['readyForSaleDate']) 
          : null,
      registrationNumber: json['registrationNumber'],
      damMatingDate: json['damMatingDate'] != null 
          ? DateTime.parse(json['damMatingDate']) 
          : null,
      estimatedDueDate: json['estimatedDueDate'] != null 
          ? DateTime.parse(json['estimatedDueDate']) 
          : null,
      damHealthTests: json['damHealthTests'],
      sireHealthTests: json['sireHealthTests'],
    );
  }
}
