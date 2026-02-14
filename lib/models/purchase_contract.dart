import 'package:hive/hive.dart';

part 'purchase_contract.g.dart';

@HiveType(typeId: 12)
class PurchaseContract extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String puppyId; // Reference to Puppy

  @HiveField(2)
  late String buyerId; // Reference to Buyer

  @HiveField(3)
  late DateTime contractDate; // When contract was created

  @HiveField(4)
  late double price; // Sale price

  @HiveField(5)
  DateTime? purchaseDate; // When puppy was sold

  @HiveField(6)
  String? contractNumber; // Contract reference number

  @HiveField(7)
  String? status; // 'Draft', 'Active', 'Completed', 'Cancelled'

  @HiveField(8)
  String? terms; // Contract terms and conditions

  @HiveField(9)
  bool spayNeuterRequired = false; // Whether spay/neuter is required

  @HiveField(10)
  bool returnClauseIncluded = false; // Whether return clause is included

  @HiveField(11)
  String? paymentTerms; // Payment details (e.g., 'Full payment due at pickup')

  @HiveField(12)
  String? notes; // Additional notes

  @HiveField(13)
  DateTime? dateAdded; // When record was created in system

  // New fields based on standard purchase agreement
  @HiveField(14)
  double? deposit; // Reservasjonsgebyr/depositum

  @HiveField(15)
  bool pedigreeDelivered; // Registreringsbevis overlevert ved avhenting

  @HiveField(16)
  bool vetCertificateAttached; // Veterinærattest vedheftet

  @HiveField(17)
  String? microchipNumber; // ID-merkenr/Mikrochip

  @HiveField(18)
  String? deliveryLocation; // Sted for overlevering

  @HiveField(19)
  String? specialTerms; // Særlige vilkår

  @HiveField(20)
  bool insuranceTransferred; // Forsikring overført til kjøper

  PurchaseContract({
    required this.id,
    required this.puppyId,
    required this.buyerId,
    required this.contractDate,
    required this.price,
    this.purchaseDate,
    this.contractNumber,
    this.status = 'Draft',
    this.terms,
    this.spayNeuterRequired = false,
    this.returnClauseIncluded = false,
    this.paymentTerms,
    this.notes,
    this.dateAdded,
    this.deposit,
    this.pedigreeDelivered = false,
    this.vetCertificateAttached = false,
    this.microchipNumber,
    this.deliveryLocation,
    this.specialTerms,
    this.insuranceTransferred = false,
  });

  /// Serialize to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'puppyId': puppyId,
      'buyerId': buyerId,
      'contractDate': contractDate.toIso8601String(),
      'price': price,
      'purchaseDate': purchaseDate?.toIso8601String(),
      'contractNumber': contractNumber,
      'status': status,
      'terms': terms,
      'spayNeuterRequired': spayNeuterRequired,
      'returnClauseIncluded': returnClauseIncluded,
      'paymentTerms': paymentTerms,
      'notes': notes,
      'dateAdded': dateAdded?.toIso8601String(),
      'deposit': deposit,
      'pedigreeDelivered': pedigreeDelivered,
      'vetCertificateAttached': vetCertificateAttached,
      'microchipNumber': microchipNumber,
      'deliveryLocation': deliveryLocation,
      'specialTerms': specialTerms,
      'insuranceTransferred': insuranceTransferred,
    };
  }

  /// Deserialize from Firebase JSON
  factory PurchaseContract.fromJson(Map<String, dynamic> json) {
    return PurchaseContract(
      id: json['id'] ?? '',
      puppyId: json['puppyId'] ?? '',
      buyerId: json['buyerId'] ?? '',
      contractDate: json['contractDate'] != null 
          ? DateTime.parse(json['contractDate']) 
          : DateTime.now(),
      price: (json['price'] ?? 0.0).toDouble(),
      purchaseDate: json['purchaseDate'] != null 
          ? DateTime.parse(json['purchaseDate']) 
          : null,
      contractNumber: json['contractNumber'],
      status: json['status'] ?? 'Draft',
      terms: json['terms'],
      spayNeuterRequired: json['spayNeuterRequired'] ?? false,
      returnClauseIncluded: json['returnClauseIncluded'] ?? false,
      paymentTerms: json['paymentTerms'],
      notes: json['notes'],
      dateAdded: json['dateAdded'] != null 
          ? DateTime.parse(json['dateAdded']) 
          : null,
      deposit: json['deposit'] != null ? (json['deposit'] as num).toDouble() : null,
      pedigreeDelivered: json['pedigreeDelivered'] ?? false,
      vetCertificateAttached: json['vetCertificateAttached'] ?? false,
      microchipNumber: json['microchipNumber'],
      deliveryLocation: json['deliveryLocation'],
      specialTerms: json['specialTerms'],
      insuranceTransferred: json['insuranceTransferred'] ?? false,
    );
  }
}
