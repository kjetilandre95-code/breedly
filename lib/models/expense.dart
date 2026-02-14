import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 5)
class Expense extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String category; // 'Fôr', 'Veterinær', 'Registrering', 'Annet'

  @HiveField(2)
  late double amount;

  @HiveField(3)
  late DateTime date;

  @HiveField(4)
  String? description;

  @HiveField(5)
  String? litterId; // Link til kull hvis relevant

  Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    this.description,
    this.litterId,
  });

  /// Serialize Expense to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'litterId': litterId,
    };
  }

  /// Deserialize Expense from Firebase JSON
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] ?? '',
      category: json['category'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] != null 
          ? DateTime.parse(json['date']) 
          : DateTime.now(),
      description: json['description'],
      litterId: json['litterId'],
    );
  }
}
