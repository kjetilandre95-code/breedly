import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:breedly/models/dog.dart';
import 'package:breedly/models/kennel_profile.dart';
import 'package:breedly/models/breeding_contract.dart';
import 'package:breedly/services/pdf_contract_service.dart';
import 'package:breedly/services/auth_service.dart';
import 'package:breedly/services/cloud_sync_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:breedly/utils/app_bar_builder.dart';
import 'package:breedly/utils/notification_service.dart';
import 'package:uuid/uuid.dart';
import 'dart:io' show Directory;
import 'package:path_provider/path_provider.dart';

class BreedingContractScreen extends StatefulWidget {
  final Dog? stud;
  final Dog? preselectedStud;
  final Dog? dam;
  final BreedingContract? existingContract;

  const BreedingContractScreen({
    super.key,
    this.stud,
    this.preselectedStud,
    this.dam,
    this.existingContract,
  });

  @override
  State<BreedingContractScreen> createState() => _BreedingContractScreenState();
}

class _BreedingContractScreenState extends State<BreedingContractScreen> {
  Dog? _selectedStud;
  Dog? _selectedDam;
  
  final _studOwnerNameController = TextEditingController();
  final _studOwnerAddressController = TextEditingController();
  final _damOwnerNameController = TextEditingController();
  final _damOwnerAddressController = TextEditingController();
  final _studFeeController = TextEditingController();
  final _paymentTermsController = TextEditingController();
  final _additionalTermsController = TextEditingController();
  
  List<Dog> _males = [];
  List<Dog> _females = [];
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadDogs();
    
