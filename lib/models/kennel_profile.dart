import 'package:hive/hive.dart';

part 'kennel_profile.g.dart';

@HiveType(typeId: 15)
class KennelProfile extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  String? kennelName;

  @HiveField(2)
  List<String> breeds;

  @HiveField(3)
  String? contactEmail;

  @HiveField(4)
  String? contactPhone;

  @HiveField(5)
  String? address;

  @HiveField(6)
  String? website;

  @HiveField(7)
  String? description;

  KennelProfile({
    required this.id,
    this.kennelName,
    this.breeds = const [],
    this.contactEmail,
    this.contactPhone,
    this.address,
    this.website,
    this.description,
  });

  /// Serialize KennelProfile to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kennelName': kennelName,
      'breeds': breeds,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'address': address,
      'website': website,
      'description': description,
    };
  }

  /// Deserialize KennelProfile from Firebase JSON
  factory KennelProfile.fromJson(Map<String, dynamic> json) {
    return KennelProfile(
      id: json['id'] ?? '',
      kennelName: json['kennelName'],
      breeds: (json['breeds'] as List<dynamic>?)?.cast<String>() ?? [],
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
      address: json['address'],
      website: json['website'],
      description: json['description'],
    );
  }
}
