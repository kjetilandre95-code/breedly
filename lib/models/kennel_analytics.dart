import 'package:cloud_firestore/cloud_firestore.dart';

class KennelAnalytics {
  final String id;
  final double totalIncome;
  final double totalExpenses;
  final double netResult;
  final int incomeCount;
  final int expenseCount;
  final DateTime? updatedAt;
  final Map<String, dynamic> rawData;

  const KennelAnalytics({
    required this.id,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netResult,
    required this.incomeCount,
    required this.expenseCount,
    required this.rawData,
    this.updatedAt,
  });

  factory KennelAnalytics.fromJson(Map<String, dynamic> json) {
    final totalIncome = _asDouble(
      json['totalIncome'] ?? json['incomeTotal'] ?? json['income'],
    );
    final totalExpenses = _asDouble(
      json['totalExpenses'] ?? json['totalExpense'] ?? json['expenses'],
    );
    return KennelAnalytics(
      id: json['id'] as String? ?? '',
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netResult: _asDouble(json['netResult'] ?? json['profit'] ?? totalIncome - totalExpenses),
      incomeCount: _asInt(json['incomeCount']),
      expenseCount: _asInt(json['expenseCount']),
      updatedAt: _asDateTime(json['updatedAt']),
      rawData: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...rawData,
      'id': id,
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'netResult': netResult,
      'incomeCount': incomeCount,
      'expenseCount': expenseCount,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  static double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static int _asInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _asDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
