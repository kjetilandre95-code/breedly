import 'package:hive/hive.dart';

part 'kennel.g.dart';

@HiveType(typeId: 20)
class Kennel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String ownerId;

  @HiveField(3)
  String ownerEmail;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  String? description;

  @HiveField(6)
  List<String> breeds;

  @HiveField(7)
  String? contactEmail;

  @HiveField(8)
  String? contactPhone;

  @HiveField(9)
  String? address;

  @HiveField(10)
  String? website;

  Kennel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.ownerEmail,
    required this.createdAt,
    this.description,
    this.breeds = const [],
    this.contactEmail,
    this.contactPhone,
    this.address,
    this.website,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'ownerEmail': ownerEmail,
      'createdAt': createdAt.toIso8601String(),
      'description': description,
      'breeds': breeds,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'address': address,
      'website': website,
    };
  }

  factory Kennel.fromJson(Map<String, dynamic> json) {
    return Kennel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      ownerId: json['ownerId'] ?? '',
      ownerEmail: json['ownerEmail'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      description: json['description'],
      breeds: (json['breeds'] as List<dynamic>?)?.cast<String>() ?? [],
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
      address: json['address'],
      website: json['website'],
    );
  }
}
