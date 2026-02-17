import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:breedly/models/puppy.dart';
import 'package:breedly/models/buyer.dart';
import 'package:breedly/models/purchase_contract.dart';
import 'package:uuid/uuid.dart';
import 'package:breedly/utils/pdf_generator.dart';
import 'package:breedly/utils/notification_service.dart';
import 'package:breedly/utils/constants.dart';
import 'dart:io' show Directory, File;
import 'package:path_provider/path_provider.dart';
import 'package:breedly/utils/app_bar_builder.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/utils/theme_colors.dart';
import 'package:breedly/services/auth_service.dart';
import 'package:breedly/services/cloud_sync_service.dart';

class PurchaseContractScreen extends StatefulWidget {
  final Puppy puppy;
  final PurchaseContract? existingContract;

  const PurchaseContractScreen({
    super.key,
    required this.puppy,
    this.existingContract,
  });

  @override
  State<PurchaseContractScreen> createState() => _PurchaseContractScreenState();
}

class _PurchaseContractScreenState extends State<PurchaseContractScreen> {
  late PurchaseContract _contract;
  late List<Buyer> _availableBuyers;
  Buyer? _selectedBuyer;

  final _priceController = TextEditingController();
  final _contractNumberController = TextEditingController();
  final _paymentTermsController = TextEditingController();
  final _termsController = TextEditingController();
  final _notesController = TextEditingController();
  final _depositController = TextEditingController();
  final _deliveryLocationController = TextEditingController();
  final _specialTermsController = TextEditingController();

  bool _spayNeuterRequired = false;
  bool _returnClauseIncluded = false;
  bool _pedigreeDelivered = false;
  bool _vetCertificateAttached = false;
  bool _insuranceTransferred = false;

  // Standard kontraktvilkår checkboxes
  bool _termGeneral = true;
  bool _termHealth = true;
  bool _termVaccination = true;
  bool _termReturn = true;
  bool _termResponsibility = true;
  bool _termRegistration = true;

  @override
  void initState() {
    super.initState();
    _loadBuyers();
    _initializeContract();
  }

  void _loadBuyers() {
    final buyerBox = Hive.box<Buyer>('buyers');
    _availableBuyers = buyerBox.values.toList();
  }

