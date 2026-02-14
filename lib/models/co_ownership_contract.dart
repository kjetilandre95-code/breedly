import 'package:hive/hive.dart';

part 'co_ownership_contract.g.dart';

@HiveType(typeId: 33)
class CoOwnershipContract extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String dogId; // Reference to Dog

  @HiveField(2)
  late String owner1Name;

  @HiveField(3)
  late String owner1Address;

  @HiveField(4)
  late String owner2Name;

  @HiveField(5)
  late String owner2Address;

  @HiveField(6)
  late int owner1Percentage; // Ownership percentage for owner 1

  @HiveField(7)
  late String primaryCaretaker; // 'Eier 1', 'Eier 2', or 'Delt'

  @HiveField(8)
  late String breedingRights;

  @HiveField(9)
  late String showRights;

  @HiveField(10)
  late String expenseSharing;

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

  CoOwnershipContract({
    required this.id,
    required this.dogId,
    required this.owner1Name,
    required this.owner1Address,
    required this.owner2Name,
    required this.owner2Address,
    required this.owner1Percentage,
    required this.primaryCaretaker,
    required this.breedingRights,
    required this.showRights,
    required this.expenseSharing,
    this.additionalTerms,
    required this.contractDate,
    this.status = 'Draft',
    this.notes,
    this.dateAdded,
  });

  int get owner2Percentage => 100 - owner1Percentage;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dogId': dogId,
      'owner1Name': owner1Name,
      'owner1Address': owner1Address,
      'owner2Name': owner2Name,
      'owner2Address': owner2Address,
      'owner1Percentage': owner1Percentage,
      'primaryCaretaker': primaryCaretaker,
      'breedingRights': breedingRights,
      'showRights': showRights,
      'expenseSharing': expenseSharing,
      'additionalTerms': additionalTerms,
      'contractDate': contractDate.toIso8601String(),
      'status': status,
      'notes': notes,
      'dateAdded': dateAdded?.toIso8601String(),
    };
  }

  factory CoOwnershipContract.fromJson(Map<String, dynamic> json) {
    return CoOwnershipContract(
      id: json['id'] ?? '',
      dogId: json['dogId'] ?? '',
      owner1Name: json['owner1Name'] ?? '',
      owner1Address: json['owner1Address'] ?? '',
      owner2Name: json['owner2Name'] ?? '',
      owner2Address: json['owner2Address'] ?? '',
      owner1Percentage: json['owner1Percentage'] ?? 50,
      primaryCaretaker: json['primaryCaretaker'] ?? 'Eier 1',
      breedingRights: json['breedingRights'] ?? '',
      showRights: json['showRights'] ?? '',
      expenseSharing: json['expenseSharing'] ?? '',
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
