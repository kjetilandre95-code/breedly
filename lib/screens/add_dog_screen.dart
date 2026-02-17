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
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/utils/theme_colors.dart';

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
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
        title: Row(
          children: [
            Icon(Icons.people_alt, color: AppColors.warning),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(l10n.dogAlreadyExists)),
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
              SizedBox(height: AppSpacing.md),
              Container(
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.colors.neutral100,
                  borderRadius: AppRadius.smAll,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(existing.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    if (existing.registrationNumber != null)
                      Text('${l10n.regNo}: ${existing.registrationNumber}', style: TextStyle(color: context.colors.textMuted, fontSize: 13)),
                    Text('${l10n.breed}: ${existing.breed}', style: TextStyle(color: context.colors.textMuted, fontSize: 13)),
                    Text(
                      existing.isPedigreeOnly ? '(Stamtavlehund)' : '(Fullverdig hund)',
                      style: TextStyle(color: AppColors.info, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Text(l10n.whatDoYouWantToDo, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'new'),
            child: Text(l10n.createNew),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, 'use'),
            child: Text(l10n.useExisting),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'update'),
            child: Text(l10n.updateData),
          ),
        ],
      );
      },
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
    final l10n = AppLocalizations.of(context)!;
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
    final gggpMap = <String, ScannedDog>{};
    for (final gggp in scanResult.greatGreatGrandparents) {
      if (gggp.position != null) gggpMap[gggp.position!] = gggp;
    }

    // 1. Create great-great-grandparents (no parents of their own from scan)
    final gggpIds = <String, String>{}; // position → id
    for (final entry in gggpMap.entries) {
      if (!mounted) return;
      gggpIds[entry.key] = await _getOrCreateDog(
        entry.value, box: box, defaultBreed: defaultBreed, dialogContext: context,
      );
    }

    // 2. Create great-grandparents, linked to their great-great-grandparents
    final ggpIds = <String, String>{}; // position → id
    for (final pos in ['Farfars far', 'Farfars mor', 'Farmors far', 'Farmors mor',
                        'Morfars far', 'Morfars mor', 'Mormors far', 'Mormors mor']) {
      if (ggpMap.containsKey(pos) && mounted) {
        ggpIds[pos] = await _getOrCreateDog(
          ggpMap[pos]!, box: box, defaultBreed: defaultBreed, dialogContext: context,
          sireId: gggpIds['${pos}s far'], damId: gggpIds['${pos}s mor'],
        );
      }
    }

    // 3. Create grandparents, linked to their great-grandparents
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
    final allIds = <String>{mainId, ...gggpIds.values, ...ggpIds.values, ...gpIds.values};
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
        scanResult.grandparents.length + scanResult.greatGrandparents.length +
        scanResult.greatGreatGrandparents.length;

    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.dogAddedWithPedigree(scannedDog.name, totalCreated)),
        // ignore: use_build_context_synchronously
        backgroundColor: Theme.of(context).primaryColor,
        duration: const Duration(seconds: 4),
      ),
    );

    // Navigate back — dog is created, no need for the form
    navigator.pop(true);
  }

  void _saveDog() async {
    final l10n = AppLocalizations.of(context)!;
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
            SnackBar(content: Text(l10n.dogUpdated)),
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
            SnackBar(content: Text(l10n.dogAdded)),
          );

          Navigator.pop(context, true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBarBuilder.buildAppBar(
        title: _isEditMode ? 'Rediger hund' : 'Legg til ny hund',
        context: context,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
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
              SizedBox(height: AppSpacing.xxl),
              const Divider(),
              SizedBox(height: AppSpacing.lg),
            ],
            
            // Name
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.name,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.mdAll,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.mdAll,
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
              ),
              onChanged: (value) => _name = value,
              validator: (value) => FormValidators.required(value, fieldName: 'Navn'),
            ),
            SizedBox(height: AppSpacing.lg),

            // Breed
            _buildSearchableBreedDropdown(),
            SizedBox(height: AppSpacing.lg),

            // Color
            TextFormField(
              controller: _colorCtrl,
              decoration: InputDecoration(
                labelText: l10n.color,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.mdAll,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.mdAll,
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
              ),
              onChanged: (value) => _color = value,
              validator: (value) => FormValidators.required(value, fieldName: 'Farge'),
            ),
            SizedBox(height: AppSpacing.lg),

            // Gender
            DropdownButtonFormField<String>(
              key: ValueKey('gender_$_gender'),
              initialValue: _gender,
              items: [
                DropdownMenuItem(value: 'Male', child: Text(l10n.male)),
                DropdownMenuItem(value: 'Female', child: Text(l10n.female)),
              ],
              onChanged: (value) {
                setState(() => _gender = value ?? 'Male');
              },
              decoration: InputDecoration(
                labelText: l10n.gender,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.mdAll,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.mdAll,
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
              ),
            ),
            SizedBox(height: AppSpacing.lg),

            // Date of Birth
            ListTile(
              title: Text(l10n.dateOfBirth),
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
            SizedBox(height: AppSpacing.lg),

            // Death Date (optional)
            ListTile(
              title: Text(l10n.dateOfDeathOptional),
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
            SizedBox(height: AppSpacing.lg),

            // Pedigree Only Checkbox
            CheckboxListTile(
              title: Text(l10n.pedigreeOnly),
              subtitle: Text(l10n.pedigreeOnlyDescription),
              value: _isPedigreeOnly,
              onChanged: (value) {
                setState(() => _isPedigreeOnly = value ?? false);
              },
            ),
            SizedBox(height: AppSpacing.lg),

            // Mother (Dam)
            _buildParentDropdown(
              label: 'Mor (Tispe) - Valgfritt',
              selectedId: _damId,
              onChanged: (value) => setState(() => _damId = value),
              requiredGender: 'Female',
            ),
            SizedBox(height: AppSpacing.lg),

            // Father (Sire)
            _buildParentDropdown(
              label: 'Far (Hannhund) - Valgfritt',
              selectedId: _sireId,
              onChanged: (value) => setState(() => _sireId = value),
              requiredGender: 'Male',
            ),
            SizedBox(height: AppSpacing.lg),

            // Heat Cycles - Only for females
            if (_gender == 'Female')
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdAll,
                ),
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
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
                      SizedBox(height: AppSpacing.md),
                      if (_heatCycles.isEmpty)
                        Text(
                          'Ingen løpetidsdatoer registrert',
                          style: TextStyle(
                            color: context.colors.textMuted,
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
                              padding: EdgeInsets.only(bottom: AppSpacing.sm),
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
                      SizedBox(height: AppSpacing.md),
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
                          label: Text(l10n.addHeatCycle),
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
            SizedBox(height: AppSpacing.lg),

            // Registration Number
            TextFormField(
              controller: _regCtrl,
              decoration: InputDecoration(
                labelText: l10n.registrationNumberOptional,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.mdAll,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.mdAll,
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
              ),
              onChanged: (value) => _registrationNumber = value,
            ),
            SizedBox(height: AppSpacing.lg),

            // Notes
            TextFormField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                labelText: l10n.notesOptional,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.mdAll,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.mdAll,
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
              ),
              maxLines: 3,
              onChanged: (value) => _notes = value,
            ),
            SizedBox(height: AppSpacing.xxl),

            // Save Button
            ElevatedButton(
              onPressed: _saveDog,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
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
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => _showBreedSearchDialog(),
      child: FormField<String>(
        initialValue: _breed,
        validator: (value) => FormValidators.selectionRequired(value, fieldName: 'rase'),
        builder: (FormFieldState<String> field) {
          return InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.breed,
              border: OutlineInputBorder(
                borderRadius: AppRadius.mdAll,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.mdAll,
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              errorText: field.errorText,
              suffixIcon: const Icon(Icons.arrow_drop_down),
              contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
            ),
            child: Text(
              _breed.isEmpty ? l10n.selectBreed : _breed,
              style: TextStyle(
                color: _breed.isEmpty ? context.colors.textDisabled : context.colors.textPrimary,
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
    final l10n = AppLocalizations.of(context)!;
    final dogBox = Hive.box<Dog>('dogs');
    final availableDogs = dogBox.values
        .where((dog) => dog.gender == requiredGender)
        .toList();

    return DropdownButtonFormField<String?>(
      key: ValueKey('parent_${label}_$selectedId'),
      initialValue: selectedId,
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text(l10n.noneSelected),
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
          borderRadius: AppRadius.mdAll,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
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
      unselectedItemColor: context.colors.textDisabled,
      backgroundColor: context.colors.surface,
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
    final l10n = AppLocalizations.of(context)!;
    final hasKennelBreeds = widget.kennelBreeds.isNotEmpty;
    
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.selectBreed),
          if (hasKennelBreeds)
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                _showAllBreeds ? 'Viser alle raser' : 'Viser kennelens raser',
                style: TextStyle(
                  fontSize: 12,
                  color: context.colors.textMuted,
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
                padding: EdgeInsets.all(AppSpacing.md),
                margin: EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: AppRadius.smAll,
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 20),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tips: Sett opp dine raser',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          SizedBox(height: AppSpacing.xxs),
                          const Text(
                            'Legg til raser i kennelprofilen for raskere valg.',
                            style: TextStyle(fontSize: 12),
                          ),
                          SizedBox(height: AppSpacing.xs + AppSpacing.xxs),
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
                hintText: l10n.searchBreed,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.smAll,
                ),
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            if (hasKennelBreeds)
              InkWell(
                onTap: _toggleShowAllBreeds,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Icon(
                        _showAllBreeds ? Icons.filter_list_off : Icons.filter_list,
                        size: 18,
                        color: Theme.of(context).primaryColor,
                      ),
                      SizedBox(width: AppSpacing.sm),
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
            SizedBox(height: AppSpacing.sm),
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
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
