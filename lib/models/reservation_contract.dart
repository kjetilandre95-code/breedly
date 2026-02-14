import 'package:hive/hive.dart';

part 'reservation_contract.g.dart';

@HiveType(typeId: 35)
class ReservationContract extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String puppyId; // Reference to Puppy

  @HiveField(2)
  late String buyerId; // Reference to Buyer

  @HiveField(3)
  late double reservationFee;

  @HiveField(4)
  late double totalPrice;

  @HiveField(5)
  String? notes;

  @HiveField(6)
  late DateTime contractDate;

  @HiveField(7)
  String? status; // 'Draft', 'Active', 'Converted', 'Cancelled'

  @HiveField(8)
  DateTime? dateAdded;

  @HiveField(9)
  String? convertedToPurchaseContractId; // If reservation converted to purchase

  ReservationContract({
    required this.id,
    required this.puppyId,
    required this.buyerId,
    required this.reservationFee,
    required this.totalPrice,
    this.notes,
    required this.contractDate,
    this.status = 'Draft',
    this.dateAdded,
    this.convertedToPurchaseContractId,
  });

  double get remainingAmount => totalPrice - reservationFee;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'puppyId': puppyId,
      'buyerId': buyerId,
      'reservationFee': reservationFee,
      'totalPrice': totalPrice,
      'notes': notes,
      'contractDate': contractDate.toIso8601String(),
      'status': status,
      'dateAdded': dateAdded?.toIso8601String(),
      'convertedToPurchaseContractId': convertedToPurchaseContractId,
    };
  }

  factory ReservationContract.fromJson(Map<String, dynamic> json) {
    return ReservationContract(
      id: json['id'] ?? '',
      puppyId: json['puppyId'] ?? '',
      buyerId: json['buyerId'] ?? '',
      reservationFee: (json['reservationFee'] ?? 0.0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
      notes: json['notes'],
      contractDate: json['contractDate'] != null 
          ? DateTime.parse(json['contractDate']) 
          : DateTime.now(),
      status: json['status'] ?? 'Draft',
      dateAdded: json['dateAdded'] != null 
          ? DateTime.parse(json['dateAdded']) 
          : null,
      convertedToPurchaseContractId: json['convertedToPurchaseContractId'],
    );
  }
}
