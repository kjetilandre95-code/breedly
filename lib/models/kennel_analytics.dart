class KennelAnalytics {
  final String id;
  final Map<String, dynamic> data;

  const KennelAnalytics({
    required this.id,
    required this.data,
  });

  factory KennelAnalytics.fromJson(Map<String, dynamic> json) {
    return KennelAnalytics(
      id: json['id'] as String? ?? '',
      data: Map<String, dynamic>.from(json),
    );
  }
}