  void _initializeContract() {
    // Use provided contract or check if one exists for this puppy
    if (widget.existingContract != null) {
      _contract = widget.existingContract!;
    } else {
      final contractBox = Hive.box<PurchaseContract>('purchase_contracts');
      final existingContract = contractBox.values.firstWhere(
        (c) => c.puppyId == widget.puppy.id,
        orElse: () => PurchaseContract(
          id: const Uuid().v4(),
          puppyId: widget.puppy.id,
          buyerId: '',
          contractDate: DateTime.now(),
          price: 0,
          dateAdded: DateTime.now(),
        ),
      );
      _contract = existingContract;
    }

    // Populate controllers if contract exists
    if (_contract.price > 0 || _contract.buyerId.isNotEmpty) {
      _priceController.text = _contract.price.toString();
      _contractNumberController.text = _contract.contractNumber ?? '';
      _paymentTermsController.text = _contract.paymentTerms ?? '';
      _termsController.text = _contract.terms ?? '';
      _notesController.text = _contract.notes ?? '';
      _depositController.text = _contract.deposit?.toString() ?? '';
      _deliveryLocationController.text = _contract.deliveryLocation ?? '';
      _specialTermsController.text = _contract.specialTerms ?? '';
      _spayNeuterRequired = _contract.spayNeuterRequired;
      _returnClauseIncluded = _contract.returnClauseIncluded;
      _pedigreeDelivered = _contract.pedigreeDelivered;
      _vetCertificateAttached = _contract.vetCertificateAttached;
      _insuranceTransferred = _contract.insuranceTransferred;

      // Parse existing terms to set checkboxes
      final existingTerms = _contract.terms ?? '';
      if (existingTerms.isNotEmpty) {
        _termGeneral = existingTerms.contains('GENERELT');
        _termHealth = existingTerms.contains('HELSE');
        _termVaccination = existingTerms.contains('VAKSINASJONER');
        _termReturn = existingTerms.contains('TILBAKELEVERING');
        _termResponsibility = existingTerms.contains('ANSVAR');
        _termRegistration = existingTerms.contains('REGISTRERING');
      }

      // Set selected buyer if exists
      try {
        _selectedBuyer = _availableBuyers.firstWhere(
          (b) => b.id == _contract.buyerId,
        );
      } catch (e) {
        _selectedBuyer = null;
      }
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _contractNumberController.dispose();
    _paymentTermsController.dispose();
    _termsController.dispose();
    _notesController.dispose();
    _depositController.dispose();
    _deliveryLocationController.dispose();
    _specialTermsController.dispose();
    super.dispose();
  }

  String _buildSelectedTerms() {
    final sections = <String>[];
    int num = 1;
    if (_termGeneral) {
      sections.add('$num. GENERELT\nDenne kontrakten regulerer kjøp og salg av valp mellom partene nevnt ovenfor.');
      num++;
    }
    if (_termHealth) {
      sections.add('$num. HELSE\nSelger garanterer at valpen ved overleveringstidspunktet er frisk og har gjennomgått veterinærkontroll. Eventuelle kjente helseproblemer skal være opplyst skriftlig.');
      num++;
    }
    if (_termVaccination) {
      sections.add('$num. VAKSINASJONER OG BEHANDLINGER\nValpen er vaksinert og avmasket i henhold til gjeldende retningslinjer. Dokumentasjon på dette følger med ved overlevering.');
      num++;
    }
    if (_termReturn) {
      sections.add('$num. TILBAKELEVERING\nDersom kjøper ikke lenger kan beholde hunden, skal selger kontaktes først. Selger forbeholder seg retten til å ta hunden tilbake.');
      num++;
    }
    if (_termResponsibility) {
      sections.add('$num. ANSVAR\nKjøper overtar alt ansvar for valpen fra overleveringstidspunktet. Kjøper forplikter seg til å gi valpen forsvarlig stell, mat og veterinærbehandling ved behov.');
      num++;
    }
    if (_termRegistration) {
      sections.add('$num. REGISTRERING\nValpen skal registreres på ny eier i henhold til gjeldende regelverk.');
      num++;
    }
    return sections.join('\n\n');
  }

  void _saveContract() async {
    if (_selectedBuyer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Velg en kjøper')),
      );
      return;
    }

    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Angi pris')),
      );
      return;
    }

    try {
      final price = double.parse(_priceController.text);

      // Parse deposit if provided
      double? deposit;
      if (_depositController.text.isNotEmpty) {
        deposit = double.tryParse(_depositController.text);
      }

      _contract
        ..puppyId = widget.puppy.id
        ..buyerId = _selectedBuyer!.id
        ..contractDate = _contract.contractDate
        ..price = price
        ..contractNumber = _contractNumberController.text.isEmpty
            ? null
            : _contractNumberController.text
        ..paymentTerms = _paymentTermsController.text.isEmpty
            ? null
            : _paymentTermsController.text
        ..terms = _buildSelectedTerms().isEmpty ? null : _buildSelectedTerms()
        ..notes = _notesController.text.isEmpty ? null : _notesController.text
        ..spayNeuterRequired = _spayNeuterRequired
        ..returnClauseIncluded = _returnClauseIncluded
        ..deposit = deposit
        ..pedigreeDelivered = _pedigreeDelivered
        ..vetCertificateAttached = _vetCertificateAttached
        ..deliveryLocation = _deliveryLocationController.text.isEmpty
            ? null
            : _deliveryLocationController.text
        ..specialTerms = _specialTermsController.text.isEmpty
            ? null
            : _specialTermsController.text
        ..insuranceTransferred = _insuranceTransferred;

      final contractBox = Hive.box<PurchaseContract>('purchase_contracts');
      
      // Always use put() with contract.id as key to avoid duplicates
      await contractBox.put(_contract.id, _contract);

      // Save to Firebase
      final userId = AuthService().currentUser?.uid;
      if (userId != null) {
        await CloudSyncService().savePurchaseContract(
          userId: userId,
          contractId: _contract.id,
          contractData: _contract.toJson(),
        );
      }

      // Update puppy status
      widget.puppy.status = 'Reserved';
      widget.puppy.save();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kontrakt lagret')),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Feil ved lagring: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarBuilder.buildAppBar(
        title: 'Kjøpekontrakt',
        context: context,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Puppy Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Valp',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.puppy.gender == 'Male'
                                  ? AppColors.male.withValues(alpha: ThemeOpacity.high(context))
                                  : AppColors.female.withValues(alpha: ThemeOpacity.high(context)),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.pets,
                                color: widget.puppy.gender == 'Male'
                                    ? AppColors.male
                                    : AppColors.female,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.puppy.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${widget.puppy.gender == "Male" ? "Hannvalp" : "Tispevalp"} • ${widget.puppy.color}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: context.colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Buyer Selection
              Text(
                'Kjøperinformasjon',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<Buyer>(
                isExpanded: true,
                // ignore: deprecated_member_use
                value: _selectedBuyer,
                decoration: InputDecoration(
                  labelText: 'Velg kjøper',
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.mdAll,
                  ),
                ),
                items: _availableBuyers
                    .map((buyer) => DropdownMenuItem(
                          value: buyer,
                          child: Text(
                            buyer.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (buyer) {
                  setState(() {
                    _selectedBuyer = buyer;
                  });
                },
              ),
              if (_selectedBuyer != null) ...[
                const SizedBox(height: AppSpacing.md),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Navn', _selectedBuyer!.name),
                        if (_selectedBuyer!.email != null)
                          _buildInfoRow('E-post', _selectedBuyer!.email!),
                        if (_selectedBuyer!.phone != null)
                          _buildInfoRow('Telefon', _selectedBuyer!.phone!),
                        if (_selectedBuyer!.address != null)
                          _buildInfoRow('Adresse', _selectedBuyer!.address!),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),

              // Contract Details
              Text(
                'Kontraktdetaljer',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Pris',
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.mdAll,
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _depositController,
                decoration: InputDecoration(
                  labelText: 'Depositum (valgfritt)',
                  hintText: 'Beløp allerede betalt som forskudd',
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.mdAll,
                  ),
                  prefixIcon: const Icon(Icons.savings_outlined),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _contractNumberController,
                decoration: InputDecoration(
                  labelText: 'Kontraktnummer (valgfritt)',
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.mdAll,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _paymentTermsController,
                decoration: InputDecoration(
                  labelText: 'Betalingsbetingelser',
                  hintText: 'F.eks. Full betaling ved opphenesting',
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.mdAll,
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _deliveryLocationController,
                decoration: InputDecoration(
                  labelText: 'Overlevingssted (valgfritt)',
                  hintText: 'F.eks. Oppdretters adresse',
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.mdAll,
                  ),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Standard kontraktvilkår med checkboxes
              Text(
                'Kontraktvilkår',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Velg hvilke vilkår som skal inkluderes i kontrakten',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.colors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              CheckboxListTile(
                title: const Text('Generelt'),
                subtitle: const Text('Grunnleggende kjøps- og salgsvilkår'),
                value: _termGeneral,
                onChanged: (value) => setState(() => _termGeneral = value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: const Text('Helse'),
                subtitle: const Text('Garanti om frisk valp og veterinærkontroll'),
                value: _termHealth,
                onChanged: (value) => setState(() => _termHealth = value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: const Text('Vaksinasjoner og behandlinger'),
                subtitle: const Text('Vaksinert og avmasket iht. retningslinjer'),
                value: _termVaccination,
                onChanged: (value) => setState(() => _termVaccination = value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: const Text('Tilbakelevering'),
                subtitle: const Text('Selger kontaktes først ved omplassering'),
                value: _termReturn,
                onChanged: (value) => setState(() => _termReturn = value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: const Text('Ansvar'),
                subtitle: const Text('Kjøper overtar ansvar fra overlevering'),
                value: _termResponsibility,
                onChanged: (value) => setState(() => _termResponsibility = value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: const Text('Registrering'),
                subtitle: const Text('Valpen registreres på ny eier'),
                value: _termRegistration,
                onChanged: (value) => setState(() => _termRegistration = value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Tilleggsvilkår
              Text(
                'Tilleggsvilkår',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              CheckboxListTile(
                title: const Text('Kastrering/sterilisering påkrevd'),
                value: _spayNeuterRequired,
                onChanged: (value) {
                  setState(() {
                    _spayNeuterRequired = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: const Text('Returklausul inkludert'),
                value: _returnClauseIncluded,
                onChanged: (value) {
                  setState(() {
                    _returnClauseIncluded = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Dokumentasjon
              Text(
                'Dokumentasjon',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              CheckboxListTile(
                title: const Text('Stamtavle leveres'),
                subtitle: const Text('Stamtavle følger med ved overlevering'),
                value: _pedigreeDelivered,
                onChanged: (value) {
                  setState(() {
                    _pedigreeDelivered = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: const Text('Helseattest vedlagt'),
                subtitle: const Text('Veterinærattest på helsestatus'),
                value: _vetCertificateAttached,
                onChanged: (value) {
                  setState(() {
                    _vetCertificateAttached = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: const Text('Forsikring overføres'),
                subtitle: const Text('Valpens forsikring overføres til kjøper'),
                value: _insuranceTransferred,
                onChanged: (value) {
                  setState(() {
                    _insuranceTransferred = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Special Terms
              TextFormField(
                controller: _specialTermsController,
                decoration: InputDecoration(
                  labelText: 'Spesielle vilkår (valgfritt)',
                  hintText: 'Eventuelle spesielle avtaler mellom partene...',
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.mdAll,
                  ),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Additional Notes
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notater (valgfritt)',
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.mdAll,
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveContract,
                  icon: const Icon(Icons.save),
                  label: const Text('Lagre kontrakt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: context.colors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Export PDF Button (only if contract is already saved)
              if (_contract.key != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _exportContractPDF(),
                    icon: const Icon(Icons.file_download),
                    label: const Text('Last ned som PDF'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.colors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportContractPDF() async {
    try {
      if (_selectedBuyer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Velg kjøper før eksport')),
        );
        return;
      }

      final pdf = await PDFGenerator.generateContractPDF(
        _contract,
        widget.puppy,
        _selectedBuyer!,
      );

      late Directory directory;
      try {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
        }
      } catch (e) {
        directory = await getApplicationDocumentsDirectory();
      }

      final fileName = 'kontrakt_${widget.puppy.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      await NotificationService().showDownloadNotification(
        title: 'PDF nedlastet',
        fileName: 'kontrakt_${widget.puppy.name}.pdf',
        filePath: file.path,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF lagret:\n${file.path}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Feil ved eksport: $e')),
        );
      }
    }
  }
}
