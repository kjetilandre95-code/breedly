import 'package:hive/hive.dart';

part 'buyer.g.dart';

/// Waitlist status enum values
class WaitlistStatus {
  static const String pending = 'pending';
  static const String contacted = 'contacted';
  static const String reserved = 'reserved';
  static const String purchased = 'purchased';
  static const String declined = 'declined';
  static const String cancelled = 'cancelled';
  
  static List<String> get all => [pending, contacted, reserved, purchased, declined, cancelled];
}

@HiveType(typeId: 4)
class Buyer extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  String? email;

  @HiveField(3)
  String? phone;

  @HiveField(4)
  String? address;

  @HiveField(5)
  String? preferences; // kjønn/lynne preferanser

  @HiveField(6)
  String? notes; // notater fra samtaler

  @HiveField(7)
  String? puppyReserved; // puppyId hvis en valp er reservert

  @HiveField(8)
  String? litterId; // kullId som kjøperen er interessert i

  @HiveField(9)
  DateTime? purchaseDate;

  @HiveField(10)
  DateTime? dateAdded;
  
  // Waitlist fields
  @HiveField(11)
  int? waitlistPosition; // Position in the waitlist (1 = first)
  
  @HiveField(12)
  DateTime? waitlistDate; // Date added to waitlist
  
  @HiveField(13)
  String? waitlistStatus; // pending, contacted, reserved, purchased, declined, cancelled
  
  @HiveField(14)
  String? preferredGender; // Male, Female, or null for no preference
  
  @HiveField(15)
  String? preferredColor; // Preferred color or null for no preference
  
  @HiveField(16)
  double? depositPaid; // Reservation deposit amount paid

  Buyer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.preferences,
    this.notes,
    this.puppyReserved,
    this.litterId,
    this.purchaseDate,
    this.dateAdded,
    this.waitlistPosition,
    this.waitlistDate,
    this.waitlistStatus,
    this.preferredGender,
    this.preferredColor,
    this.depositPaid,
  });
  
  /// Check if buyer is on waitlist
  bool get isOnWaitlist => waitlistPosition != null && waitlistPosition! > 0;
  
  /// Check if buyer has active status
  bool get hasActiveWaitlistStatus => 
    waitlistStatus == WaitlistStatus.pending || 
    waitlistStatus == WaitlistStatus.contacted ||
    waitlistStatus == WaitlistStatus.reserved;

  /// Serialize to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'preferences': preferences,
      'notes': notes,
      'puppyReserved': puppyReserved,
      'litterId': litterId,
      'purchaseDate': purchaseDate?.toIso8601String(),
      'dateAdded': dateAdded?.toIso8601String(),
      'waitlistPosition': waitlistPosition,
      'waitlistDate': waitlistDate?.toIso8601String(),
      'waitlistStatus': waitlistStatus,
      'preferredGender': preferredGender,
      'preferredColor': preferredColor,
      'depositPaid': depositPaid,
    };
  }

  /// Deserialize from Firebase JSON
  factory Buyer.fromJson(Map<String, dynamic> json) {
    return Buyer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      preferences: json['preferences'],
      notes: json['notes'],
      puppyReserved: json['puppyReserved'],
      litterId: json['litterId'],
      purchaseDate: json['purchaseDate'] != null 
          ? DateTime.parse(json['purchaseDate']) 
          : null,
      dateAdded: json['dateAdded'] != null 
          ? DateTime.parse(json['dateAdded']) 
          : null,
      waitlistPosition: json['waitlistPosition'],
      waitlistDate: json['waitlistDate'] != null
          ? DateTime.parse(json['waitlistDate'])
          : null,
      waitlistStatus: json['waitlistStatus'],
      preferredGender: json['preferredGender'],
      preferredColor: json['preferredColor'],
      depositPaid: json['depositPaid']?.toDouble(),
    );
  }
}
