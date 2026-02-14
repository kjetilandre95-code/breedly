import 'package:hive/hive.dart';

part 'income.g.dart';

@HiveType(typeId: 6)
class Income extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late double amount;

  @HiveField(2)
  late DateTime date;

  @HiveField(3)
  String? puppyId; // Link til solgt valp

  @HiveField(4)
  String? buyerName;

  @HiveField(5)
  String? description;

  @HiveField(6)
  String? litterId; // Link til kull

  Income({
    required this.id,
    required this.amount,
    required this.date,
    this.puppyId,
    this.buyerName,
    this.description,
    this.litterId,
  });

  /// Serialize Income to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'puppyId': puppyId,
      'buyerName': buyerName,
      'description': description,
      'litterId': litterId,
    };
  }

  /// Deserialize Income from Firebase JSON
  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] != null 
          ? DateTime.parse(json['date']) 
          : DateTime.now(),
      puppyId: json['puppyId'],
      buyerName: json['buyerName'],
      description: json['description'],
      litterId: json['litterId'],
    );
  }
}
