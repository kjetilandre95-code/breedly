import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/dog.dart';
import '../models/kennel.dart';
import '../models/co_ownership_contract.dart';
import '../services/pdf_contract_service.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';

class CoOwnershipContractScreen extends StatefulWidget {
  final Dog? preselectedDog;
  final CoOwnershipContract? existingContract;
  
  const CoOwnershipContractScreen({super.key, this.preselectedDog, this.existingContract});

  @override
  State<CoOwnershipContractScreen> createState() => _CoOwnershipContractScreenState();
}

class _CoOwnershipContractScreenState extends State<CoOwnershipContractScreen> {
  final _formKey = GlobalKey<FormState>();
  
  Dog? _selectedDog;
  final _owner1NameController = TextEditingController();
  final _owner1AddressController = TextEditingController();
  final _owner2NameController = TextEditingController();
  final _owner2AddressController = TextEditingController();
  int _owner1Percentage = 50;
  String _primaryCaretaker = 'Eier 1';
  final _breedingRightsController = TextEditingController();
  final _showRightsController = TextEditingController();
  final _expenseSharingController = TextEditingController();
  final _additionalTermsController = TextEditingController();
  
  bool _isLoading = false;
  List<Dog> _allDogs = [];
  Kennel? _kennel;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Load existing contract values or use defaults
    if (widget.existingContract != null) {
      _loadExistingContract();
    } else {
      // Default values
      _breedingRightsController.text = 'Begge eiere skal godkjenne enhver avlsbruk. Eventuelle valper fordeles etter eierandel.';
      _showRightsController.text = 'Begge eiere har rett til å stille hunden på utstillinger. Resultater og premier deles.';
      _expenseSharingController.text = 'Løpende utgifter som fôr, veterinær og forsikring deles etter eierandel.';
    }
  }

  void _loadExistingContract() {
    final contract = widget.existingContract!;
    _owner1NameController.text = contract.owner1Name;
    _owner1AddressController.text = contract.owner1Address;
    _owner2NameController.text = contract.owner2Name;
    _owner2AddressController.text = contract.owner2Address;
    _owner1Percentage = contract.owner1Percentage;
    _primaryCaretaker = contract.primaryCaretaker;
    _breedingRightsController.text = contract.breedingRights;
    _showRightsController.text = contract.showRights;
    _expenseSharingController.text = contract.expenseSharing;
    _additionalTermsController.text = contract.additionalTerms ?? '';
  }

  Future<void> _loadData() async {
    final dogsBox = Hive.box<Dog>('dogs');
    final kennelBox = Hive.box<Kennel>('kennel');
    
    setState(() {
      _allDogs = dogsBox.values.toList();
      _kennel = kennelBox.isNotEmpty ? kennelBox.getAt(0) : null;
      
      if (widget.existingContract != null) {
        _selectedDog = _allDogs.where((d) => d.id == widget.existingContract!.dogId).firstOrNull;
      } else if (widget.preselectedDog != null) {
        _selectedDog = widget.preselectedDog;
      }
    });
  }

  @override
  void dispose() {
    _owner1NameController.dispose();
    _owner1AddressController.dispose();
    _owner2NameController.dispose();
    _owner2AddressController.dispose();
    _breedingRightsController.dispose();
    _showRightsController.dispose();
    _expenseSharingController.dispose();
    _additionalTermsController.dispose();
    super.dispose();
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
      
      final contract = CoOwnershipContract(
        id: contractId,
        dogId: _selectedDog!.id,
        owner1Name: _owner1NameController.text,
        owner1Address: _owner1AddressController.text,
        owner2Name: _owner2NameController.text,
        owner2Address: _owner2AddressController.text,
        owner1Percentage: _owner1Percentage,
        primaryCaretaker: _primaryCaretaker,
        breedingRights: _breedingRightsController.text,
        showRights: _showRightsController.text,
        expenseSharing: _expenseSharingController.text,
        additionalTerms: _additionalTermsController.text.isNotEmpty
            ? _additionalTermsController.text
            : null,
        contractDate: widget.existingContract?.contractDate ?? DateTime.now(),
        status: widget.existingContract?.status ?? 'Active',
        dateAdded: widget.existingContract?.dateAdded ?? DateTime.now(),
      );

      final contractsBox = Hive.box<CoOwnershipContract>('co_ownership_contracts');
      await contractsBox.put(contractId, contract);

      // Sync to cloud
      final userId = AuthService().currentUser?.uid;
      if (userId != null) {
        await CloudSyncService().saveCoOwnershipContract(
          userId: userId,
          contractId: contractId,
          contractData: contract.toJson(),
        );
      }

      final pdfService = PdfContractService();
      final file = await pdfService.generateCoOwnershipContractPdf(
        dog: _selectedDog!,
        owner1Name: _owner1NameController.text,
        owner1Address: _owner1AddressController.text,
        owner2Name: _owner2NameController.text,
        owner2Address: _owner2AddressController.text,
        owner1Percentage: _owner1Percentage,
        primaryCaretaker: _primaryCaretaker,
        breedingRights: _breedingRightsController.text,
        showRights: _showRightsController.text,
        expenseSharing: _expenseSharingController.text,
        kennel: _kennel,
        additionalTerms: _additionalTermsController.text.isNotEmpty
            ? _additionalTermsController.text
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medeieravtale opprettet!')),
        );
        
        // Show share dialog
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Medeieravtale - ${_selectedDog!.name}',
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
        title: const Text('Medeieravtale'),
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
                              initialValue: _selectedDog,
                              decoration: const InputDecoration(
                                labelText: 'Velg hund',
                                border: OutlineInputBorder(),
                              ),
                              items: _allDogs.map((dog) {
                                return DropdownMenuItem(
                                  value: dog,
                                  child: Text('${dog.name} (${dog.breed})'),
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

                    // Owner 1
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Eier 1',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _owner1NameController,
                              decoration: const InputDecoration(
                                labelText: 'Navn',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Påkrevd' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _owner1AddressController,
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

                    // Owner 2
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Eier 2',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _owner2NameController,
                              decoration: const InputDecoration(
                                labelText: 'Navn',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Påkrevd' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _owner2AddressController,
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

                    // Ownership percentage
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Eierandel',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text('Eier 1: $_owner1Percentage%'),
                                ),
                                Expanded(
                                  child: Text('Eier 2: ${100 - _owner1Percentage}%'),
                                ),
                              ],
                            ),
                            Slider(
                              value: _owner1Percentage.toDouble(),
                              min: 10,
                              max: 90,
                              divisions: 8,
                              label: '$_owner1Percentage%',
                              onChanged: (value) {
                                setState(() => _owner1Percentage = value.round());
                              },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _primaryCaretaker,
                              decoration: const InputDecoration(
                                labelText: 'Hovedomsorgsperson',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Eier 1',
                                  child: Text('Eier 1'),
                                ),
                                DropdownMenuItem(
                                  value: 'Eier 2',
                                  child: Text('Eier 2'),
                                ),
                                DropdownMenuItem(
                                  value: 'Delt',
                                  child: Text('Delt ansvar'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() => _primaryCaretaker = value ?? 'Eier 1');
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Rights and responsibilities
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rettigheter og ansvar',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _breedingRightsController,
                              decoration: const InputDecoration(
                                labelText: 'Avlsrettigheter',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Påkrevd' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _showRightsController,
                              decoration: const InputDecoration(
                                labelText: 'Utstillingsrettigheter',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Påkrevd' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _expenseSharingController,
                              decoration: const InputDecoration(
                                labelText: 'Utgiftsfordeling',
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
                        label: const Text('Generer medeieravtale'),
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
