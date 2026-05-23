class KennelAnalytics {
  final String id;
  final double incomeTotal;
  final double expenseTotal;
  final double profit;
  final int incomeCount;
  final int expenseCount;

  const KennelAnalytics({
    required this.id,
    required this.incomeTotal,
    required this.expenseTotal,
    required this.profit,
    required this.incomeCount,
    required this.expenseCount,
  });

  factory KennelAnalytics.fromJson(Map<String, dynamic> json) {
    final incomeTotal = _toDouble(json['incomeTotal'] ?? json['totalIncome']);
    final expenseTotal =
        _toDouble(json['expenseTotal'] ?? json['totalExpenses']);
    return KennelAnalytics(
      id: (json['id'] ?? '').toString(),
      incomeTotal: incomeTotal,
      expenseTotal: expenseTotal,
      profit: _toDouble(json['profit'] ?? (incomeTotal - expenseTotal)),
      incomeCount: _toInt(json['incomeCount']),
      expenseCount: _toInt(json['expenseCount']),
    );
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _toInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
