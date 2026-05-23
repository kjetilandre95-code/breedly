class ImportedShowResult {
  final DateTime date;
  final String showName;
  final String? judge;
  final String showClass;
  final String quality;
  final String? classPlacement;
  final String? placement;
  final List<String> certificates;
  final String? bestOfSexPlacement;
  final String? groupResult;
  final String? bisResult;
  final String? notes;
  final String? showType;
  final bool hasCK;

  const ImportedShowResult({
    required this.date,
    required this.showName,
    this.judge,
    required this.showClass,
    required this.quality,
    this.classPlacement,
    this.placement,
    this.certificates = const [],
    this.bestOfSexPlacement,
    this.groupResult,
    this.bisResult,
    this.notes,
    this.showType,
    this.hasCK = false,
  });
}

class ShowImportService {
  Future<List<ImportedShowResult>> analyzeText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return [];

    return [
      ImportedShowResult(
        date: DateTime.now(),
        showName: trimmed.split('\n').first.trim(),
        showClass: 'Åpen',
        quality: 'Excellent',
        notes: trimmed,
      ),
    ];
  }
}
