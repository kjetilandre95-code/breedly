import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:breedly/models/purchase_contract.dart';
import 'package:breedly/models/buyer.dart';
import 'package:breedly/models/puppy.dart';
import 'package:breedly/models/dog.dart';
import 'package:breedly/models/kennel.dart';

/// Contract types available in the app
enum ContractType {
  purchase, // Kjøpskontrakt
  breeding, // Avlskontrakt
  coOwnership, // Medeieravtale
  foster, // Fôrvertsavtale
  reservation, // Reservasjonsavtale
}

class PdfContractService {
  static final PdfContractService _instance = PdfContractService._internal();
  factory PdfContractService() => _instance;
  PdfContractService._internal();

  final _dateFormat = DateFormat('dd.MM.yyyy');

  /// Generate a purchase contract PDF
  Future<File> generateContractPdf({
    required PurchaseContract contract,
    required Buyer buyer,
    required Puppy puppy,
    Dog? mother,
    Dog? father,
    Kennel? kennel,
    String? breed,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(kennel),
          pw.SizedBox(height: 15),
          _buildTitle(),
          pw.SizedBox(height: 15),
          _buildSellerSection(kennel),
          pw.SizedBox(height: 12),
          _buildBuyerSection(buyer),
          pw.SizedBox(height: 12),
          _buildDogSection(puppy, mother, father, breed),
          pw.SizedBox(height: 12),
          _buildPaymentAndDeliverySection(contract),
          pw.SizedBox(height: 12),
          _buildDocumentationSection(contract, puppy),
          pw.SizedBox(height: 12),
          _buildTermsSection(contract),
          if (contract.specialTerms != null && contract.specialTerms!.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _buildSpecialTermsSection(contract),
          ],
          pw.SizedBox(height: 12),
          _buildLegalInfoSection(),
          pw.SizedBox(height: 25),
          _buildEnhancedSignatureSection(contract, buyer, kennel),
        ],
      ),
    );

    // Save to file
    final output = await getTemporaryDirectory();
    final fileName =
        'kontrakt_${puppy.name}_${_dateFormat.format(DateTime.now()).replaceAll('.', '-')}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Generate and share contract PDF
  Future<void> shareContractPdf({
    required PurchaseContract contract,
    required Buyer buyer,
    required Puppy puppy,
    Dog? mother,
    Dog? father,
    Kennel? kennel,
  }) async {
    final file = await generateContractPdf(
      contract: contract,
      buyer: buyer,
      puppy: puppy,
      mother: mother,
      father: father,
      kennel: kennel,
    );

    await Share.shareXFiles([
      XFile(file.path),
    ], subject: 'Kjøpskontrakt - ${puppy.name}');
  }

  pw.Widget _buildHeader(Kennel? kennel) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              kennel?.name ?? 'Kennel',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            if (kennel?.address != null)
              pw.Text(
                kennel!.address!,
                style: const pw.TextStyle(fontSize: 10),
              ),
            if (kennel?.contactPhone != null)
              pw.Text(
                'Tlf: ${kennel!.contactPhone}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            if (kennel?.contactEmail != null)
              pw.Text(
                kennel!.contactEmail!,
                style: const pw.TextStyle(fontSize: 10),
              ),
          ],
        ),
        pw.Text(
          _dateFormat.format(DateTime.now()),
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  pw.Widget _buildTitle() {
    return pw.Center(
      child: pw.Text(
        'KJØPSKONTRAKT FOR VALP',
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _buildSellerSection(Kennel? kennel) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SELGER',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text('Navn: ${kennel?.name ?? '________________________'}'),
          pw.SizedBox(height: 3),
          pw.Text('Adresse: ${kennel?.address ?? '________________________'}'),
          pw.SizedBox(height: 3),
          pw.Text(
            'Telefon: ${kennel?.contactPhone ?? '________________________'}',
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'E-post: ${kennel?.contactEmail ?? '________________________'}',
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBuyerSection(Buyer buyer) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'KJØPER',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text('Navn: ${buyer.name}'),
          pw.SizedBox(height: 3),
          pw.Text('Adresse: ${buyer.address ?? '________________________'}'),
          pw.SizedBox(height: 3),
          pw.Text('Telefon: ${buyer.phone ?? '________________________'}'),
          pw.SizedBox(height: 3),
          pw.Text('E-post: ${buyer.email ?? '________________________'}'),
        ],
      ),
    );
  }

  // ============================================
  // ENHANCED DOG SECTION (Based on standard agreement)
  // ============================================

  pw.Widget _buildDogSection(Puppy puppy, Dog? mother, Dog? father, String? breed) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'HUND',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildLabelValue('Hundens navn:', puppy.name),
                    _buildLabelValue('Rase:', breed ?? 'Ikke angitt'),
                    _buildLabelValue('Fødselsdato:', _dateFormat.format(puppy.dateOfBirth)),
                    _buildLabelValue('Farge:', puppy.color),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildLabelValue('Kjønn:', puppy.gender == 'Male' ? 'Hann' : 'Tispe'),
                    _buildLabelValue('Reg.nr:', puppy.registrationNumber ?? 'Ikke registrert'),
                    _buildLabelValue('ID-merke/Mikrochip:', puppy.microchipped ? 'Ja' : 'Nei'),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Foreldre:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Mor (tispe):', style: const pw.TextStyle(fontSize: 9)),
                          pw.Text(mother?.name ?? 'Ikke angitt', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                          pw.Text('Reg.nr: ${mother?.registrationNumber ?? '-'}', style: const pw.TextStyle(fontSize: 8)),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Far (hannhund):', style: const pw.TextStyle(fontSize: 9)),
                          pw.Text(father?.name ?? 'Ikke angitt', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                          pw.Text('Reg.nr: ${father?.registrationNumber ?? '-'}', style: const pw.TextStyle(fontSize: 8)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildLabelValue(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
          ),
        ],
      ),
    );
  }

  // ============================================
  // PAYMENT AND DELIVERY SECTION
  // ============================================

  pw.Widget _buildPaymentAndDeliverySection(PurchaseContract contract) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'BETALING',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildLabelValue('Kjøpesum:', 'kr ${contract.price.toStringAsFixed(0)},-'),
                    if (contract.deposit != null && contract.deposit! > 0)
                      _buildLabelValue('Depositum:', 'kr ${contract.deposit!.toStringAsFixed(0)},-'),
                    _buildLabelValue('Restbeløp:', contract.deposit != null && contract.deposit! > 0
                        ? 'kr ${(contract.price - contract.deposit!).toStringAsFixed(0)},-'
                        : 'kr ${contract.price.toStringAsFixed(0)},-'),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildLabelValue('Overtagelsesdato:', contract.purchaseDate != null 
                        ? _dateFormat.format(contract.purchaseDate!) 
                        : '________________________'),
                    if (contract.deliveryLocation != null && contract.deliveryLocation!.isNotEmpty)
                      _buildLabelValue('Sted:', contract.deliveryLocation!),
                  ],
                ),
              ),
            ],
          ),
          if (contract.paymentTerms != null && contract.paymentTerms!.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text('Betalingsvilkår: ${contract.paymentTerms}', style: const pw.TextStyle(fontSize: 9)),
          ],
        ],
      ),
    );
  }

  // ============================================
  // DOCUMENTATION SECTION
  // ============================================

  pw.Widget _buildDocumentationSection(PurchaseContract contract, Puppy puppy) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DOKUMENTASJON',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _buildCheckboxRow('Registreringsbevis (stamtavle) overlevert ved avhenting', contract.pedigreeDelivered),
          _buildCheckboxRow('Veterinærattest vedheftes avtalen', contract.vetCertificateAttached),
          _buildCheckboxRow('Hunden er ID-merket (mikrochip)', puppy.microchipped),
          _buildCheckboxRow('Hunden er vaksinert', puppy.vaccinated),
          _buildCheckboxRow('Hunden er avlustet/ormet', puppy.dewormed),
          if (contract.insuranceTransferred)
            _buildCheckboxRow('Forsikring overføres til kjøper', contract.insuranceTransferred),
          pw.SizedBox(height: 8),
          pw.Text(
            'Selger forplikter seg til å sørge for at eierskifte blir foretatt så snart som mulig etter at kjøpesummen er betalt.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCheckboxRow(String label, bool checked) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Container(
            width: 12,
            height: 12,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey600),
            ),
            child: checked
                ? pw.Center(child: pw.Text('X', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)))
                : null,
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(child: pw.Text(label, style: const pw.TextStyle(fontSize: 9))),
        ],
      ),
    );
  }

  // ============================================
  // SPECIAL TERMS SECTION
  // ============================================

  pw.Widget _buildSpecialTermsSection(PurchaseContract contract) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SÆRLIGE VILKÅR',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(contract.specialTerms ?? '', style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  // ============================================
  // LEGAL INFO SECTION
  // ============================================

  pw.Widget _buildLegalInfoSection() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Partenes plikter',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '• Kjøper bekrefter at hunden er besiktiget og funnet i orden ved avtaleinngåelsen.',
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.Text(
            '• Selger bekrefter at kjøper er informert om eventuelle forhold ved hunden som selger har kjennskap til.',
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.Text(
            '• Selger bekrefter at kjøper er informert om kjente arvelige sykdommer innen rasen.',
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Mangel og reklamasjon',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Hunden har en mangel dersom den ikke svarer til det den er solgt som. Ved eventuelle problemer kontaktes oppdretter først. Reklamasjon må fremsettes innen rimelig tid etter at mangelen ble oppdaget.',
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Det foreligger ikke angrerett ved kjøp av hund.',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ============================================
  // ENHANCED SIGNATURE SECTION
  // ============================================

  pw.Widget _buildEnhancedSignatureSection(
    PurchaseContract contract,
    Buyer buyer,
    Kennel? kennel,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Undertegnede, kjøper og selger, bekrefter at vi har gjennomgått denne kjøpeavtalen.',
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Sted:', style: const pw.TextStyle(fontSize: 9)),
                pw.Container(
                  width: 150,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
                  ),
                  child: pw.SizedBox(height: 20),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Dato:', style: const pw.TextStyle(fontSize: 9)),
                pw.Container(
                  width: 150,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
                  ),
                  child: pw.SizedBox(height: 20),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Selger:', style: const pw.TextStyle(fontSize: 9)),
                pw.Container(
                  width: 150,
                  height: 40,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  kennel?.name ?? '',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Sted:', style: const pw.TextStyle(fontSize: 9)),
                pw.Container(
                  width: 150,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
                  ),
                  child: pw.SizedBox(height: 20),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Dato:', style: const pw.TextStyle(fontSize: 9)),
                pw.Container(
                  width: 150,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
                  ),
                  child: pw.SizedBox(height: 20),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Kjøper:', style: const pw.TextStyle(fontSize: 9)),
                pw.Container(
                  width: 150,
                  height: 40,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  buyer.name,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPuppySection(Puppy puppy, Dog? mother, Dog? father) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'VALP',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text('Navn: ${puppy.name}'),
          pw.SizedBox(height: 3),
          pw.Text('Kjønn: ${puppy.gender == 'Male' ? 'Hannhund' : 'Tispe'}'),
          pw.SizedBox(height: 3),
          pw.Text('Farge: ${puppy.color}'),
          pw.SizedBox(height: 3),
          pw.Text(
            'Reg.nr: ${puppy.registrationNumber ?? '________________________'}',
          ),
          pw.SizedBox(height: 3),
          pw.Text('Mikrochip: ${puppy.microchipped ? 'Ja' : 'Nei'}'),
          pw.SizedBox(height: 8),
          pw.Text(
            'Foreldre:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'Mor: ${mother?.name ?? 'Ukjent'} (${mother?.registrationNumber ?? '-'})',
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'Far: ${father?.name ?? 'Ukjent'} (${father?.registrationNumber ?? '-'})',
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTermsSection(PurchaseContract contract) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'VILKÅR',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          if (contract.terms != null && contract.terms!.isNotEmpty)
            pw.Text(contract.terms!)
          else ...[
            pw.Text(
              '1. Valpen leveres med veterinærattest, vaksinasjonskort og registreringsbevis.',
            ),
            pw.SizedBox(height: 3),
            pw.Text('2. Selger garanterer at valpen er frisk ved levering.'),
            pw.SizedBox(height: 3),
            pw.Text(
              '3. Kjøper forplikter seg til å gi valpen god omsorg og stell.',
            ),
            pw.SizedBox(height: 3),
            pw.Text('4. Ved eventuelle problemer kontaktes oppdretter først.'),
          ],
          if (contract.spayNeuterRequired == true) ...[
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(5),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
              ),
              child: pw.Text(
                'KASTRERING/STERILISERING: Hunden skal kastreres/steriliseres i henhold til avtale med oppdretter.',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildSignatureSection(
    PurchaseContract contract,
    Buyer buyer,
    Kennel? kennel,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
      children: [
        pw.Column(
          children: [
            pw.Container(
              width: 200,
              height: 50,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.black),
                ),
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text('Selger'),
            pw.Text(
              kennel?.name ?? '',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
        pw.Column(
          children: [
            pw.Container(
              width: 200,
              height: 50,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.black),
                ),
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text('Kjøper'),
            pw.Text(buyer.name, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ],
    );
  }

  // ============================================
  // RESERVATION CONTRACT (Reservasjonsavtale)
  // ============================================

  /// Generate a reservation contract PDF
  Future<File> generateReservationContractPdf({
    required Buyer buyer,
    required Puppy puppy,
    required double reservationFee,
    required double totalPrice,
    Dog? mother,
    Dog? father,
    Kennel? kennel,
    String? notes,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(kennel),
          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Text(
              'RESERVASJONSAVTALE FOR VALP',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),
          _buildSellerSection(kennel),
          pw.SizedBox(height: 15),
          _buildBuyerSection(buyer),
          pw.SizedBox(height: 15),
          _buildPuppySection(puppy, mother, father),
          pw.SizedBox(height: 15),
          _buildReservationTermsSection(reservationFee, totalPrice, notes),
          pw.SizedBox(height: 30),
          _buildSignatureSection(
            PurchaseContract(
              id: '',
              buyerId: buyer.id,
              puppyId: puppy.id,
              contractDate: DateTime.now(),
              price: totalPrice,
              status: 'reserved',
            ),
            buyer,
            kennel,
          ),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final fileName =
        'reservasjon_${puppy.name}_${_dateFormat.format(DateTime.now()).replaceAll('.', '-')}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildReservationTermsSection(
    double reservationFee,
    double totalPrice,
    String? notes,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RESERVASJONSVILKÅR',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Reservasjonsgebyr:'),
              pw.Text(
                'kr ${reservationFee.toStringAsFixed(0)},-',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total pris for valpen:'),
              pw.Text(
                'kr ${totalPrice.toStringAsFixed(0)},-',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Gjenstående ved levering:'),
              pw.Text(
                'kr ${(totalPrice - reservationFee).toStringAsFixed(0)},-',
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Text(
            'Vilkår:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            '1. Reservasjonsgebyret er ikke refunderbart med mindre oppdretteren kansellerer.',
          ),
          pw.SizedBox(height: 3),
          pw.Text('2. Reservasjonsgebyret trekkes fra totalprisen ved kjøp.'),
          pw.SizedBox(height: 3),
          pw.Text('3. Valpen er reservert inntil full betaling er mottatt.'),
          pw.SizedBox(height: 3),
          pw.Text(
            '4. Ved avbestilling etter at valpen er 6 uker, beholdes gebyret.',
          ),
          if (notes != null && notes.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              'Tilleggsnotater:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 5),
            pw.Text(notes),
          ],
        ],
      ),
    );
  }

  // ============================================
  // BREEDING CONTRACT (Avlskontrakt)
  // ============================================

  /// Generate a breeding contract PDF
  Future<File> generateBreedingContractPdf({
    required Dog stud,
    required Dog dam,
    required String studOwnerName,
    required String damOwnerName,
    required String studOwnerAddress,
    required String damOwnerAddress,
    required double studFee,
    required String paymentTerms,
    Kennel? kennel,
    String? additionalTerms,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(kennel),
          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Text(
              'AVLSKONTRAKT / PARINGSAVTALE',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),
          _buildBreedingPartiesSection(
            stud,
            studOwnerName,
            studOwnerAddress,
            dam,
            damOwnerName,
            damOwnerAddress,
          ),
          pw.SizedBox(height: 15),
          _buildBreedingDogsSection(stud, dam),
          pw.SizedBox(height: 15),
          _buildBreedingFeeSection(studFee, paymentTerms),
          pw.SizedBox(height: 15),
          _buildBreedingTermsSection(additionalTerms),
          pw.SizedBox(height: 30),
          _buildBreedingSignatureSection(studOwnerName, damOwnerName),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final fileName =
        'avlskontrakt_${stud.name}_${dam.name}_${_dateFormat.format(DateTime.now()).replaceAll('.', '-')}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildBreedingPartiesSection(
    Dog stud,
    String studOwner,
    String studAddress,
    Dog dam,
    String damOwner,
    String damAddress,
  ) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'HANNHUNDEIER',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text('Navn: $studOwner'),
                pw.SizedBox(height: 3),
                pw.Text('Adresse: $studAddress'),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'TISPEEIER',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text('Navn: $damOwner'),
                pw.SizedBox(height: 3),
                pw.Text('Adresse: $damAddress'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildBreedingDogsSection(Dog stud, Dog dam) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'HUNDER SOM SKAL PARES',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Hannhund:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text('Navn: ${stud.name}'),
                    pw.Text('Reg.nr: ${stud.registrationNumber ?? '-'}'),
                    pw.Text('Rase: ${stud.breed}'),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Tispe:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text('Navn: ${dam.name}'),
                    pw.Text('Reg.nr: ${dam.registrationNumber ?? '-'}'),
                    pw.Text('Rase: ${dam.breed}'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBreedingFeeSection(double studFee, String paymentTerms) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DEKNINGSAVGIFT',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Avtalt paringsgebyr:'),
              pw.Text(
                'kr ${studFee.toStringAsFixed(0)},-',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Betalingsvilkår:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text(paymentTerms),
        ],
      ),
    );
  }

  pw.Widget _buildBreedingTermsSection(String? additionalTerms) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'VILKÅR',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            '1. Paringstidspunkt avtales mellom partene basert på tispens løpetid.',
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            '2. Hannhundeier har rett til å se dokumentasjon på tispens helsestatus.',
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            '3. Ved tom tispe gis normalt én ny dekking uten ekstra kostnad.',
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            '4. Begge parter er ansvarlige for å sikre at hundene er fri for arvelige sykdommer.',
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            '5. Registrering av kullet skal skje i henhold til gjeldende regler.',
          ),
          if (additionalTerms != null && additionalTerms.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              'Tilleggsvilkår:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 5),
            pw.Text(additionalTerms),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildBreedingSignatureSection(String studOwner, String damOwner) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
      children: [
        pw.Column(
          children: [
            pw.Container(
              width: 200,
              height: 50,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.black),
                ),
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text('Hannhundeier'),
            pw.Text(studOwner, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.Column(
          children: [
            pw.Container(
              width: 200,
              height: 50,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.black),
                ),
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text('Tispeeier'),
            pw.Text(damOwner, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ],
    );
  }

  // ============================================
  // CO-OWNERSHIP CONTRACT (Medeieravtale)
  // ============================================

  /// Generate a co-ownership contract PDF
  Future<File> generateCoOwnershipContractPdf({
    required Dog dog,
    required String owner1Name,
    required String owner1Address,
    required String owner2Name,
    required String owner2Address,
    required int owner1Percentage,
    required String primaryCaretaker,
    required String breedingRights,
    required String showRights,
    required String expenseSharing,
    Kennel? kennel,
    String? additionalTerms,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(kennel),
          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Text(
              'MEDEIERAVTALE / SAMEIEKONTRAKT',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),
          _buildCoOwnershipPartiesSection(
            owner1Name,
            owner1Address,
            owner2Name,
            owner2Address,
            owner1Percentage,
          ),
          pw.SizedBox(height: 15),
          _buildCoOwnershipDogSection(dog),
          pw.SizedBox(height: 15),
          _buildCoOwnershipTermsSection(
            primaryCaretaker,
            breedingRights,
            showRights,
            expenseSharing,
            additionalTerms,
          ),
          pw.SizedBox(height: 30),
          _buildBreedingSignatureSection(owner1Name, owner2Name),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final fileName =
        'medeieravtale_${dog.name}_${_dateFormat.format(DateTime.now()).replaceAll('.', '-')}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildCoOwnershipPartiesSection(
    String owner1,
    String owner1Address,
    String owner2,
    String owner2Address,
    int owner1Percentage,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'MEDEIERE',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Eier 1:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(owner1),
                    pw.Text(
                      owner1Address,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text('Eierandel: $owner1Percentage%'),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Eier 2:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(owner2),
                    pw.Text(
                      owner2Address,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text('Eierandel: ${100 - owner1Percentage}%'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCoOwnershipDogSection(Dog dog) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'HUND',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text('Navn: ${dog.name}'),
          pw.Text('Rase: ${dog.breed}'),
          pw.Text('Reg.nr: ${dog.registrationNumber ?? '-'}'),
          pw.Text('Kjønn: ${dog.gender == 'Male' ? 'Hannhund' : 'Tispe'}'),
          pw.Text('Fødselsdato: ${_dateFormat.format(dog.dateOfBirth)}'),
        ],
      ),
    );
  }

  pw.Widget _buildCoOwnershipTermsSection(
    String primaryCaretaker,
    String breedingRights,
    String showRights,
    String expenseSharing,
    String? additionalTerms,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'AVTALEVILKÅR',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Primær omsorgsgiver: $primaryCaretaker',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Avlsrettigheter:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(breedingRights),
          pw.SizedBox(height: 8),
          pw.Text(
            'Utstillingsrettigheter:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(showRights),
          pw.SizedBox(height: 8),
          pw.Text(
            'Fordeling av utgifter:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(expenseSharing),
          pw.SizedBox(height: 10),
          pw.Text(
            'Generelle vilkår:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text('1. Alle avgjørelser om hundens velferd tas i fellesskap.'),
          pw.Text(
            '2. Ved uenighet skal mekling forsøkes før rettslige skritt.',
          ),
          pw.Text('3. Salg av hunden krever samtykke fra begge parter.'),
          pw.Text('4. Endringer i avtalen må gjøres skriftlig.'),
          if (additionalTerms != null && additionalTerms.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              'Tilleggsvilkår:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(additionalTerms),
          ],
        ],
      ),
    );
  }

  // ============================================
  // FOSTER CONTRACT (Fôrvertsavtale)
  // ============================================

  /// Generate a foster agreement PDF
  Future<File> generateFosterContractPdf({
    required Dog dog,
    required String ownerName,
    required String ownerAddress,
    required String fosterName,
    required String fosterAddress,
    required DateTime startDate,
    DateTime? endDate,
    required String breedingTerms,
    required String expenseTerms,
    required String returnConditions,
    Kennel? kennel,
    String? additionalTerms,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(kennel),
          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Text(
              'FÔRVERTSAVTALE',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),
          _buildFosterPartiesSection(
            ownerName,
            ownerAddress,
            fosterName,
            fosterAddress,
          ),
          pw.SizedBox(height: 15),
          _buildCoOwnershipDogSection(dog),
          pw.SizedBox(height: 15),
          _buildFosterPeriodSection(startDate, endDate),
          pw.SizedBox(height: 15),
          _buildFosterTermsSection(
            breedingTerms,
            expenseTerms,
            returnConditions,
            additionalTerms,
          ),
          pw.SizedBox(height: 30),
          _buildBreedingSignatureSection(ownerName, fosterName),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final fileName =
        'forvertsavtale_${dog.name}_${_dateFormat.format(DateTime.now()).replaceAll('.', '-')}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildFosterPartiesSection(
    String owner,
    String ownerAddress,
    String foster,
    String fosterAddress,
  ) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'EIER',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text('Navn: $owner'),
                pw.Text('Adresse: $ownerAddress'),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'FÔRVERT',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text('Navn: $foster'),
                pw.Text('Adresse: $fosterAddress'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildFosterPeriodSection(DateTime startDate, DateTime? endDate) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'AVTALEPERIODE',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text('Fra: ${_dateFormat.format(startDate)}'),
          pw.Text(
            'Til: ${endDate != null ? _dateFormat.format(endDate) : 'Ubestemt / Etter avtale'}',
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFosterTermsSection(
    String breedingTerms,
    String expenseTerms,
    String returnConditions,
    String? additionalTerms,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'VILKÅR',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Avlsvilkår:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(breedingTerms),
          pw.SizedBox(height: 8),
          pw.Text(
            'Utgifter:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(expenseTerms),
          pw.SizedBox(height: 8),
          pw.Text(
            'Tilbakeleveringsvilkår:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(returnConditions),
          pw.SizedBox(height: 10),
          pw.Text(
            'Generelle vilkår:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            '1. Fôrvert forplikter seg til å gi hunden god omsorg og oppfølging.',
          ),
          pw.Text(
            '2. Eier beholder alle rettigheter til hunden og dens avkom.',
          ),
          pw.Text(
            '3. Fôrvert kan ikke avle på hunden uten skriftlig samtykke fra eier.',
          ),
          pw.Text(
            '4. Hunden kan ikke selges, gis bort eller omplasseres uten eiers samtykke.',
          ),
          pw.Text(
            '5. Eier har rett til å inspisere hundens forhold med rimelig varsel.',
          ),
          if (additionalTerms != null && additionalTerms.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              'Tilleggsvilkår:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(additionalTerms),
          ],
        ],
      ),
    );
  }
}
