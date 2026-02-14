import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:breedly/models/litter.dart';
import 'package:breedly/models/puppy.dart';
import 'package:breedly/models/expense.dart';
import 'package:breedly/models/income.dart';
import 'package:breedly/models/show_result.dart';
import 'package:breedly/models/kennel_profile.dart';

/// Service for generating annual reports in PDF format
class AnnualReportService {
  static final AnnualReportService _instance = AnnualReportService._internal();
  factory AnnualReportService() => _instance;
  AnnualReportService._internal();

  final _dateFormat = DateFormat('dd.MM.yyyy');
  final _currencyFormat = NumberFormat.currency(locale: 'nb_NO', symbol: 'kr');

  /// Generate annual report for a specific year
  Future<File> generateAnnualReport(int year) async {
    final pdf = pw.Document();

    // Gather all data for the year
    final reportData = _gatherYearData(year);
    final kennel = _getKennelProfile();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(kennel, year),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildSummarySection(reportData),
          pw.SizedBox(height: 20),
          _buildLitterSection(reportData),
          pw.SizedBox(height: 20),
          _buildPuppySection(reportData),
          pw.SizedBox(height: 20),
          _buildFinanceSection(reportData),
          pw.SizedBox(height: 20),
          if (reportData['showResults'].isNotEmpty)
            _buildShowResultsSection(reportData),
        ],
      ),
    );

    // Save to file
    final output = await getTemporaryDirectory();
    final fileName = 'aarsrapport_$year.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Generate and share the annual report
  Future<void> shareAnnualReport(int year) async {
    final file = await generateAnnualReport(year);
    await Share.shareXFiles([XFile(file.path)], subject: 'Årsrapport $year');
  }

  Map<String, dynamic> _gatherYearData(int year) {
    final litterBox = Hive.box<Litter>('litters');
    final puppyBox = Hive.box<Puppy>('puppies');
    final expenseBox = Hive.box<Expense>('expenses');
    final incomeBox = Hive.box<Income>('incomes');
    final showResultBox = Hive.box<ShowResult>('show_results');

    // Filter by year
    final litters = litterBox.values
        .where((l) => l.dateOfBirth.year == year)
        .toList();

    final puppies = puppyBox.values
        .where((p) => p.dateOfBirth.year == year)
        .toList();

    final expenses = expenseBox.values
        .where((e) => e.date.year == year)
        .toList();

    final incomes = incomeBox.values.where((i) => i.date.year == year).toList();

    final showResults = showResultBox.values
        .where((s) => s.date.year == year)
        .toList();

    // Calculate statistics
    final totalPuppies = puppies.length;
    final malePuppies = puppies.where((p) => p.gender == 'Male').length;
    final femalePuppies = puppies.where((p) => p.gender == 'Female').length;
    final soldPuppies = puppies
        .where((p) => p.status == 'Sold' || p.status == 'Delivered')
        .length;

    final totalIncome = incomes.fold<double>(0, (sum, i) => sum + i.amount);
    final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final netResult = totalIncome - totalExpenses;

    // Group expenses by category
    final expensesByCategory = <String, double>{};
    for (final expense in expenses) {
      final category = expense.category;
      expensesByCategory[category] =
          (expensesByCategory[category] ?? 0) + expense.amount;
    }

    // Show results summary
    final birCount = showResults.where((s) => s.placement == 'BIR').length;
    final bimCount = showResults.where((s) => s.placement == 'BIM').length;
    final certCount = showResults
        .where((s) => s.certificates?.isNotEmpty == true)
        .length;

    return {
      'year': year,
      'litters': litters,
      'puppies': puppies,
      'expenses': expenses,
      'incomes': incomes,
      'showResults': showResults,
      'totalPuppies': totalPuppies,
      'malePuppies': malePuppies,
      'femalePuppies': femalePuppies,
      'soldPuppies': soldPuppies,
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'netResult': netResult,
      'expensesByCategory': expensesByCategory,
      'birCount': birCount,
      'bimCount': bimCount,
      'certCount': certCount,
      'avgLitterSize': litters.isNotEmpty ? totalPuppies / litters.length : 0.0,
    };
  }

  KennelProfile? _getKennelProfile() {
    try {
      final box = Hive.box<KennelProfile>('kennel_profile');
      return box.values.firstOrNull;
    } catch (e) {
      return null;
    }
  }

  pw.Widget _buildHeader(KennelProfile? kennel, int year) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                kennel?.kennelName ?? 'Breedly',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Årsrapport $year',
                style: const pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Text(
            'Generert: ${_dateFormat.format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Side ${context.pageNumber} av ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
      ),
    );
  }

  pw.Widget _buildSummarySection(Map<String, dynamic> data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.green200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Årssammendrag ${data['year']}',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green900,
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryBox(
                'Kull født',
                '${(data['litters'] as List).length}',
                PdfColors.blue,
              ),
              _buildSummaryBox(
                'Valper født',
                '${data['totalPuppies']}',
                PdfColors.purple,
              ),
              _buildSummaryBox(
                'Valper solgt',
                '${data['soldPuppies']}',
                PdfColors.orange,
              ),
              _buildSummaryBox(
                'Netto resultat',
                _currencyFormat.format(data['netResult']),
                data['netResult'] >= 0 ? PdfColors.green : PdfColors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryBox(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildLitterSection(Map<String, dynamic> data) {
    final litters = data['litters'] as List<Litter>;

    if (litters.isEmpty) {
      return pw.Container(
        child: pw.Text(
          'Ingen kull registrert i ${data['year']}',
          style: const pw.TextStyle(color: PdfColors.grey600),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Kull', PdfColors.blue),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blue50),
              children: [
                _buildTableHeader('Mor'),
                _buildTableHeader('Far'),
                _buildTableHeader('Fødselsdato'),
                _buildTableHeader('Hanner'),
                _buildTableHeader('Tisper'),
              ],
            ),
            ...litters.map((litter) {
              final puppyBox = Hive.box<Puppy>('puppies');
              final litterPuppies = puppyBox.values
                  .where((p) => p.litterId == litter.id)
                  .toList();
              final males = litterPuppies
                  .where((p) => p.gender == 'Male')
                  .length;
              final females = litterPuppies
                  .where((p) => p.gender == 'Female')
                  .length;

              return pw.TableRow(
                children: [
                  _buildTableCell(litter.damName),
                  _buildTableCell(litter.sireName),
                  _buildTableCell(_dateFormat.format(litter.dateOfBirth)),
                  _buildTableCell('$males'),
                  _buildTableCell('$females'),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text(
              'Gjennomsnittlig kullstørrelse: ${(data['avgLitterSize'] as double).toStringAsFixed(1)} valper',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPuppySection(Map<String, dynamic> data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Valpestatistikk', PdfColors.purple),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildStatCard(
                'Totalt født',
                '${data['totalPuppies']}',
                PdfColors.purple,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: _buildStatCard(
                'Hannvalper',
                '${data['malePuppies']}',
                PdfColors.blue,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: _buildStatCard(
                'Tispevalper',
                '${data['femalePuppies']}',
                PdfColors.pink,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: _buildStatCard(
                'Solgt/levert',
                '${data['soldPuppies']}',
                PdfColors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildFinanceSection(Map<String, dynamic> data) {
    final expensesByCategory =
        data['expensesByCategory'] as Map<String, double>;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Økonomi', PdfColors.orange),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildStatCard(
                'Total inntekt',
                _currencyFormat.format(data['totalIncome']),
                PdfColors.green,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: _buildStatCard(
                'Totale utgifter',
                _currencyFormat.format(data['totalExpenses']),
                PdfColors.red,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: _buildStatCard(
                'Netto resultat',
                _currencyFormat.format(data['netResult']),
                data['netResult'] >= 0 ? PdfColors.green : PdfColors.red,
              ),
            ),
          ],
        ),
        if (expensesByCategory.isNotEmpty) ...[
          pw.SizedBox(height: 15),
          pw.Text(
            'Utgifter per kategori:',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.orange50),
                children: [
                  _buildTableHeader('Kategori'),
                  _buildTableHeader('Beløp'),
                ],
              ),
              ...expensesByCategory.entries.map(
                (entry) => pw.TableRow(
                  children: [
                    _buildTableCell(entry.key),
                    _buildTableCell(_currencyFormat.format(entry.value)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  pw.Widget _buildShowResultsSection(Map<String, dynamic> data) {
    final showResults = data['showResults'] as List<ShowResult>;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Utstillingsresultater', PdfColors.amber),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildStatCard(
                'BIR',
                '${data['birCount']}',
                PdfColors.amber,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: _buildStatCard(
                'BIM',
                '${data['bimCount']}',
                PdfColors.grey,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: _buildStatCard(
                'Sertifikater',
                '${data['certCount']}',
                PdfColors.amber800,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: _buildStatCard(
                'Utstillinger',
                '${showResults.length}',
                PdfColors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSectionTitle(String title, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  pw.Widget _buildStatCard(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildTableCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
}
