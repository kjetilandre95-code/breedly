import 'package:hive/hive.dart';

part 'breeding_contract.g.dart';

@HiveType(typeId: 32)
class BreedingContract extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String studId; // Reference to male Dog

  @HiveField(2)
  late String damId; // Reference to female Dog

  @HiveField(3)
  late String studOwnerName;

  @HiveField(4)
  late String studOwnerAddress;

  @HiveField(5)
  late String damOwnerName;

  @HiveField(6)
  late String damOwnerAddress;

  @HiveField(7)
  late double studFee;

  @HiveField(8)
  String? paymentTerms;

  @HiveField(9)
  String? additionalTerms;

  @HiveField(10)
  late DateTime contractDate;

  @HiveField(11)
  String? status; // 'Draft', 'Active', 'Completed', 'Cancelled'

  @HiveField(12)
  String? notes;

  @HiveField(13)
  DateTime? dateAdded;

  BreedingContract({
    required this.id,
    required this.studId,
    required this.damId,
    required this.studOwnerName,
    required this.studOwnerAddress,
    required this.damOwnerName,
    required this.damOwnerAddress,
    required this.studFee,
    this.paymentTerms,
    this.additionalTerms,
    required this.contractDate,
    this.status = 'Draft',
    this.notes,
    this.dateAdded,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studId': studId,
      'damId': damId,
      'studOwnerName': studOwnerName,
      'studOwnerAddress': studOwnerAddress,
      'damOwnerName': damOwnerName,
      'damOwnerAddress': damOwnerAddress,
      'studFee': studFee,
      'paymentTerms': paymentTerms,
      'additionalTerms': additionalTerms,
      'contractDate': contractDate.toIso8601String(),
      'status': status,
      'notes': notes,
      'dateAdded': dateAdded?.toIso8601String(),
    };
  }

  factory BreedingContract.fromJson(Map<String, dynamic> json) {
    return BreedingContract(
      id: json['id'] ?? '',
      studId: json['studId'] ?? '',
      damId: json['damId'] ?? '',
      studOwnerName: json['studOwnerName'] ?? '',
      studOwnerAddress: json['studOwnerAddress'] ?? '',
      damOwnerName: json['damOwnerName'] ?? '',
      damOwnerAddress: json['damOwnerAddress'] ?? '',
      studFee: (json['studFee'] ?? 0.0).toDouble(),
      paymentTerms: json['paymentTerms'],
      additionalTerms: json['additionalTerms'],
      contractDate: json['contractDate'] != null 
          ? DateTime.parse(json['contractDate']) 
          : DateTime.now(),
      status: json['status'] ?? 'Draft',
      notes: json['notes'],
      dateAdded: json['dateAdded'] != null 
          ? DateTime.parse(json['dateAdded']) 
          : null,
    );
  }
}
