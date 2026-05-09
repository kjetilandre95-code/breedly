class ImportedShowResult {
  final DateTime date;
  final String showName;
  final String? judge;
  final String showClass;
  final String quality;
  final int? classPlacement;
  final String? placement;
  final List<String> certificates;
  final int? bestOfSexPlacement;
  final String? groupResult;
  final String? bisResult;
  final String? notes;
  final String? showType;
  final bool hasCK;
  final String? place;

  const ImportedShowResult({
    required this.date,
    required this.showName,
    required this.showClass,
    required this.quality,
    this.judge,
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
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) return [];

    return lines.map(_parseLine).toList();
  }

  ImportedShowResult _parseLine(String line) {
    final parts = line
        .split(RegExp(r'[;\t|]'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    final date = parts.isNotEmpty ? _parseDate(parts.first) : null;
    final startsWithDate = date != null;
    final showNameIndex = startsWithDate ? 1 : 0;

    return ImportedShowResult(
      date: date ?? DateTime.now(),
      showName: parts.length > showNameIndex
          ? parts[showNameIndex]
          : line,
      judge: parts.length > showNameIndex + 1 ? parts[showNameIndex + 1] : null,
      showClass: parts.length > showNameIndex + 2
          ? parts[showNameIndex + 2]
          : 'Åpen klasse',
      quality: parts.length > showNameIndex + 3
          ? parts[showNameIndex + 3]
          : 'Excellent',
      hasCK: line.toUpperCase().contains('CK'),
      certificates: _extractCertificates(line),
      notes: line,
    );
  }

  DateTime? _parseDate(String value) {
    final iso = DateTime.tryParse(value);
    if (iso != null) return iso;

    final match = RegExp(r'^(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})$')
        .firstMatch(value);
    if (match == null) return null;

    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    var year = int.tryParse(match.group(3)!);
    if (day == null || month == null || year == null) return null;
    if (year < 100) year += 2000;
    return DateTime(year, month, day);
  }

  List<String> _extractCertificates(String line) {
    final upper = line.toUpperCase();
    return [
      if (upper.contains('CERT')) 'CERT',
      if (upper.contains('CACIB')) 'CACIB',
      if (upper.contains('NORD')) 'NORD CERT',
    ];
  }
}
