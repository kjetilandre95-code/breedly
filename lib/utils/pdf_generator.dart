import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:breedly/models/puppy.dart';
import 'package:breedly/models/litter.dart';
import 'package:breedly/models/dog.dart';
import 'package:breedly/models/puppy_weight_log.dart';
import 'package:breedly/models/purchase_contract.dart';
import 'package:breedly/models/buyer.dart';
import 'package:intl/intl.dart';
import 'translations.dart';
import 'package:hive_flutter/hive_flutter.dart';

class PDFGenerator {
  static Future<pw.Document> generatePuppyPackage(
    Puppy puppy,
    Litter litter,
  ) async {
    final pdf = pw.Document();
    final weightBox = Hive.box<PuppyWeightLog>('weight_logs');
    final weightLogs = weightBox.values
        .where((log) => log.puppyId == puppy.id)
        .toList()
      ..sort((a, b) => a.logDate.compareTo(b.logDate));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Valpes dokumentasjon',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Grunnleggende informasjon',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildRow('Navn:', puppy.name),
              _buildRow('Kjønn:', puppy.gender),
              _buildRow('Farge:', puppy.color),
              _buildRow('Fødselsdato:', DateFormat('yyyy-MM-dd').format(puppy.dateOfBirth)),
              _buildRow('Registreringsnummer:', puppy.registrationNumber ?? 'Ikke registrert'),
              _buildRow('Mikrobrikke:', puppy.microchipped ? 'Ja' : 'Nei'),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Kullinfo',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildRow('Mor (tispe):', litter.damName),
              _buildRow('Far (hannhund):', litter.sireName),
              _buildRow('Rase:', litter.breed),
              _buildRow('Kullstørrelse:', '${litter.getTotalPuppiesCount()} valper'),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Helseinformasjon',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildRow('Vaksinert:', puppy.vaccinated ? 'Ja' : 'Nei'),
              _buildRow('Avormert:', puppy.dewormed ? 'Ja' : 'Nei'),
              _buildRow('Vekt ved fødsel:', puppy.birthWeight != null ? '${puppy.birthWeight?.toStringAsFixed(0)} gram' : 'Ikke registrert'),
              if (puppy.birthNotes != null && puppy.birthNotes!.isNotEmpty)
                _buildRow('Merknader:', puppy.birthNotes!),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Status',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildRow('Status:', AppTranslations.translatePuppyStatus(puppy.status ?? 'Available')),
              if (puppy.buyerName != null && puppy.buyerName!.isNotEmpty)
                _buildRow('Kjøper:', puppy.buyerName!),
              if (puppy.notes != null && puppy.notes!.isNotEmpty)
                _buildRow('Notater:', puppy.notes!),
            ],
          ),
          if (weightLogs.isNotEmpty) ...[
            pw.SizedBox(height: 30),
            pw.Divider(),
            pw.SizedBox(height: 20),
            pw.Text(
              'Vektkurve',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            _buildWeightTable(weightLogs, puppy),
          ],
          pw.SizedBox(height: 40),
          pw.Divider(),
          pw.SizedBox(height: 20),
          pw.Text(
            'Dokument generert: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _buildWeightTable(List<PuppyWeightLog> logs, Puppy puppy) {
    // Bygg liste med fødselssvekt først hvis den finnes
    List<pw.TableRow> rows = [
      // Header row
      pw.TableRow(
        decoration: pw.BoxDecoration(
          color: PdfColor.fromInt(0xFF6B5B4B),
        ),
        children: [
          _buildTableCell('Dato og tid', isHeader: true),
          _buildTableCell('Dag', isHeader: true),
          _buildTableCell('Vekt (g)', isHeader: true),
          _buildTableCell('Notater', isHeader: true),
        ],
      ),
    ];

    // Legg til fødselssvekt som dag 0 hvis den finnes
    if (puppy.birthWeight != null && puppy.birthWeight! > 0) {
      final dateTimeStr = DateFormat('dd.MM.yyyy HH:mm').format(puppy.dateOfBirth);
      rows.add(
        pw.TableRow(
          children: [
            _buildTableCell(dateTimeStr),
            _buildTableCell('0'),
            _buildTableCell('${puppy.birthWeight?.toStringAsFixed(0)}'),
            _buildTableCell('Fødselsvekt'),
          ],
        ),
      );
    }

    // Legg til registrerte vektmålinger
    rows.addAll(
      logs.map((log) {
        final hours = log.logDate.difference(puppy.dateOfBirth).inHours;
        final daysSinceBirth = (hours / 24).ceil();
        final dateTimeStr = DateFormat('dd.MM.yyyy HH:mm').format(log.logDate);
        return pw.TableRow(
          children: [
            _buildTableCell(dateTimeStr),
            _buildTableCell('$daysSinceBirth'),
            _buildTableCell(log.weight.toStringAsFixed(0)),
            _buildTableCell(log.notes ?? '-'),
          ],
        );
      }).toList(),
    );

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFCCCCCC)),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(0.8),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
      },
      children: rows,
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _buildRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  static Future<pw.Document> generateContractPDF(
    PurchaseContract contract,
    Puppy puppy,
    Buyer buyer,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'KJØPEKONTRAKT FOR VALP',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 24),
          
          // Contract Number and Date
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Kontraktnummer: ${contract.contractNumber ?? "—"}'),
              pw.Text('Dato: ${DateFormat('d. MMM yyyy', 'nb_NO').format(contract.contractDate)}'),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 20),

          // Parties Section
          pw.Text(
            'KONTRAKTSPARTIER',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('SELGER:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
              pw.SizedBox(height: 4),
              pw.Text('Oppsett av avler/kenneltype ikke implementert - vises senere'),
              pw.SizedBox(height: 16),
              pw.Text('KJØPER:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
              pw.SizedBox(height: 4),
              _buildRow('Navn:', buyer.name),
              if (buyer.address != null) _buildRow('Adresse:', buyer.address!),
              if (buyer.phone != null) _buildRow('Telefon:', buyer.phone!),
              if (buyer.email != null) _buildRow('E-post:', buyer.email!),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 20),

          // Puppy Information
          pw.Text(
            'VALPEN',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildRow('Navn:', puppy.name),
              _buildRow('Kjønn:', puppy.gender),
              _buildRow('Farge:', puppy.color),
              _buildRow('Fødselsdato:', DateFormat('d. MMM yyyy', 'nb_NO').format(puppy.dateOfBirth)),
              _buildRow('Alder ved salg:', '${puppy.getAgeInWeeks()} uker'),
              if (puppy.registrationNumber != null)
                _buildRow('Reg. nr.:', puppy.registrationNumber!),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 20),

          // Price and Payment Terms
          pw.Text(
            'PRIS OG BETALING',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildRow('Kjøpesum:', '${contract.price.toStringAsFixed(0)} kr'),
              if (contract.paymentTerms != null && contract.paymentTerms!.isNotEmpty)
                _buildRow('Betalingsbetingelser:', contract.paymentTerms!),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 20),

          // Contract Terms
          if (contract.terms != null && contract.terms!.isNotEmpty) ...[
            pw.Text(
              'KONTRAKTVILKÅR',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Text(contract.terms!),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 20),
          ],

          // Standard Clauses
          if (contract.spayNeuterRequired || contract.returnClauseIncluded) ...[
            pw.Text(
              'VILKÅR OG BETINGELSER',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (contract.spayNeuterRequired)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Text('• Kastrering/sterilisering er påkrevd'),
                  ),
                if (contract.returnClauseIncluded)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Text('• Returklausul er inkludert i denne kontrakten'),
                  ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 20),
          ],

          // Additional Notes
          if (contract.notes != null && contract.notes!.isNotEmpty) ...[
            pw.Text(
              'ØVRIG INFORMASJON',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Text(contract.notes!),
            pw.SizedBox(height: 20),
          ],

          pw.SizedBox(height: 30),
          pw.Divider(),
          pw.SizedBox(height: 20),

          // Signature Section
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(height: 30),
                  pw.Text('_________________________'),
                  pw.Text('Selger', style: pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(height: 30),
                  pw.Text('_________________________'),
                  pw.Text('Kjøper', style: pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Kontrakten ble generert av Breedly-appen',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );

    return pdf;
  }

  /// Genererer helseattest-PDF for valp før levering
  static Future<pw.Document> generateHealthCertificate(
    Puppy puppy,
    Litter litter, {
    String? vetName,
    String? vetClinic,
    String? vetPhone,
    DateTime? examDate,
    String? healthNotes,
    bool generalHealthOk = true,
    bool eyesOk = true,
    bool earsOk = true,
    bool heartOk = true,
    bool lungsOk = true,
    bool skinOk = true,
    bool teethOk = true,
    bool abdomenOk = true,
    bool limbsOk = true,
    Map<String, String>? healthCheckNotes,
  }) async {
    final pdf = pw.Document();
    final date = examDate ?? DateTime.now();
    final notes = healthCheckNotes ?? {};

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'HELSEATTEST FOR VALP',
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Veterinærkontroll før levering',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Divider(),
          pw.SizedBox(height: 16),

          // Puppy Information
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF5F5F5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'VALPENS INFORMASJON',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                _buildRow('Navn:', puppy.name),
                _buildRow('Rase:', litter.breed),
                _buildRow('Kjønn:', AppTranslations.translateGender(puppy.gender)),
                _buildRow('Farge:', puppy.color),
                _buildRow('Fødselsdato:', DateFormat('d. MMM yyyy', 'nb_NO').format(puppy.dateOfBirth)),
                _buildRow('Alder:', '${puppy.getAgeInWeeks()} uker'),
                if (puppy.registrationNumber != null)
                  _buildRow('Reg.nummer:', puppy.registrationNumber!),
                if (puppy.microchipped)
                  _buildRow('ID-merket:', 'Ja'),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Parent Information
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF5F5F5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'FORELDRE',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                _buildRow('Mor (tispe):', litter.damName),
                _buildRow('Far (hannhund):', litter.sireName),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 16),

          // Health Examination
          pw.Text(
            'HELSEUNDERSØKELSE',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Dato for undersøkelse: ${DateFormat('d. MMMM yyyy', 'nb_NO').format(date)}',
            style: pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(height: 12),

          // Health checklist table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(4),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF6B5B4B)),
                children: [
                  _buildTableCell('Undersøkelsesområde', isHeader: true),
                  _buildTableCell('Status', isHeader: true),
                  _buildTableCell('Merknader', isHeader: true),
                ],
              ),
              _buildHealthRow('Allmenntilstand', generalHealthOk, notes['generalHealth']),
              _buildHealthRow('Øyne', eyesOk, notes['eyes']),
              _buildHealthRow('Ører', earsOk, notes['ears']),
              _buildHealthRow('Hjerte', heartOk, notes['heart']),
              _buildHealthRow('Lunger', lungsOk, notes['lungs']),
              _buildHealthRow('Hud/pels', skinOk, notes['skin']),
              _buildHealthRow('Tenner/munn', teethOk, notes['teeth']),
              _buildHealthRow('Buk (abdomen)', abdomenOk, notes['abdomen']),
              _buildHealthRow('Lemmer/ledd', limbsOk, notes['limbs']),
            ],
          ),
          pw.SizedBox(height: 16),

          // Treatments
          pw.Text(
            'UTFØRTE BEHANDLINGER',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF6B5B4B)),
                children: [
                  _buildTableCell('Behandling', isHeader: true),
                  _buildTableCell('Utført', isHeader: true),
                ],
              ),
              pw.TableRow(
                children: [
                  _buildTableCell('Vaksinasjon'),
                  _buildTableCell(puppy.vaccinated ? '✓ Ja' : '✗ Nei'),
                ],
              ),
              pw.TableRow(
                children: [
                  _buildTableCell('Avmasking'),
                  _buildTableCell(puppy.dewormed ? '✓ Ja' : '✗ Nei'),
                ],
              ),
              pw.TableRow(
                children: [
                  _buildTableCell('ID-merking (mikrochip)'),
                  _buildTableCell(puppy.microchipped ? '✓ Ja' : '✗ Nei'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // Additional notes
          if (healthNotes != null && healthNotes.isNotEmpty) ...[
            pw.Text(
              'VETERINÆRENS MERKNADER',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(healthNotes),
            ),
            pw.SizedBox(height: 16),
          ],

          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 20),

          // Veterinarian info
          pw.Text(
            'VETERINÆR',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (vetClinic != null) _buildRow('Klinikk:', vetClinic),
          if (vetName != null) _buildRow('Veterinær:', vetName),
          if (vetPhone != null) _buildRow('Telefon:', vetPhone),

          pw.SizedBox(height: 30),
          
          // Signature
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(height: 40),
                  pw.Text('_________________________'),
                  pw.Text('Veterinærens underskrift', style: pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(height: 40),
                  pw.Text('_________________________'),
                  pw.Text('Stempel', style: pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Denne helseattesten bekrefter at valpen er undersøkt og funnet frisk ved dato for undersøkelse.',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey, fontStyle: pw.FontStyle.italic),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );

    return pdf;
  }

  static pw.TableRow _buildHealthRow(String area, bool isOk, [String? note]) {
    return pw.TableRow(
      children: [
        _buildTableCell(area),
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Center(
            child: pw.Text(
              isOk ? '✓ OK' : '✗',
              style: pw.TextStyle(
                color: isOk ? PdfColor.fromInt(0xFF228B22) : PdfColor.fromInt(0xFFDC143C),
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ),
        _buildTableCell(note?.isNotEmpty == true ? note! : (isOk ? '' : 'Avvik registrert')),
      ],
    );
  }

  /// Standard kontraktsvilkår for salg av valp
  static String getDefaultContractTerms() {
    return '''
1. GENERELT
Denne kontrakten regulerer kjøp og salg av valp mellom partene nevnt ovenfor.

2. HELSE
Selger garanterer at valpen ved overleveringstidspunktet er frisk og har gjennomgått veterinærkontroll. Eventuelle kjente helseproblemer skal være opplyst skriftlig.

3. VAKSINASJONER OG BEHANDLINGER
Valpen er vaksinert og avmasket i henhold til gjeldende retningslinjer. Dokumentasjon på dette følger med ved overlevering.

4. TILBAKELEVERING
Dersom kjøper ikke lenger kan beholde hunden, skal selger kontaktes først. Selger forbeholder seg retten til å ta hunden tilbake.

5. ANSVAR
Kjøper overtar alt ansvar for valpen fra overleveringstidspunktet. Kjøper forplikter seg til å gi valpen forsvarlig stell, mat og veterinærbehandling ved behov.

6. REGISTRERING
Valpen skal registreres på ny eier i henhold til gjeldende regelverk.
''';
  }

  /// Generate a pedigree PDF document for a dog
  static Future<pw.Document> generatePedigreePDF(Dog dog) async {
    final pdf = pw.Document();
    final dogsBox = Hive.box<Dog>('dogs');

    Dog? getDogById(String? id) {
      if (id == null) return null;
      try {
        return dogsBox.values.where((d) => d.id == id).firstOrNull;
      } catch (e) {
        return null;
      }
    }

    // Get ancestors
    final mother = getDogById(dog.damId);
    final father = getDogById(dog.sireId);
    final maternalGrandmother = getDogById(mother?.damId);
    final maternalGrandfather = getDogById(mother?.sireId);
    final paternalGrandmother = getDogById(father?.damId);
    final paternalGrandfather = getDogById(father?.sireId);

    // Great-grandparents
    final mmGrandmother = getDogById(maternalGrandmother?.damId);
    final mmGrandfather = getDogById(maternalGrandmother?.sireId);
    final mfGrandmother = getDogById(maternalGrandfather?.damId);
    final mfGrandfather = getDogById(maternalGrandfather?.sireId);
    final pmGrandmother = getDogById(paternalGrandmother?.damId);
    final pmGrandfather = getDogById(paternalGrandmother?.sireId);
    final pfGrandmother = getDogById(paternalGrandfather?.damId);
    final pfGrandfather = getDogById(paternalGrandfather?.sireId);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'STAMTAVLE',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      dog.name,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (dog.registrationNumber != null)
                      pw.Text(
                        'Reg.nr: ${dog.registrationNumber}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Dog info
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoPair('Rase', dog.breed),
                    _buildInfoPair('Kjønn', dog.gender),
                    _buildInfoPair('Født', DateFormat('dd.MM.yyyy').format(dog.dateOfBirth)),
                    _buildInfoPair('Farge', dog.color),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Pedigree table
              pw.Expanded(
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    // Parents column
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        children: [
                          pw.Expanded(
                            child: _buildPedigreeCell(mother, 'MOR'),
                          ),
                          pw.Expanded(
                            child: _buildPedigreeCell(father, 'FAR'),
                          ),
                        ],
                      ),
                    ),
                    // Grandparents column
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        children: [
                          pw.Expanded(child: _buildPedigreeCell(maternalGrandmother, 'Mormor')),
                          pw.Expanded(child: _buildPedigreeCell(maternalGrandfather, 'Morfar')),
                          pw.Expanded(child: _buildPedigreeCell(paternalGrandmother, 'Farmor')),
                          pw.Expanded(child: _buildPedigreeCell(paternalGrandfather, 'Farfar')),
                        ],
                      ),
                    ),
                    // Great-grandparents column
                    pw.Expanded(
                      flex: 3,
                      child: pw.Column(
                        children: [
                          pw.Expanded(child: _buildPedigreeCell(mmGrandmother, 'Mormors mor')),
                          pw.Expanded(child: _buildPedigreeCell(mmGrandfather, 'Mormors far')),
                          pw.Expanded(child: _buildPedigreeCell(mfGrandmother, 'Morfars mor')),
                          pw.Expanded(child: _buildPedigreeCell(mfGrandfather, 'Morfars far')),
                          pw.Expanded(child: _buildPedigreeCell(pmGrandmother, 'Farmors mor')),
                          pw.Expanded(child: _buildPedigreeCell(pmGrandfather, 'Farmors far')),
                          pw.Expanded(child: _buildPedigreeCell(pfGrandmother, 'Farfars mor')),
                          pw.Expanded(child: _buildPedigreeCell(pfGrandfather, 'Farfars far')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Footer
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Generert ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())} - Breedly',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildInfoPair(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _buildPedigreeCell(Dog? dog, String label) {
    return pw.Container(
      margin: const pw.EdgeInsets.all(2),
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(2),
        color: dog != null ? PdfColors.grey100 : PdfColors.white,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            dog?.name ?? 'Ukjent',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
            maxLines: 1,
          ),
          if (dog?.registrationNumber != null)
            pw.Text(
              dog!.registrationNumber!,
              style: const pw.TextStyle(fontSize: 7),
              maxLines: 1,
            ),
          if (dog != null && dog.breed.isNotEmpty)
            pw.Text(
              dog.breed,
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
              maxLines: 1,
            ),
        ],
      ),
    );
  }
}
