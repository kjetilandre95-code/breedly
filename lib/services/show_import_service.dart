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
  final String? place;

  const ImportedShowResult({
    required this.date,
    required this.showName,
    this.judge,
    this.showClass = 'Åpen',
    this.quality = 'Excellent',
    this.classPlacement,
    this.placement,
    this.certificates = const [],
    this.bestOfSexPlacement,
    this.groupResult,
    this.bisResult,
    this.notes,
    this.showType,
    this.hasCK = false,
    this.place,
  });
}

class ShowImportService {
  Future<List<ImportedShowResult>> analyzeText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const [];

    final lines = trimmed
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final date = _extractDate(trimmed) ?? DateTime.now();
    return [
      ImportedShowResult(
        date: date,
        showName: lines.isNotEmpty ? lines.first : 'Imported show',
        notes: trimmed,
      ),
    ];
  }

  DateTime? _extractDate(String text) {
    final match = RegExp(r'(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})').firstMatch(text);
    if (match == null) return null;
    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    var year = int.tryParse(match.group(3)!);
    if (day == null || month == null || year == null) return null;
    if (year < 100) year += 2000;
    return DateTime.tryParse(
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}',
    );
  }
}
