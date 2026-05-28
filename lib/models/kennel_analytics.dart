class KennelAnalytics {
  final String id;
  final double totalIncome;
  final double totalExpenses;
  final double netIncome;
  final DateTime? updatedAt;

  const KennelAnalytics({
    required this.id,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netIncome,
    this.updatedAt,
  });

  factory KennelAnalytics.fromJson(Map<String, dynamic> json) {
    final totalIncome = _asDouble(json['totalIncome'] ?? json['income']);
    final totalExpenses = _asDouble(json['totalExpenses'] ?? json['expenses']);
    return KennelAnalytics(
      id: json['id']?.toString() ?? '',
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netIncome: _asDouble(json['netIncome'] ?? (totalIncome - totalExpenses)),
      updatedAt: _asDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'netIncome': netIncome,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _asDateTime(Object? value) {
    if (value is DateTime) return value;
    final dynamicValue = value as dynamic;
    try {
      final converted = dynamicValue?.toDate();
      if (converted is DateTime) return converted;
    } catch (_) {}
    return DateTime.tryParse(value?.toString() ?? '');
  }
}
