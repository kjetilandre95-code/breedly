import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:breedly/models/dog.dart';
import 'package:breedly/models/kennel_profile.dart';
import 'package:breedly/screens/kennel_profile_screen.dart';
import 'package:breedly/utils/dog_breeds.dart';
import 'package:intl/intl.dart';
import 'package:breedly/utils/app_bar_builder.dart';
import 'package:breedly/utils/form_validators.dart';
import 'package:breedly/services/auth_service.dart';
import 'package:breedly/services/cloud_sync_service.dart';
import 'package:breedly/services/offline_mode_manager.dart';
import 'package:breedly/utils/logger.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';
import 'package:breedly/widgets/pedigree_scanner_widget.dart';
import 'package:breedly/services/pedigree_scanner_service.dart';

class AddDogScreen extends StatefulWidget {
  final Dog? dogToEdit;
  
  const AddDogScreen({super.key, this.dogToEdit});

  @override
  State<AddDogScreen> createState() => _AddDogScreenState();
}

class _AddDogScreenState extends State<AddDogScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _breed = '';
  String _color = '';
  DateTime _dateOfBirth = DateTime.now();
  String _gender = 'Male';
  String _registrationNumber = '';
  String _notes = '';
  String? _damId;
  String? _sireId;
  final List<DateTime> _heatCycles = [];
  DateTime? _deathDate;
  bool _isPedigreeOnly = false;

  // TextEditingControllers so scanner data updates the form
  late final TextEditingController _nameCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _regCtrl;
  late final TextEditingController _notesCtrl;
  
  bool get _isEditMode => widget.dogToEdit != null;

  @override
  void initState() {
    super.initState();
    if (widget.dogToEdit != null) {
      final dog = widget.dogToEdit!;
      _name = dog.name;
      _breed = dog.breed;
      _color = dog.color;
      _dateOfBirth = dog.dateOfBirth;
      _gender = dog.gender;
      _registrationNumber = dog.registrationNumber ?? '';
      _notes = dog.notes ?? '';
      _damId = dog.damId;
      _sireId = dog.sireId;
      _heatCycles.addAll(dog.heatCycles);
      _deathDate = dog.deathDate;
      _isPedigreeOnly = dog.isPedigreeOnly;
    }
    _nameCtrl = TextEditingController(text: _name);
    _colorCtrl = TextEditingController(text: _color);
    _regCtrl = TextEditingController(text: _registrationNumber);
    _notesCtrl = TextEditingController(text: _notes);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _colorCtrl.dispose();
    _regCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  // Pedigree scan → auto-create all dogs
  // ──────────────────────────────────────────────

  /// Parse a date string like "25.01.2022" into a DateTime
  DateTime? _parseDateString(String? dateStr) {
    if (dateStr == null) return null;
    try {
      final parts = dateStr.split(RegExp(r'[./\-]'));
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          return DateTime(year > 100 ? year : 2000 + year, month, day);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Create a pedigree-only Dog from scanned data
  Dog _scannedToDog(ScannedDog s, {
    required String defaultBreed,
    String? sireId,
    String? damId,
  }) {
    return Dog(
      id: '${DateTime.now().millisecondsSinceEpoch}_${s.name.hashCode.abs()}',
      name: s.name,
      breed: s.breed ?? defaultBreed,
      color: s.color ?? '',
      dateOfBirth: _parseDateString(s.birthDate) ?? DateTime(2000),
      gender: s.gender ?? (s.position?.contains('mor') == true || s.position?.contains('Mor') == true ? 'Female' : 'Male'),
      registrationNumber: s.registrationNumber,
      sireId: sireId,
      damId: damId,
      isPedigreeOnly: true,
    );
  }

  /// Find an existing dog by registration number or name match
  Dog? _findExistingDog(ScannedDog scanned, Box<Dog> box) {
    // Priority 1: Match by registration number (most reliable)
    if (scanned.registrationNumber != null && scanned.registrationNumber!.isNotEmpty) {
      final regNr = scanned.registrationNumber!.trim().toLowerCase();
      final match = box.values.where(
        (d) => d.registrationNumber != null &&
               d.registrationNumber!.trim().toLowerCase() == regNr,
      );
      if (match.isNotEmpty) return match.first;
    }
    // Priority 2: Match by exact name (case-insensitive)
    final nameLower = scanned.name.trim().toLowerCase();
    if (nameLower.isNotEmpty && nameLower != 'ukjent') {
      final match = box.values.where(
        (d) => d.name.trim().toLowerCase() == nameLower,
      );
      if (match.isNotEmpty) return match.first;
    }
    return null;
  }

  /// Show dialog when a scanned dog matches an existing dog, returns:
  /// - 'update' → update the existing dog with scanned data
  /// - 'use'    → use the existing dog as-is (just link)
  /// - 'new'    → create as new dog anyway
  /// - null     → dialog dismissed (treat as 'use')
  Future<String?> _showDuplicateDialog(
    BuildContext ctx,
    ScannedDog scanned,
    Dog existing,
  ) {
    return showDialog<String>(
      context: ctx,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.people_alt, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Expanded(child: Text('Hunden finnes allerede')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '«${scanned.name}» ser ut til å matche en hund som allerede er lagt til:',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(existing.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    if (existing.registrationNumber != null)
                      Text('Reg.nr: ${existing.registrationNumber}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    Text('Rase: ${existing.breed}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    Text(
                      existing.isPedigreeOnly ? '(Stamtavlehund)' : '(Fullverdig hund)',
                      style: TextStyle(color: Colors.blue[600], fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text('Hva vil du gjøre?', style: TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'new'),
            child: const Text('Opprett ny'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, 'use'),
            child: const Text('Bruk eksisterende'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'update'),
            child: const Text('Oppdater data'),
          ),
        ],
      ),
    );
  }

  /// Update existing dog with newly scanned data (fills in blanks, updates breed/color if missing)
  void _updateDogFromScan(Dog existing, ScannedDog scanned, String defaultBreed, {String? sireId, String? damId}) {
    if (scanned.registrationNumber != null && scanned.registrationNumber!.isNotEmpty) {
      existing.registrationNumber = scanned.registrationNumber;
    }
    if (scanned.breed != null && scanned.breed!.isNotEmpty && existing.breed.isEmpty) {
      existing.breed = scanned.breed!;
    } else if (existing.breed.isEmpty && defaultBreed.isNotEmpty) {
      existing.breed = defaultBreed;
    }
    if (scanned.color != null && scanned.color!.isNotEmpty && existing.color.isEmpty) {
      existing.color = scanned.color!;
    }
    if (scanned.birthDate != null) {
      final parsed = _parseDateString(scanned.birthDate);
      if (parsed != null && existing.dateOfBirth.year == 2000) {
        existing.dateOfBirth = parsed;
      }
    }
    if (sireId != null && existing.sireId == null) existing.sireId = sireId;
    if (damId != null && existing.damId == null) existing.damId = damId;
    existing.save();
  }

  /// Get or create a dog from scan data, checking for duplicates.
  /// Returns the ID of the dog (existing or newly created).
  Future<String> _getOrCreateDog(
    ScannedDog scanned, {
    required Box<Dog> box,
    required String defaultBreed,
    required BuildContext dialogContext,
    String? sireId,
    String? damId,
    bool isPedigreeOnly = true,
  }) async {
    final existing = _findExistingDog(scanned, box);
    if (existing != null) {
      final action = await _showDuplicateDialog(dialogContext, scanned, existing);
      if (action == 'update') {
        _updateDogFromScan(existing, scanned, defaultBreed, sireId: sireId, damId: damId);
        return existing.id;
      } else if (action == 'new') {
        // Fall through to create new
      } else {
        // 'use' or dismissed → link to existing, but still update parent links if missing
        if (sireId != null && existing.sireId == null) {
          existing.sireId = sireId;
          existing.save();
        }
        if (damId != null && existing.damId == null) {
          existing.damId = damId;
          existing.save();
        }
        return existing.id;
      }
    }
    // Create new dog
    final d = isPedigreeOnly
        ? _scannedToDog(scanned, defaultBreed: defaultBreed, sireId: sireId, damId: damId)
        : Dog(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: scanned.name,
            breed: scanned.breed ?? defaultBreed,
            color: scanned.color ?? '',
            dateOfBirth: _parseDateString(scanned.birthDate) ?? DateTime.now(),
            gender: scanned.gender ?? 'Male',
            registrationNumber: scanned.registrationNumber,
            sireId: sireId,
            damId: damId,
            isPedigreeOnly: false,
          );
    await box.put(d.id, d);
    return d.id;
  }

  /// After scan + review, create main dog + all pedigree ancestors and navigate back
  Future<void> _createAllDogsFromScan(
    PedigreeScanResult scanResult,
    ScaffoldMessengerState messenger,
    NavigatorState navigator,
  ) async {
    final box = Hive.box<Dog>('dogs');
    final authService = AuthService();
    final offlineManager = OfflineModeManager();
    final cloudSync = CloudSyncService();
    final scannedDog = scanResult.dog!;
    final defaultBreed = scannedDog.breed ?? '';

    // Build lookup maps by position
    final gpMap = <String, ScannedDog>{};
    for (final gp in scanResult.grandparents) {
      if (gp.position != null) gpMap[gp.position!] = gp;
    }
    final ggpMap = <String, ScannedDog>{};
    for (final ggp in scanResult.greatGrandparents) {
      if (ggp.position != null) ggpMap[ggp.position!] = ggp;
    }

    // 1. Create great-grandparents (no parents of their own from scan)
    final ggpIds = <String, String>{}; // position → id
    for (final entry in ggpMap.entries) {
      if (!mounted) return;
      ggpIds[entry.key] = await _getOrCreateDog(
        entry.value, box: box, defaultBreed: defaultBreed, dialogContext: context,
      );
    }

    // 2. Create grandparents, linked to their great-grandparents
    final gpIds = <String, String>{}; // position → id
    for (final pos in ['Farfar', 'Farmor', 'Morfar', 'Mormor']) {
      if (gpMap.containsKey(pos) && mounted) {
        gpIds[pos] = await _getOrCreateDog(
          gpMap[pos]!, box: box, defaultBreed: defaultBreed, dialogContext: context,
          sireId: ggpIds['${pos}s far'], damId: ggpIds['${pos}s mor'],
        );
      }
    }

    // 3. Create parents, linked to grandparents
    String? sireId, damId;
    for (final parent in scanResult.parents) {
      if (!mounted) return;
      if (parent.position == 'Far') {
        sireId = await _getOrCreateDog(
          parent, box: box, defaultBreed: defaultBreed, dialogContext: context,
          sireId: gpIds['Farfar'], damId: gpIds['Farmor'],
        );
      } else if (parent.position == 'Mor') {
        damId = await _getOrCreateDog(
          parent, box: box, defaultBreed: defaultBreed, dialogContext: context,
          sireId: gpIds['Morfar'], damId: gpIds['Mormor'],
        );
      }
    }

    if (!mounted) return;

    // 4. Create the main dog (not pedigree-only)
    final mainId = await _getOrCreateDog(
      scannedDog, box: box, defaultBreed: defaultBreed, dialogContext: context,
      sireId: sireId, damId: damId, isPedigreeOnly: false,
    );

    // If the main dog was an existing pedigree-only dog, upgrade it
    final mainDog = box.get(mainId);
    if (mainDog != null && mainDog.isPedigreeOnly) {
      mainDog.isPedigreeOnly = false;
      if (sireId != null) mainDog.sireId = sireId;
      if (damId != null) mainDog.damId = damId;
      await mainDog.save();
    }

    // 5. Sync to Firebase if authenticated
    final allIds = <String>{mainId, ...ggpIds.values, ...gpIds.values};
    if (sireId != null) allIds.add(sireId);
    if (damId != null) allIds.add(damId);

    if (authService.isAuthenticated && offlineManager.isOnline) {
      try {
        for (final dog in box.values.where((d) => allIds.contains(d.id))) {
          await cloudSync.saveDog(
            userId: authService.currentUserId!,
            dogId: dog.id,
            dogData: dog.toJson(),
          );
        }
      } catch (e) {
        debugPrint('Feil ved synkronisering til Firebase: $e');
      }
    }

    final totalCreated = 1 + scanResult.parents.length +
        scanResult.grandparents.length + scanResult.greatGrandparents.length;

    messenger.showSnackBar(
      SnackBar(
        content: Text('${scannedDog.name} lagt til med stamtavle ($totalCreated hunder totalt)'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );

    // Navigate back — dog is created, no need for the form
    navigator.pop(true);
  }

  void _saveDog() async {
    if (_formKey.currentState!.validate()) {
      final box = Hive.box<Dog>('dogs');
      final authService = AuthService();
      final offlineManager = OfflineModeManager();
      final cloudSync = CloudSyncService();
      
      if (_isEditMode) {
        // Update existing dog
        final existingDog = widget.dogToEdit!;
        existingDog.name = _name;
        existingDog.breed = _breed;
        existingDog.color = _color;
        existingDog.dateOfBirth = _dateOfBirth;
        existingDog.gender = _gender;
        existingDog.registrationNumber = _registrationNumber.isEmpty ? null : _registrationNumber;
        existingDog.notes = _notes.isEmpty ? null : _notes;
        existingDog.damId = _damId;
        existingDog.sireId = _sireId;
        existingDog.heatCycles = _heatCycles;
        existingDog.deathDate = _deathDate;
        existingDog.isPedigreeOnly = _isPedigreeOnly;
        
        await existingDog.save();
        
        // Update in Firebase if authenticated and online
        if (authService.isAuthenticated && offlineManager.isOnline) {
          try {
            await cloudSync.saveDog(
              userId: authService.currentUserId!,
              dogId: existingDog.id,
              dogData: existingDog.toJson(),
            );
          } catch (e) {
            AppLogger.debug('Feil ved oppdatering til Firebase: $e');
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hund oppdatert')),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Create new dog
        final dog = Dog(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _name,
          breed: _breed,
          color: _color,
          dateOfBirth: _dateOfBirth,
          gender: _gender,
          registrationNumber: _registrationNumber.isEmpty ? null : _registrationNumber,
          notes: _notes.isEmpty ? null : _notes,
          damId: _damId,
          sireId: _sireId,
          heatCycles: _heatCycles,
          deathDate: _deathDate,
          isPedigreeOnly: _isPedigreeOnly,
        );

        await box.put(dog.id, dog);

        // Save to Firebase if user is authenticated and online
        if (authService.isAuthenticated && offlineManager.isOnline) {
          try {
            await cloudSync.saveDog(
              userId: authService.currentUserId!,
              dogId: dog.id,
              dogData: dog.toJson(),
            );
          } catch (e) {
            AppLogger.debug('Feil ved lagring til Firebase: $e');
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hund lagt til')),
          );

          Navigator.pop(context, true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarBuilder.buildAppBar(
        title: _isEditMode ? 'Rediger hund' : 'Legg til ny hund',
        context: context,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
            // Pedigree Scanner - Show only when adding new dog
            if (!_isEditMode) ...[
              PedigreeScannerWidget(
                onScanComplete: (result) async {
                  // Get references before async gap
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  
                  // Show review screen - returns updated PedigreeScanResult or null
                  final editedResult = await Navigator.push<PedigreeScanResult?>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PedigreeScanReviewScreen(
                        scanResult: result,
                      ),
                    ),
                  );
                  
                  if (editedResult != null && editedResult.dog != null && mounted) {
                    await _createAllDogsFromScan(editedResult, messenger, navigator);
                  }
                },
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
            ],
            
            // Name
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Navn',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (value) => _name = value,
              validator: (value) => FormValidators.required(value, fieldName: 'Navn'),
            ),
            const SizedBox(height: 16),

            // Breed
            _buildSearchableBreedDropdown(),
            const SizedBox(height: 16),

            // Color
            TextFormField(
              controller: _colorCtrl,
              decoration: InputDecoration(
                labelText: 'Farge',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (value) => _color = value,
              validator: (value) => FormValidators.required(value, fieldName: 'Farge'),
            ),
            const SizedBox(height: 16),

            // Gender
            DropdownButtonFormField<String>(
              key: ValueKey('gender_$_gender'),
              initialValue: _gender,
              items: const [
                DropdownMenuItem(value: 'Male', child: Text('Hann')),
                DropdownMenuItem(value: 'Female', child: Text('Tispe')),
              ],
              onChanged: (value) {
                setState(() => _gender = value ?? 'Male');
              },
              decoration: InputDecoration(
                labelText: 'Kjønn',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            // Date of Birth
            ListTile(
              title: const Text('Fødselsdato'),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(_dateOfBirth)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dateOfBirth,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _dateOfBirth = picked);
                }
              },
            ),
            const SizedBox(height: 16),

            // Death Date (optional)
            ListTile(
              title: const Text('Dødsdato (valgfritt)'),
              subtitle: Text(
                _deathDate != null 
                    ? DateFormat('yyyy-MM-dd').format(_deathDate!)
                    : 'Ikke angitt',
              ),
              trailing: _deathDate != null 
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _deathDate = null),
                    )
                  : null,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _deathDate ?? DateTime.now(),
                  firstDate: _dateOfBirth,
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _deathDate = picked);
                }
              },
            ),
            const SizedBox(height: 16),

            // Pedigree Only Checkbox
            CheckboxListTile(
              title: const Text('Kun stamtavle'),
              subtitle: const Text('Hunden vises kun i stamtavler, ikke i hovedlisten'),
              value: _isPedigreeOnly,
              onChanged: (value) {
                setState(() => _isPedigreeOnly = value ?? false);
              },
            ),
            const SizedBox(height: 16),

            // Mother (Dam)
            _buildParentDropdown(
              label: 'Mor (Tispe) - Valgfritt',
              selectedId: _damId,
              onChanged: (value) => setState(() => _damId = value),
              requiredGender: 'Female',
            ),
            const SizedBox(height: 16),

            // Father (Sire)
            _buildParentDropdown(
              label: 'Far (Hannhund) - Valgfritt',
              selectedId: _sireId,
              onChanged: (value) => setState(() => _sireId = value),
              requiredGender: 'Male',
            ),
            const SizedBox(height: 16),

            // Heat Cycles - Only for females
            if (_gender == 'Female')
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Løpetidssykler',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_heatCycles.isEmpty)
                        Text(
                          'Ingen løpetidsdatoer registrert',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _heatCycles.asMap().entries.map((entry) {
                            final index = entry.key;
                            final date = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('dd.MM.yyyy').format(date),
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    onPressed: () {
                                      setState(() => _heatCycles.removeAt(index));
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                _heatCycles.add(picked);
                                _heatCycles.sort((a, b) => b.compareTo(a));
                              });
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Legg til løpetidsdato'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Registration Number
            TextFormField(
              controller: _regCtrl,
              decoration: InputDecoration(
                labelText: 'Registreringsnummer (valgfritt)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (value) => _registrationNumber = value,
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                labelText: 'Notater (valgfritt)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              maxLines: 3,
              onChanged: (value) => _notes = value,
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _saveDog,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_isEditMode ? 'Oppdater hund' : 'Lagre hund'),
            ),
          ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(Theme.of(context).primaryColor),
    );
  }

  Widget _buildSearchableBreedDropdown() {
    return GestureDetector(
      onTap: () => _showBreedSearchDialog(),
      child: FormField<String>(
        initialValue: _breed,
        validator: (value) => FormValidators.selectionRequired(value, fieldName: 'rase'),
        builder: (FormFieldState<String> field) {
          return InputDecorator(
            decoration: InputDecoration(
              labelText: 'Rase',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              errorText: field.errorText,
              suffixIcon: const Icon(Icons.arrow_drop_down),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            child: Text(
              _breed.isEmpty ? 'Velg rase' : _breed,
              style: TextStyle(
                color: _breed.isEmpty ? Colors.grey : Colors.black,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showBreedSearchDialog() {
    // Get breeds from kennel profile if available
    final kennelBox = Hive.box<KennelProfile>('kennel_profile');
    List<String> kennelBreeds = [];
    
    if (kennelBox.isNotEmpty) {
      final profile = kennelBox.values.first;
      if (profile.breeds.isNotEmpty) {
        kennelBreeds = profile.breeds;
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => BreedSearchDialog(
        kennelBreeds: kennelBreeds,
        allBreeds: dogBreeds,
        selectedBreed: _breed,
        onBreedSelected: (breed) {
          setState(() => _breed = breed);
          Navigator.pop(context);
        },
        onNavigateToKennelProfile: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const KennelProfileScreen(),
            ),
          ).then((_) => setState(() {}));
        },
      ),
    );
  }

  Widget _buildParentDropdown({
    required String label,
    required String? selectedId,
    required Function(String?) onChanged,
    required String requiredGender,
  }) {
    final dogBox = Hive.box<Dog>('dogs');
    final availableDogs = dogBox.values
        .where((dog) => dog.gender == requiredGender)
        .toList();

    return DropdownButtonFormField<String?>(
      key: ValueKey('parent_${label}_$selectedId'),
      initialValue: selectedId,
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Ingen valgt'),
        ),
        ...availableDogs.map((dog) {
          return DropdownMenuItem<String?>(
            value: dog.id,
            child: Text(dog.name),
          );
        }),
      ],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildBottomNavigationBar(Color primaryColor) {
    final l10n = AppLocalizations.of(context);
    return BottomNavigationBar(
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard_rounded),
          label: l10n?.overview ?? 'Oversikt',
        ),
        BottomNavigationBarItem(
          icon: const FaIcon(FontAwesomeIcons.dog),
          label: l10n?.dogs ?? 'Hunder',
        ),
        BottomNavigationBarItem(
          icon: const FaIcon(FontAwesomeIcons.paw),
          label: l10n?.litters ?? 'Kull',
        ),
        BottomNavigationBarItem(
          icon: const FaIcon(FontAwesomeIcons.coins),
          label: l10n?.finance ?? 'Økonomi',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.people_alt_rounded),
          label: l10n?.buyers ?? 'Kjøpere',
        ),
      ],
      currentIndex: 0,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );
  }
}

class BreedSearchDialog extends StatefulWidget {
  final List<String> kennelBreeds;
  final List<String> allBreeds;
  final String selectedBreed;
  final Function(String) onBreedSelected;
  final VoidCallback onNavigateToKennelProfile;

  const BreedSearchDialog({
    super.key,
    required this.kennelBreeds,
    required this.allBreeds,
    required this.selectedBreed,
    required this.onBreedSelected,
    required this.onNavigateToKennelProfile,
  });

  @override
  State<BreedSearchDialog> createState() => _BreedSearchDialogState();
}

class _BreedSearchDialogState extends State<BreedSearchDialog> {
  late TextEditingController _searchController;
  late List<String> _filteredBreeds;
  bool _showAllBreeds = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _showAllBreeds = widget.kennelBreeds.isEmpty;
    _filteredBreeds = _showAllBreeds ? widget.allBreeds : widget.kennelBreeds;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _currentBreedList => _showAllBreeds ? widget.allBreeds : widget.kennelBreeds;

  void _filterBreeds(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBreeds = _currentBreedList;
      } else {
        _filteredBreeds = _currentBreedList
            .where((breed) =>
                breed.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _toggleShowAllBreeds() {
    setState(() {
      _showAllBreeds = !_showAllBreeds;
      _filterBreeds(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasKennelBreeds = widget.kennelBreeds.isNotEmpty;
    
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Velg rase'),
          if (hasKennelBreeds)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _showAllBreeds ? 'Viser alle raser' : 'Viser kennelens raser',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!hasKennelBreeds)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tips: Sett opp dine raser',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Legg til raser i kennelprofilen for raskere valg.',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: widget.onNavigateToKennelProfile,
                            child: Text(
                              'Gå til kennelprofil',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            TextField(
              controller: _searchController,
              onChanged: _filterBreeds,
              decoration: InputDecoration(
                hintText: 'Søk rase...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (hasKennelBreeds)
              InkWell(
                onTap: _toggleShowAllBreeds,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        _showAllBreeds ? Icons.filter_list_off : Icons.filter_list,
                        size: 18,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _showAllBreeds ? 'Vis kun kennelens raser' : 'Vis alle raser',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _filteredBreeds.isEmpty
                  ? Center(
                      child: Text(
                        'Ingen raser funnet for "${_searchController.text}"',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredBreeds.length,
                      itemBuilder: (context, index) {
                        final breed = _filteredBreeds[index];
                        return ListTile(
                          title: Text(breed),
                          selected: breed == widget.selectedBreed,
                          onTap: () {
                            widget.onBreedSelected(breed);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Avbryt'),
        ),
      ],
    );
  }
}
