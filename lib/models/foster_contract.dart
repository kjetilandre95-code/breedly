import 'package:hive/hive.dart';

part 'foster_contract.g.dart';

@HiveType(typeId: 34)
class FosterContract extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String dogId; // Reference to Dog

  @HiveField(2)
  late String ownerName;

  @HiveField(3)
  late String ownerAddress;

  @HiveField(4)
  late String fosterName;

  @HiveField(5)
  late String fosterAddress;

  @HiveField(6)
  late DateTime startDate;

  @HiveField(7)
  DateTime? endDate; // Null means indefinite

  @HiveField(8)
  late String breedingTerms;

  @HiveField(9)
  late String expenseTerms;

  @HiveField(10)
  late String returnConditions;

  @HiveField(11)
  String? additionalTerms;

  @HiveField(12)
  late DateTime contractDate;

  @HiveField(13)
  String? status; // 'Draft', 'Active', 'Completed', 'Cancelled'

  @HiveField(14)
  String? notes;

  @HiveField(15)
  DateTime? dateAdded;

  FosterContract({
    required this.id,
    required this.dogId,
    required this.ownerName,
    required this.ownerAddress,
    required this.fosterName,
    required this.fosterAddress,
    required this.startDate,
    this.endDate,
    required this.breedingTerms,
    required this.expenseTerms,
    required this.returnConditions,
    this.additionalTerms,
    required this.contractDate,
    this.status = 'Draft',
    this.notes,
    this.dateAdded,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dogId': dogId,
      'ownerName': ownerName,
      'ownerAddress': ownerAddress,
      'fosterName': fosterName,
      'fosterAddress': fosterAddress,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'breedingTerms': breedingTerms,
      'expenseTerms': expenseTerms,
      'returnConditions': returnConditions,
      'additionalTerms': additionalTerms,
      'contractDate': contractDate.toIso8601String(),
      'status': status,
      'notes': notes,
      'dateAdded': dateAdded?.toIso8601String(),
    };
  }

  factory FosterContract.fromJson(Map<String, dynamic> json) {
    return FosterContract(
      id: json['id'] ?? '',
      dogId: json['dogId'] ?? '',
      ownerName: json['ownerName'] ?? '',
      ownerAddress: json['ownerAddress'] ?? '',
      fosterName: json['fosterName'] ?? '',
      fosterAddress: json['fosterAddress'] ?? '',
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate']) 
          : DateTime.now(),
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate']) 
          : null,
      breedingTerms: json['breedingTerms'] ?? '',
      expenseTerms: json['expenseTerms'] ?? '',
      returnConditions: json['returnConditions'] ?? '',
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
