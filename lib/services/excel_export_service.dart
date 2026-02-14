import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:breedly/models/dog.dart';
import 'package:breedly/models/litter.dart';
import 'package:breedly/models/puppy.dart';
import 'package:breedly/models/expense.dart';
import 'package:breedly/models/income.dart';

/// Service for exporting data to CSV (Excel-compatible)
class ExcelExportService {
  static final ExcelExportService _instance = ExcelExportService._internal();
  factory ExcelExportService() => _instance;
  ExcelExportService._internal();

  final _dateFormat = DateFormat('dd.MM.yyyy');
  final _numberFormat = NumberFormat('#,##0', 'nb_NO');

  /// Export all dogs to CSV
  Future<File> exportDogs() async {
    final box = Hive.box<Dog>('dogs');
    final dogs = box.values.toList();

    final headers = [
      'Navn',
      'Rase',
      'Kjønn',
      'Fødselsdato',
      'Farge',
      'Reg.nr',
      'Mor',
      'Far',
      'Notater',
    ];

    final rows = dogs.map((dog) {
      final mother = dog.damId != null 
          ? box.values.where((d) => d.id == dog.damId).firstOrNull
          : null;
      final father = dog.sireId != null 
          ? box.values.where((d) => d.id == dog.sireId).firstOrNull
          : null;

      return [
        dog.name,
        dog.breed,
        dog.gender == 'Female' ? 'Tispe' : 'Hannhund',
        _dateFormat.format(dog.dateOfBirth),
        dog.color,
        dog.registrationNumber ?? '',
        mother?.name ?? '',
        father?.name ?? '',
        dog.notes ?? '',
      ];
    }).toList();

    return _createCsvFile('hunder', headers, rows);
  }

  /// Export all litters to CSV
  Future<File> exportLitters() async {
    final litterBox = Hive.box<Litter>('litters');
    final dogBox = Hive.box<Dog>('dogs');
    final puppyBox = Hive.box<Puppy>('puppies');

    final litters = litterBox.values.toList();

    final headers = [
      'Mor',
      'Far',
      'Parringsdato',
      'Fødselsdato',
      'Antall valper',
      'Hannvalper',
      'Tispevalper',
      'Solgt',
      'Reservert',
      'Tilgjengelig',
      'Notater',
    ];

    final rows = litters.map((litter) {
      final mother = dogBox.values.where((d) => d.id == litter.damId).firstOrNull;
      final father = dogBox.values.where((d) => d.id == litter.sireId).firstOrNull;
      final puppies = puppyBox.values.where((p) => p.litterId == litter.id).toList();

      final males = puppies.where((p) => p.gender == 'Male').length;
      final females = puppies.where((p) => p.gender == 'Female').length;
      final sold = puppies.where((p) => p.status == 'Sold').length;
      final reserved = puppies.where((p) => p.status == 'Reserved').length;
      final available = puppies.where((p) => p.status == 'Available' || p.status == null).length;

      return [
        mother?.name ?? litter.damName,
        father?.name ?? litter.sireName,
        litter.damMatingDate != null ? _dateFormat.format(litter.damMatingDate!) : '',
        _dateFormat.format(litter.dateOfBirth),
        puppies.length.toString(),
        males.toString(),
        females.toString(),
        sold.toString(),
        reserved.toString(),
        available.toString(),
        litter.notes ?? '',
      ];
    }).toList();

    return _createCsvFile('kull', headers, rows);
  }

  /// Export all puppies to CSV
  Future<File> exportPuppies() async {
    final puppyBox = Hive.box<Puppy>('puppies');
    final litterBox = Hive.box<Litter>('litters');
    final dogBox = Hive.box<Dog>('dogs');

    final puppies = puppyBox.values.toList();

    final headers = [
      'Navn',
      'Kjønn',
      'Farge',
      'Status',
      'Mor',
      'Far',
      'Fødselsdato',
      'Reg.nr',
      'Fødselsvekt (g)',
      'Notater',
    ];

    final rows = puppies.map((puppy) {
      final litter = litterBox.values.where((l) => l.id == puppy.litterId).firstOrNull;
      final mother = litter != null
          ? dogBox.values.where((d) => d.id == litter.damId).firstOrNull
          : null;
      final father = litter != null
          ? dogBox.values.where((d) => d.id == litter.sireId).firstOrNull
          : null;

      String status;
      switch (puppy.status) {
        case 'Sold':
          status = 'Solgt';
          break;
        case 'Reserved':
          status = 'Reservert';
          break;
        case 'Delivered':
          status = 'Levert';
          break;
        default:
          status = 'Tilgjengelig';
      }

      return [
        puppy.name,
        puppy.gender == 'Female' ? 'Tispe' : 'Hannhund',
        puppy.color,
        status,
        mother?.name ?? litter?.damName ?? '',
        father?.name ?? litter?.sireName ?? '',
        _dateFormat.format(puppy.dateOfBirth),
        puppy.registrationNumber ?? '',
        puppy.birthWeight?.toString() ?? '',
        puppy.notes ?? '',
      ];
    }).toList();

    return _createCsvFile('valper', headers, rows);
  }

