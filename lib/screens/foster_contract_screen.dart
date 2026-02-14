import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/dog.dart';
import '../models/kennel.dart';
import '../models/foster_contract.dart';
import '../services/pdf_contract_service.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';

class FosterContractScreen extends StatefulWidget {
  final Dog? preselectedDog;
  final FosterContract? existingContract;
  
  const FosterContractScreen({super.key, this.preselectedDog, this.existingContract});

  @override
  State<FosterContractScreen> createState() => _FosterContractScreenState();
}

class _FosterContractScreenState extends State<FosterContractScreen> {
  final _formKey = GlobalKey<FormState>();
  
  Dog? _selectedDog;
  final _ownerNameController = TextEditingController();
  final _ownerAddressController = TextEditingController();
  final _fosterNameController = TextEditingController();
  final _fosterAddressController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _hasEndDate = false;
  final _breedingTermsController = TextEditingController();
  final _expenseTermsController = TextEditingController();
  final _returnConditionsController = TextEditingController();
  final _additionalTermsController = TextEditingController();
  
  bool _isLoading = false;
  List<Dog> _allDogs = [];
  Kennel? _kennel;
  final _dateFormat = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Load existing contract values or use defaults
    if (widget.existingContract != null) {
      _loadExistingContract();
    } else {
      // Default values
      _breedingTermsController.text = 'Hunden skal brukes i avl i henhold til eiers instruksjoner. Alle valper tilhører eier.';
      _expenseTermsController.text = 'Fôrvert dekker daglig fôr, normal veterinærbehandling og generell omsorg. Større veterinærutgifter dekkes av eier.';
      _returnConditionsController.text = 'Hunden skal returneres til eier på forespørsel med minst 14 dagers varsel.';
    }
  }

  void _loadExistingContract() {
    final contract = widget.existingContract!;
    _ownerNameController.text = contract.ownerName;
    _ownerAddressController.text = contract.ownerAddress;
    _fosterNameController.text = contract.fosterName;
    _fosterAddressController.text = contract.fosterAddress;
    _startDate = contract.startDate;
    _endDate = contract.endDate;
    _hasEndDate = contract.endDate != null;
    _breedingTermsController.text = contract.breedingTerms;
    _expenseTermsController.text = contract.expenseTerms;
    _returnConditionsController.text = contract.returnConditions;
    _additionalTermsController.text = contract.additionalTerms ?? '';
  }

  Future<void> _loadData() async {
    final dogsBox = Hive.box<Dog>('dogs');
    final kennelBox = Hive.box<Kennel>('kennel');
    
    setState(() {
      _allDogs = dogsBox.values.where((d) => !d.isPedigreeOnly).toList();
      _kennel = kennelBox.isNotEmpty ? kennelBox.getAt(0) : null;
      
      if (widget.existingContract != null) {
        _selectedDog = _allDogs.where((d) => d.id == widget.existingContract!.dogId).firstOrNull;
      } else if (widget.preselectedDog != null) {
        _selectedDog = widget.preselectedDog;
      }
      
      // Pre-fill owner info from kennel (only if not editing)
      if (_kennel != null && widget.existingContract == null) {
        _ownerNameController.text = _kennel!.name;
        _ownerAddressController.text = _kennel!.address ?? '';
      }
    });
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _ownerAddressController.dispose();
    _fosterNameController.dispose();
    _fosterAddressController.dispose();
    _breedingTermsController.dispose();
    _expenseTermsController.dispose();
    _returnConditionsController.dispose();
    _additionalTermsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate ? _startDate : (_endDate ?? DateTime.now().add(const Duration(days: 365)));
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _generatePdf() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDog == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Velg en hund')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Use existing contract ID if editing, otherwise generate new one
      final contractId = widget.existingContract?.id ?? const Uuid().v4();
      
      final contract = FosterContract(
        id: contractId,
        dogId: _selectedDog!.id,
        ownerName: _ownerNameController.text,
        ownerAddress: _ownerAddressController.text,
        fosterName: _fosterNameController.text,
        fosterAddress: _fosterAddressController.text,
        startDate: _startDate,
        endDate: _hasEndDate ? _endDate : null,
        breedingTerms: _breedingTermsController.text,
        expenseTerms: _expenseTermsController.text,
        returnConditions: _returnConditionsController.text,
        additionalTerms: _additionalTermsController.text.isNotEmpty
            ? _additionalTermsController.text
            : null,
        contractDate: widget.existingContract?.contractDate ?? DateTime.now(),
        status: widget.existingContract?.status ?? 'Active',
        dateAdded: widget.existingContract?.dateAdded ?? DateTime.now(),
      );

      final contractsBox = Hive.box<FosterContract>('foster_contracts');
      await contractsBox.put(contractId, contract);

      // Sync to cloud
      final userId = AuthService().currentUser?.uid;
      if (userId != null) {
        await CloudSyncService().saveFosterContract(
          userId: userId,
          contractId: contractId,
          contractData: contract.toJson(),
        );
      }

      final pdfService = PdfContractService();
      final file = await pdfService.generateFosterContractPdf(
        dog: _selectedDog!,
        ownerName: _ownerNameController.text,
        ownerAddress: _ownerAddressController.text,
        fosterName: _fosterNameController.text,
        fosterAddress: _fosterAddressController.text,
        startDate: _startDate,
        endDate: _hasEndDate ? _endDate : null,
        breedingTerms: _breedingTermsController.text,
        expenseTerms: _expenseTermsController.text,
        returnConditions: _returnConditionsController.text,
        kennel: _kennel,
        additionalTerms: _additionalTermsController.text.isNotEmpty
            ? _additionalTermsController.text
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fôrvertsavtale opprettet!')),
        );
        
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Fôrvertsavtale - ${_selectedDog!.name}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Feil: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fôrvertsavtale'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dog selection
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hund',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<Dog>(
                              isExpanded: true,
                              initialValue: _selectedDog,
                              decoration: const InputDecoration(
                                labelText: 'Velg hund',
                                border: OutlineInputBorder(),
                              ),
                              items: _allDogs.map((dog) {
                                return DropdownMenuItem(
                                  value: dog,
                                  child: Text(
                                    '${dog.name} (${dog.breed})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (dog) {
                                setState(() => _selectedDog = dog);
                              },
                              validator: (value) =>
                                  value == null ? 'Påkrevd' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Owner info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Eier',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _ownerNameController,
                              decoration: const InputDecoration(
                                labelText: 'Navn',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Påkrevd' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _ownerAddressController,
                              decoration: const InputDecoration(
                                labelText: 'Adresse',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Påkrevd' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Foster info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fôrvert',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _fosterNameController,
                              decoration: const InputDecoration(
                                labelText: 'Navn',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Påkrevd' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _fosterAddressController,
                              decoration: const InputDecoration(
                                labelText: 'Adresse',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Påkrevd' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Period
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Avtaleperiode',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.calendar_today),
                              title: const Text('Startdato'),
                              subtitle: Text(_dateFormat.format(_startDate)),
                              onTap: () => _selectDate(context, true),
                            ),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _hasEndDate,
                              onChanged: (value) {
                                setState(() {
                                  _hasEndDate = value ?? false;
                                  if (_hasEndDate && _endDate == null) {
                                    _endDate = _startDate.add(const Duration(days: 365));
                                  }
                                });
                              },
                              title: const Text('Har bestemt sluttdato'),
                            ),
                            if (_hasEndDate)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.calendar_today),
                                title: const Text('Sluttdato'),
                                subtitle: Text(_endDate != null 
                                    ? _dateFormat.format(_endDate!) 
                                    : 'Velg dato'),
                                onTap: () => _selectDate(context, false),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Terms
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vilkår',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _breedingTermsController,
                              decoration: const InputDecoration(
                                labelText: 'Avlsvilkår',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Påkrevd' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _expenseTermsController,
                              decoration: const InputDecoration(
                                labelText: 'Utgiftsfordeling',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Påkrevd' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _returnConditionsController,
                              decoration: const InputDecoration(
                                labelText: 'Returvilkår',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Påkrevd' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Additional terms
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tilleggsvilkår',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _additionalTermsController,
                              decoration: const InputDecoration(
                                labelText: 'Tilleggsvilkår (valgfritt)',
                                hintText: 'Skriv inn eventuelle tilleggsvilkår...',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Generate button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _generatePdf,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Generer fôrvertsavtale'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}
