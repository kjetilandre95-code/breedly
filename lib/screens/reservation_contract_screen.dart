import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/buyer.dart';
import '../models/dog.dart';
import '../models/kennel.dart';
import '../models/litter.dart';
import '../models/puppy.dart';
import '../models/reservation_contract.dart';
import '../services/pdf_contract_service.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';

class ReservationContractScreen extends StatefulWidget {
  final Puppy? preselectedPuppy;
  final Buyer? preselectedBuyer;
  final ReservationContract? existingContract;
  
  const ReservationContractScreen({
    super.key, 
    this.preselectedPuppy,
    this.preselectedBuyer,
    this.existingContract,
  });

  @override
  State<ReservationContractScreen> createState() => _ReservationContractScreenState();
}

class _ReservationContractScreenState extends State<ReservationContractScreen> {
  final _formKey = GlobalKey<FormState>();
  
  Puppy? _selectedPuppy;
  Buyer? _selectedBuyer;
  final _reservationFeeController = TextEditingController();
  final _totalPriceController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isLoading = false;
  List<Puppy> _allPuppies = [];
  List<Buyer> _allBuyers = [];
  Map<String, Dog> _dogsMap = {};
  Map<String, Litter> _littersMap = {};
  Kennel? _kennel;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Default values or existing contract values
    if (widget.existingContract != null) {
      _reservationFeeController.text = widget.existingContract!.reservationFee.toString();
      _totalPriceController.text = widget.existingContract!.totalPrice.toString();
      _notesController.text = widget.existingContract!.notes ?? '';
    } else {
      _reservationFeeController.text = '2000';
      _totalPriceController.text = '20000';
    }
  }

  Future<void> _loadData() async {
    final puppiesBox = Hive.box<Puppy>('puppies');
    final buyersBox = Hive.box<Buyer>('buyers');
    final dogsBox = Hive.box<Dog>('dogs');
    final littersBox = Hive.box<Litter>('litters');
    final kennelBox = Hive.box<Kennel>('kennel');
    
    setState(() {
      _allPuppies = puppiesBox.values.toList();
      _allBuyers = buyersBox.values.toList();
      _dogsMap = {for (var dog in dogsBox.values) dog.id: dog};
      _littersMap = {for (var litter in littersBox.values) litter.id: litter};
      _kennel = kennelBox.isNotEmpty ? kennelBox.getAt(0) : null;
      
      // Load from existing contract if editing
      if (widget.existingContract != null) {
        _selectedPuppy = _allPuppies.where((p) => p.id == widget.existingContract!.puppyId).firstOrNull;
        _selectedBuyer = _allBuyers.where((b) => b.id == widget.existingContract!.buyerId).firstOrNull;
      } else {
        if (widget.preselectedPuppy != null) {
          _selectedPuppy = widget.preselectedPuppy;
        }
        if (widget.preselectedBuyer != null) {
          _selectedBuyer = widget.preselectedBuyer;
        }
      }
    });
  }

  Dog? _getMotherForPuppy(Puppy puppy) {
    final litter = _littersMap[puppy.litterId];
    if (litter != null) {
      return _dogsMap[litter.damId];
    }
    return null;
  }

  Dog? _getFatherForPuppy(Puppy puppy) {
    final litter = _littersMap[puppy.litterId];
    if (litter != null) {
      return _dogsMap[litter.sireId];
    }
    return null;
  }

  @override
  void dispose() {
    _reservationFeeController.dispose();
    _totalPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _generatePdf() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    if (_selectedPuppy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectPuppy)),
      );
      return;
    }
    if (_selectedBuyer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectBuyer)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Use existing contract ID if editing, otherwise generate new one
      final contractId = widget.existingContract?.id ?? const Uuid().v4();
      final isEditing = widget.existingContract != null;
      
      final contract = ReservationContract(
        id: contractId,
        puppyId: _selectedPuppy!.id,
        buyerId: _selectedBuyer!.id,
        reservationFee: double.tryParse(_reservationFeeController.text) ?? 0,
        totalPrice: double.tryParse(_totalPriceController.text) ?? 0,
        notes: _notesController.text.isNotEmpty
            ? _notesController.text
            : null,
        contractDate: widget.existingContract?.contractDate ?? DateTime.now(),
        status: widget.existingContract?.status ?? 'Active',
        dateAdded: widget.existingContract?.dateAdded ?? DateTime.now(),
      );

      final contractsBox = Hive.box<ReservationContract>('reservation_contracts');
      await contractsBox.put(contractId, contract);

      // Sync to cloud
      final userId = AuthService().currentUser?.uid;
      if (userId != null) {
        await CloudSyncService().saveReservationContract(
          userId: userId,
          contractId: contractId,
          contractData: contract.toJson(),
        );
      }

      final pdfService = PdfContractService();
      final file = await pdfService.generateReservationContractPdf(
        buyer: _selectedBuyer!,
        puppy: _selectedPuppy!,
        reservationFee: double.tryParse(_reservationFeeController.text) ?? 0,
        totalPrice: double.tryParse(_totalPriceController.text) ?? 0,
        mother: _getMotherForPuppy(_selectedPuppy!),
        father: _getFatherForPuppy(_selectedPuppy!),
        kennel: _kennel,
        notes: _notesController.text.isNotEmpty
            ? _notesController.text
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? l10n.reservationContractUpdated : l10n.reservationContractCreated)),
        );
        
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: '${l10n.reservationContract} - ${_selectedPuppy!.name}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.genericError(e.toString()))),
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reservationContract),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Puppy selection
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.puppy,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            DropdownButtonFormField<Puppy>(
                              isExpanded: true,
                              initialValue: _selectedPuppy,
                              decoration: InputDecoration(
                                labelText: l10n.selectPuppy,
                                border: const OutlineInputBorder(),
                              ),
                              items: _allPuppies.map((puppy) {
                                final mother = _getMotherForPuppy(puppy);
                                return DropdownMenuItem(
                                  value: puppy,
                                  child: Text(
                                    '${puppy.name}${mother != null ? ' (fra ${mother.name})' : ''}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (puppy) {
                                setState(() => _selectedPuppy = puppy);
                              },
                              validator: (value) =>
                                  value == null ? l10n.required : null,
                            ),
                            if (_selectedPuppy != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                '${l10n.gender}: ${_selectedPuppy!.gender == 'male' ? l10n.maleDog : l10n.female}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (_selectedPuppy!.color.isNotEmpty)
                                Text(
                                  '${l10n.color}: ${_selectedPuppy!.color}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Buyer selection
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.buyer,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            DropdownButtonFormField<Buyer>(
                              isExpanded: true,
                              initialValue: _selectedBuyer,
                              decoration: InputDecoration(
                                labelText: l10n.selectBuyer,
                                border: const OutlineInputBorder(),
                              ),
                              items: _allBuyers.map((buyer) {
                                return DropdownMenuItem(
                                  value: buyer,
                                  child: Text(
                                    buyer.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (buyer) {
                                setState(() => _selectedBuyer = buyer);
                              },
                              validator: (value) =>
                                  value == null ? l10n.required : null,
                            ),
                            if (_selectedBuyer != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                '${l10n.address}: ${_selectedBuyer!.address}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (_selectedBuyer!.phone != null)
                                Text(
                                  '${l10n.phone}: ${_selectedBuyer!.phone}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              if (_selectedBuyer!.email != null)
                                Text(
                                  '${l10n.email}: ${_selectedBuyer!.email}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Price info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.prices,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              controller: _reservationFeeController,
                              decoration: InputDecoration(
                                labelText: l10n.reservationFeeLabel,
                                border: const OutlineInputBorder(),
                                prefixText: 'kr ',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty ?? true) return l10n.required;
                                if (double.tryParse(value!) == null) {
                                  return l10n.invalidAmount;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _totalPriceController,
                              decoration: InputDecoration(
                                labelText: l10n.totalPriceForPuppy,
                                border: const OutlineInputBorder(),
                                prefixText: 'kr ',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty ?? true) return l10n.required;
                                if (double.tryParse(value!) == null) {
                                  return l10n.invalidAmount;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              l10n.remainingAmount(((double.tryParse(_totalPriceController.text) ?? 0) - (double.tryParse(_reservationFeeController.text) ?? 0)).toStringAsFixed(0)),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Notes
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.remarks,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              controller: _notesController,
                              decoration: InputDecoration(
                                labelText: l10n.remarksOptional,
                                hintText: l10n.remarksHint,
                                border: const OutlineInputBorder(),
                              ),
                              maxLines: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Generate button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _generatePdf,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: Text(l10n.generateReservationContract),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
    );
  }
}