  /// Export expenses to CSV
  Future<File> exportExpenses() async {
    final box = Hive.box<Expense>('expenses');
    final expenses = box.values.toList();

    // Sort by date
    expenses.sort((a, b) => b.date.compareTo(a.date));

    final headers = [
      'Dato',
      'Kategori',
      'Beskrivelse',
      'Beløp',
    ];

    final rows = expenses.map((expense) {
      return [
        _dateFormat.format(expense.date),
        expense.category,
        expense.description ?? '',
        _numberFormat.format(expense.amount),
      ];
    }).toList();

    return _createCsvFile('utgifter', headers, rows);
  }

  /// Export income to CSV
  Future<File> exportIncome() async {
    final box = Hive.box<Income>('incomes');
    final incomes = box.values.toList();

    // Sort by date
    incomes.sort((a, b) => b.date.compareTo(a.date));

    final headers = [
      'Dato',
      'Kjøper',
      'Beskrivelse',
      'Beløp',
    ];

    final rows = incomes.map((income) {
      return [
        _dateFormat.format(income.date),
        income.buyerName ?? '',
        income.description ?? '',
        _numberFormat.format(income.amount),
      ];
    }).toList();

    return _createCsvFile('inntekter', headers, rows);
  }

  /// Export financial summary to CSV
  Future<File> exportFinancialSummary() async {
    final expenseBox = Hive.box<Expense>('expenses');
    final incomeBox = Hive.box<Income>('incomes');
    
    final expenses = expenseBox.values.toList();
    final incomes = incomeBox.values.toList();

    // Group by year
    final years = <int>{};
    for (final e in expenses) {
      years.add(e.date.year);
    }
    for (final i in incomes) {
      years.add(i.date.year);
    }

    final headers = [
      'År',
      'Total inntekt',
      'Total utgift',
      'Netto resultat',
    ];

    final rows = years.map((year) {
      final yearIncome = incomes
          .where((i) => i.date.year == year)
          .fold<double>(0, (sum, i) => sum + i.amount);
      final yearExpense = expenses
          .where((e) => e.date.year == year)
          .fold<double>(0, (sum, e) => sum + e.amount);
      final net = yearIncome - yearExpense;

      return [
        year.toString(),
        _numberFormat.format(yearIncome),
        _numberFormat.format(yearExpense),
        _numberFormat.format(net),
      ];
    }).toList();

    // Sort by year descending
    rows.sort((a, b) => int.parse(b[0]).compareTo(int.parse(a[0])));

    return _createCsvFile('okonomi_sammendrag', headers, rows);
  }

  /// Export litter statistics to CSV
  Future<File> exportLitterStatistics() async {
    final litterBox = Hive.box<Litter>('litters');
    final puppyBox = Hive.box<Puppy>('puppies');

    final litters = litterBox.values.toList();

    // Group by breed
    final byBreed = <String, List<Litter>>{};
    for (final litter in litters) {
      final breed = litter.breed.isNotEmpty ? litter.breed : 'Ukjent';
      byBreed.putIfAbsent(breed, () => []).add(litter);
    }

    final headers = [
      'Rase',
      'Antall kull',
      'Totalt valper',
      'Snitt kullstørrelse',
      'Hannvalper',
      'Tispevalper',
    ];

    final rows = byBreed.entries.map((entry) {
      final breed = entry.key;
      final breedLitters = entry.value;

      int totalPuppies = 0;
      int totalMales = 0;
      int totalFemales = 0;

      for (final litter in breedLitters) {
        final puppies = puppyBox.values.where((p) => p.litterId == litter.id).toList();
        totalPuppies += puppies.length;
        totalMales += puppies.where((p) => p.gender == 'Male').length;
        totalFemales += puppies.where((p) => p.gender == 'Female').length;
      }

      final avgSize = breedLitters.isNotEmpty
          ? (totalPuppies / breedLitters.length).toStringAsFixed(1)
          : '0';

      return [
        breed,
        breedLitters.length.toString(),
        totalPuppies.toString(),
        avgSize,
        totalMales.toString(),
        totalFemales.toString(),
      ];
    }).toList();

    return _createCsvFile('kullstatistikk', headers, rows);
  }

  /// Create CSV file from headers and rows
  Future<File> _createCsvFile(
    String name,
    List<String> headers,
    List<List<String>> rows,
  ) async {
    final buffer = StringBuffer();

    // Add BOM for Excel to recognize UTF-8
    buffer.write('\uFEFF');

    // Add headers
    buffer.writeln(headers.map(_escapeCsv).join(';'));

    // Add rows
    for (final row in rows) {
      buffer.writeln(row.map(_escapeCsv).join(';'));
    }

    // Save file
    final output = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final file = File('${output.path}/${name}_$timestamp.csv');
    await file.writeAsString(buffer.toString());

    return file;
  }

  /// Escape CSV value
  String _escapeCsv(String value) {
    if (value.contains(';') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Share exported file
  Future<void> shareFile(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Breedly eksport',
    );
  }

  /// Export all data and share
  Future<void> exportAllData() async {
    // Export all files
    final files = await Future.wait([
      exportDogs(),
      exportLitters(),
      exportPuppies(),
      exportExpenses(),
      exportIncome(),
      exportFinancialSummary(),
      exportLitterStatistics(),
    ]);

    // Share all files
    await Share.shareXFiles(
      files.map((f) => XFile(f.path)).toList(),
      subject: 'Breedly - Komplett dataeksport',
    );
  }
}