    // Load existing contract values or use preselected values
    if (widget.existingContract != null) {
      _loadExistingContract();
    } else {
      _selectedStud = widget.stud ?? widget.preselectedStud;
      _selectedDam = widget.dam;
      _loadKennelProfile();
    }
  }

  void _loadExistingContract() {
    final contract = widget.existingContract!;
    _selectedStud = _males.where((d) => d.id == contract.studId).firstOrNull;
    _selectedDam = _females.where((d) => d.id == contract.damId).firstOrNull;
    _studOwnerNameController.text = contract.studOwnerName;
    _studOwnerAddressController.text = contract.studOwnerAddress;
    _damOwnerNameController.text = contract.damOwnerName;
    _damOwnerAddressController.text = contract.damOwnerAddress;
    _studFeeController.text = contract.studFee.toString();
    _paymentTermsController.text = contract.paymentTerms ?? '';
    _additionalTermsController.text = contract.additionalTerms ?? '';
  }

  void _loadDogs() {
    final dogBox = Hive.box<Dog>('dogs');
    _males = dogBox.values.where((d) => d.gender == 'Male').toList();
    _females = dogBox.values.where((d) => d.gender == 'Female').toList();
  }

  void _loadKennelProfile() {
    final kennelBox = Hive.box<KennelProfile>('kennel_profile');
    if (kennelBox.isNotEmpty) {
      final profile = kennelBox.values.first;
      _studOwnerNameController.text = profile.kennelName ?? '';
      _studOwnerAddressController.text = profile.address ?? '';
    }
  }

  @override
  void dispose() {
    _studOwnerNameController.dispose();
    _studOwnerAddressController.dispose();
    _damOwnerNameController.dispose();
    _damOwnerAddressController.dispose();
    _studFeeController.dispose();
    _paymentTermsController.dispose();
    _additionalTermsController.dispose();
    super.dispose();
  }

  Future<void> _generateContract() async {
    if (_selectedStud == null || _selectedDam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Velg hannhund og tispe')),
      );
      return;
    }

    if (_studFeeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Angi paringsavgift')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      // Use existing contract ID if editing, otherwise generate new one
      final contractId = widget.existingContract?.id ?? const Uuid().v4();
      
      final contract = BreedingContract(
        id: contractId,
        studId: _selectedStud!.id,
        damId: _selectedDam!.id,
        studOwnerName: _studOwnerNameController.text.trim(),
        studOwnerAddress: _studOwnerAddressController.text.trim(),
        damOwnerName: _damOwnerNameController.text.trim(),
        damOwnerAddress: _damOwnerAddressController.text.trim(),
        studFee: double.tryParse(_studFeeController.text) ?? 0,
        paymentTerms: _paymentTermsController.text.trim().isEmpty 
            ? 'Betales ved paring' 
            : _paymentTermsController.text.trim(),
        additionalTerms: _additionalTermsController.text.trim().isEmpty 
            ? null 
            : _additionalTermsController.text.trim(),
        contractDate: widget.existingContract?.contractDate ?? DateTime.now(),
        status: widget.existingContract?.status ?? 'Active',
        dateAdded: widget.existingContract?.dateAdded ?? DateTime.now(),
      );

      final contractsBox = Hive.box<BreedingContract>('breeding_contracts');
      await contractsBox.put(contractId, contract);

      // Sync to cloud
      final userId = AuthService().currentUser?.uid;
      if (userId != null) {
        await CloudSyncService().saveBreedingContract(
          userId: userId,
          contractId: contractId,
          contractData: contract.toJson(),
        );
      }

      final file = await PdfContractService().generateBreedingContractPdf(
        stud: _selectedStud!,
        dam: _selectedDam!,
        studOwnerName: _studOwnerNameController.text.trim(),
        damOwnerName: _damOwnerNameController.text.trim(),
        studOwnerAddress: _studOwnerAddressController.text.trim(),
        damOwnerAddress: _damOwnerAddressController.text.trim(),
        studFee: double.tryParse(_studFeeController.text) ?? 0,
        paymentTerms: _paymentTermsController.text.trim().isEmpty 
            ? 'Betales ved paring' 
            : _paymentTermsController.text.trim(),
        additionalTerms: _additionalTermsController.text.trim().isEmpty 
            ? null 
            : _additionalTermsController.text.trim(),
      );

      // Copy to downloads
      late Directory directory;
      try {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory() ?? 
                      await getApplicationDocumentsDirectory();
        }
      } catch (e) {
        directory = await getApplicationDocumentsDirectory();
      }

      final newPath = '${directory.path}/${file.path.split('/').last}';
      final savedFile = await file.copy(newPath);

      await NotificationService().showDownloadNotification(
        title: 'Avlskontrakt nedlastet',
        fileName: savedFile.path.split('/').last,
        filePath: savedFile.path,
      );

      if (mounted) {
        _showShareDialog(savedFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Feil ved generering: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _showShareDialog(String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Kontrakt generert!'),
          ],
        ),
        content: const Text(
          'Avlskontrakten er generert og lagret. Vil du dele den?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Lukk'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Share.shareXFiles([XFile(filePath)], subject: 'Avlskontrakt');
            },
            icon: const Icon(Icons.share),
            label: const Text('Del'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarBuilder.buildAppBar(
        title: 'Avlskontrakt',
        context: context,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Fyll ut informasjon om paring og kontraktsvilkår for å generere avlskontrakt.',
                        style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Stud Section
              _buildSectionHeader('Hannhund (far)', Icons.male),
              const SizedBox(height: 8),
              DropdownButtonFormField<Dog>(
                initialValue: _selectedStud,
                decoration: const InputDecoration(
                  labelText: 'Velg hannhund',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pets),
                ),
                items: _males.map((dog) => DropdownMenuItem(
                  value: dog,
                  child: Text(dog.name),
                )).toList(),
                onChanged: (dog) => setState(() => _selectedStud = dog),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _studOwnerNameController,
                decoration: const InputDecoration(
                  labelText: 'Hannhundens eier (navn)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _studOwnerAddressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 24),

              // Dam Section
              _buildSectionHeader('Tispe (mor)', Icons.female),
              const SizedBox(height: 8),
              DropdownButtonFormField<Dog>(
                initialValue: _selectedDam,
                decoration: const InputDecoration(
                  labelText: 'Velg tispe',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pets),
                ),
                items: _females.map((dog) => DropdownMenuItem(
                  value: dog,
                  child: Text(dog.name),
                )).toList(),
                onChanged: (dog) => setState(() => _selectedDam = dog),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _damOwnerNameController,
                decoration: const InputDecoration(
                  labelText: 'Tispens eier (navn)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _damOwnerAddressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 24),

              // Payment Section
              _buildSectionHeader('Paringsavgift', Icons.payments),
              const SizedBox(height: 8),
              TextField(
                controller: _studFeeController,
                decoration: const InputDecoration(
                  labelText: 'Beløp (NOK)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _paymentTermsController,
                decoration: const InputDecoration(
                  labelText: 'Betalingsvilkår',
                  hintText: 'F.eks. "Betales ved paring" eller "50% ved paring, 50% ved fødsel"',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.receipt_long),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Terms Section
              _buildSectionHeader('Tilleggsvilkår', Icons.description),
              const SizedBox(height: 8),
              TextField(
                controller: _additionalTermsController,
                decoration: const InputDecoration(
                  labelText: 'Tilleggsvilkår (valgfritt)',
                  hintText: 'Legg til spesielle vilkår for denne avtalen...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 32),

              // Generate Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateContract,
                  icon: _isGenerating 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.picture_as_pdf),
                  label: Text(_isGenerating ? 'Genererer...' : 'Generer avlskontrakt (PDF)'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
