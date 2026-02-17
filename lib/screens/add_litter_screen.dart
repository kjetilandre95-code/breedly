import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:breedly/models/dog.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/utils/theme_colors.dart';
import 'package:breedly/models/litter.dart';
import 'package:breedly/models/puppy.dart';
import 'package:breedly/models/kennel_profile.dart';
import 'package:breedly/screens/add_dog_screen.dart';
import 'package:breedly/screens/dog_health_screen.dart';
import 'package:breedly/screens/breeding_contract_screen.dart';
import 'package:breedly/screens/kennel_profile_screen.dart';
import 'package:breedly/utils/id_generator.dart';
import 'package:breedly/utils/dog_breeds.dart';
import 'package:breedly/widgets/inbreeding_widget.dart';
import 'package:intl/intl.dart';
import 'package:breedly/utils/app_bar_builder.dart';
import 'package:breedly/services/auth_service.dart';
import 'package:breedly/services/cloud_sync_service.dart';
import 'package:breedly/services/offline_mode_manager.dart';
import 'package:breedly/utils/logger.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';

class AddLitterScreen extends StatefulWidget {
  const AddLitterScreen({super.key});

  @override
  State<AddLitterScreen> createState() => _AddLitterScreenState();
}

class _AddLitterScreenState extends State<AddLitterScreen> {
  final _formKey = GlobalKey<FormState>();
  Dog? _selectedDam;
  Dog? _selectedSire;
  DateTime _dateOfBirth = DateTime.now();
  DateTime? _damMatingDate;
  DateTime? _estimatedDueDate;
  int _numberOfPuppies = 0;
  int _actualMalesCount = 0;
  int _actualFemalesCount = 0;
  String _breed = '';
  String _notes = '';
  
  // Ny: Planleggingsmodus
  bool _isPlannedLitter = false;
  // Ny: Historisk kull (eldre enn 75 dager)
  bool _isHistoricalLitter = false;

  List<Dog> _dogs = [];

  @override
  void initState() {
    super.initState();
    _selectedDam = null;
    _selectedSire = null;
    _loadDogs();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDogs();
  }

  void _loadDogs() {
    final box = Hive.box<Dog>('dogs');
    setState(() {
      _dogs = box.values.where((d) => !d.isPedigreeOnly).toList();
    });
  }

  void _saveLitter() async {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      if (_selectedDam == null || _selectedSire == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pleaseSelectBothParents)),
        );
        return;
      }

      // Validering for kjønn
      if (_selectedDam!.gender != 'Female') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.motherMustBeFemale)),
        );
        return;
      }

      if (_selectedSire!.gender != 'Male') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.fatherMustBeMale)),
        );
        return;
      }

      // Parringsdato er nå valgfri for planlagte kull
      // Brukeren kan opprette planlagt kull uten å vite når parring vil skje

      final litter = Litter(
        id: IdGenerator.generateId(),
        damId: _selectedDam!.id,
        sireId: _selectedSire!.id,
        damName: _selectedDam!.name,
        sireName: _selectedSire!.name,
        dateOfBirth: _isPlannedLitter 
            ? (_estimatedDueDate ?? DateTime(2099, 1, 1)) 
            : _dateOfBirth,
        numberOfPuppies: _numberOfPuppies,
        breed: _breed,
        actualMalesCount: _isPlannedLitter ? 0 : _actualMalesCount,
        actualFemalesCount: _isPlannedLitter ? 0 : _actualFemalesCount,
        notes: _isPlannedLitter 
            ? '${_notes.isNotEmpty ? '$_notes\n' : ''}${l10n.plannedLitterTag}' 
            : _notes,
        damMatingDate: _damMatingDate,
        estimatedDueDate: _estimatedDueDate,
      );

      final litterBox = Hive.box<Litter>('litters');
      await litterBox.put(litter.id, litter);

      // Save to Firebase if user is authenticated and online
      final authService = AuthService();
      final offlineManager = OfflineModeManager();
      
      if (authService.isAuthenticated && offlineManager.isOnline) {
        final cloudSync = CloudSyncService();
        try {
          await cloudSync.saveLitter(
            userId: authService.currentUserId!,
            litterId: litter.id,
            litterData: litter.toJson(),
          );
        } catch (e) {
          AppLogger.debug('Feil ved lagring av kull til Firebase: $e');
        }
      }

      // Auto-generate puppies only if not in planning mode
      if (!_isPlannedLitter) {
        _generatePuppies(litter);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isPlannedLitter 
              ? l10n.plannedLitterCreated 
              : l10n.litterAdded)),
        );

        Navigator.pop(context);
      }
    }
  }

  void _generatePuppies(Litter litter) {
    final l10n = AppLocalizations.of(context)!;
    final puppyBox = Hive.box<Puppy>('puppies');
    
    // Generate male puppies
    for (int i = 0; i < _actualMalesCount; i++) {
      final puppy = Puppy(
        id: IdGenerator.generateId(),
        name: '${litter.damName} x ${litter.sireName} - ${l10n.maleNumberTemplate(i + 1)}',
        litterId: litter.id,
        dateOfBirth: _dateOfBirth,
        gender: 'Male',
        color: '',
        status: 'Available',
        vaccinated: false,
        dewormed: false,
        microchipped: false,
      );
      puppyBox.put(puppy.id, puppy);
    }
    
    // Generate female puppies
    for (int i = 0; i < _actualFemalesCount; i++) {
      final puppy = Puppy(
        id: IdGenerator.generateId(),
        name: '${litter.damName} x ${litter.sireName} - ${l10n.femaleNumberTemplate(i + 1)}',
        litterId: litter.id,
        dateOfBirth: _dateOfBirth,
        gender: 'Female',
        color: '',
        status: 'Available',
        vaccinated: false,
        dewormed: false,
        microchipped: false,
      );
      puppyBox.put(puppy.id, puppy);
    }
  }

  // Automatisk sett rase hvis mor og far har samme rase
  void _autoSetBreedIfSame() {
    if (_selectedDam != null && _selectedSire != null) {
      if (_selectedDam!.breed == _selectedSire!.breed && _selectedDam!.breed.isNotEmpty) {
        setState(() {
          _breed = _selectedDam!.breed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBarBuilder.buildAppBar(
        title: _isPlannedLitter ? l10n.planLitter : 'Legg til nytt kull',
        context: context,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
            // Planleggingsmodus toggle
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.mdAll,
              ),
              color: _isPlannedLitter 
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isPlannedLitter ? Icons.calendar_month : Icons.pets,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            _isPlannedLitter 
                                ? l10n.planningFutureLitter
                                : l10n.registeringBornLitter,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SwitchListTile(
                      title: Text(l10n.planningMode),
                      subtitle: Text(
                        _isPlannedLitter 
                            ? l10n.planningModeDescription
                            : l10n.registeringModeDescription,
                      ),
                      value: _isPlannedLitter,
                      onChanged: (value) {
                        setState(() {
                          _isPlannedLitter = value;
                          if (value) {
                            _isHistoricalLitter = false;
                            // Sett fødselsdato til forventet dato kun hvis parringsdato er satt
                            if (_estimatedDueDate != null) {
                              _dateOfBirth = _estimatedDueDate!;
                            }
                          } else {
                            _dateOfBirth = DateTime.now();
                          }
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (!_isPlannedLitter) ...[
                      const Divider(),
                      SwitchListTile(
                        title: Text(l10n.historicalLitter),
                        subtitle: Text(
                          _isHistoricalLitter 
                              ? l10n.registerPreviousLitter
                              : l10n.registerPreviousLitter,
                        ),
                        value: _isHistoricalLitter,
                        onChanged: (value) {
                          setState(() {
                            _isHistoricalLitter = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        activeTrackColor: context.colors.textMuted.withValues(alpha: 0.5),
                        activeThumbColor: context.colors.textMuted,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Dam Selection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.selectDam}:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_dogs.where((d) => d.gender == 'Female').isEmpty)
                  OutlinedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddDogScreen(),
                        ),
                      );
                      _loadDogs();
                    },
                    child: const Text('+ Legg til'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _dogs.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.error),
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ingen hunder registrert ennå',
                          style: TextStyle(color: AppColors.error),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ElevatedButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddDogScreen(),
                              ),
                            );
                            if (result != null) {
                              _loadDogs();
                            }
                          },
                          child: Text(l10n.addDogsFirst),
                        ),
                      ],
                    ),
                  )
                : DropdownButtonFormField<Dog>(
                    isExpanded: true,
                    initialValue: _selectedDam,
                    items: [
                      ..._dogs
                          .where((dog) => dog.gender == 'Female')
                          .map((dog) => DropdownMenuItem(
                                value: dog,
                                child: Text(
                                  '${dog.name} - ${dog.breed}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                      DropdownMenuItem(
                        value: null,
                        child: Row(
                          children: [
                            const Icon(Icons.add, size: 18),
                            const SizedBox(width: AppSpacing.sm),
                            Text(l10n.addNewFemale),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) async {
                      if (value == null) {
                        // Bruker trykket på "Legg til ny"
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddDogScreen(),
                          ),
                        );
                        _loadDogs();
                      } else {
                        setState(() {
                          _selectedDam = value;
                          _autoSetBreedIfSame();
                        });
                      }
                    },
                    decoration: InputDecoration(
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
                      labelText: l10n.selectDam,
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    ),
                    validator: (value) =>
                        value == null ? l10n.pleaseSelectDam : null,
                  ),
            const SizedBox(height: AppSpacing.lg),

            // Sire Selection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${l10n.selectSire}:', style: Theme.of(context).textTheme.titleMedium),
                if (_dogs.where((d) => d.gender == 'Male').isEmpty)
                  OutlinedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddDogScreen(),
                        ),
                      );
                      _loadDogs();
                    },
                    child: const Text('+ Legg til'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<Dog>(
              isExpanded: true,
              initialValue: _selectedSire,
              items: [
                ..._dogs
                    .where((dog) => dog.gender == 'Male')
                    .map((dog) => DropdownMenuItem(
                          value: dog,
                          child: Text(
                            '${dog.name} - ${dog.breed}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                DropdownMenuItem(
                  value: null,
                  child: Row(
                    children: [
                      const Icon(Icons.add, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l10n.addNewMale),
                    ],
                  ),
                ),
              ],
              onChanged: (value) async {
                if (value == null) {
                  // Bruker trykket på "Legg til ny"
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddDogScreen(),
                    ),
                  );
                  _loadDogs();
                } else {
                  setState(() {
                    _selectedSire = value;
                    _autoSetBreedIfSame();
                  });
                }
              },
              decoration: InputDecoration(
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
                labelText: l10n.selectSire,
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              ),
              validator: (value) => value == null ? l10n.pleaseSelectSire : null,
            ),
            
            // Inbreeding coefficient display
            if (_selectedDam != null && _selectedSire != null) ...[
              const SizedBox(height: AppSpacing.lg),
              InbreedingWidget(
                motherId: _selectedDam!.id,
                fatherId: _selectedSire!.id,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),

            // Breed - Searchable
            _buildSearchableBreedDropdown(),
            const SizedBox(height: AppSpacing.lg),

            // Mating Date - viktig for planlegging
            if (_isPlannedLitter && _damMatingDate == null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  l10n.dateSetWhenMatingCompleted,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.colors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.mdAll,
              ),
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              child: ListTile(
                leading: Icon(
                  Icons.favorite,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  l10n.matingDate,
                ),
                subtitle: _damMatingDate != null
                    ? Text(
                        DateFormat('dd.MM.yyyy').format(_damMatingDate!),
                        style: const TextStyle(fontSize: 16),
                      )
                    : Text(l10n.tapToSelectDate),
                trailing: _damMatingDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: l10n.removeMatingDate,
                        onPressed: () {
                          setState(() {
                            _damMatingDate = null;
                            _estimatedDueDate = null;
                            if (_isPlannedLitter) {
                              _dateOfBirth = DateTime.now().add(const Duration(days: 63));
                            }
                          });
                        },
                      )
                    : const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _damMatingDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: _isPlannedLitter ? DateTime.now().add(const Duration(days: 365)) : DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _damMatingDate = picked;
                      // Automatically calculate estimated due date (63 days from mating)
                      _estimatedDueDate = picked.add(const Duration(days: 63));
                      if (_isPlannedLitter) {
                        _dateOfBirth = _estimatedDueDate!;
                      }
                      // Auto-detect if this is a historical litter (older than 75 days)
                      if (!_isPlannedLitter && _estimatedDueDate!.isBefore(DateTime.now().subtract(const Duration(days: 12)))) {
                        _isHistoricalLitter = true;
                      }
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Estimated Due Date - alltid vis i planleggingsmodus
            if (_estimatedDueDate != null || _isPlannedLitter)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdAll,
                ),
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                child: ListTile(
                  leading: Icon(
                    Icons.event,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    l10n.estimatedDueDate,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: _estimatedDueDate != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('dd.MM.yyyy').format(_estimatedDueDate!),
                              style: const TextStyle(fontSize: 16),
                            ),
                            if (_estimatedDueDate!.isAfter(DateTime.now()))
                              Text(
                                '${_estimatedDueDate!.difference(DateTime.now()).inDays} dager til',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        )
                      : Text(l10n.setMatingDateFirst),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _estimatedDueDate != null ? () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _estimatedDueDate!,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          _estimatedDueDate = picked;
                          if (_isPlannedLitter) {
                            _dateOfBirth = picked;
                          }
                        });
                      }
                    } : null,
                  ),
                ),
              ),
            if (_estimatedDueDate != null || _isPlannedLitter) 
              const SizedBox(height: AppSpacing.lg),

            // Progesteronmålinger-knapp i planleggingsmodus
            if (_isPlannedLitter && _selectedDam != null)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdAll,
                ),
                color: AppColors.accent5.withValues(alpha: 0.15),
                child: ListTile(
                  leading: Icon(
                    Icons.science,
                    color: AppColors.accent5,
                  ),
                  title: Text(
                    l10n.progesteroneMeasurements,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    l10n.progesteroneMeasurementsSubtitle,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DogHealthScreen(dog: _selectedDam!),
                      ),
                    );
                  },
                ),
              ),
            if (_isPlannedLitter && _selectedDam != null) 
              const SizedBox(height: AppSpacing.lg),

            // Opprett parringsavtale - kun i planleggingsmodus med begge foreldre valgt
            if (_isPlannedLitter && _selectedDam != null && _selectedSire != null)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdAll,
                ),
                color: AppColors.accent2.withValues(alpha: 0.15),
                child: ListTile(
                  leading: Icon(
                    Icons.description,
                    color: AppColors.accent2,
                  ),
                  title: Text(
                    l10n.breedingContract,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    l10n.breedingContractSubtitle,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BreedingContractScreen(
                          dam: _selectedDam,
                          stud: _selectedSire,
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (_isPlannedLitter && _selectedDam != null && _selectedSire != null)
              const SizedBox(height: AppSpacing.lg),

            // Date of Birth - skjul i planleggingsmodus
            if (!_isPlannedLitter)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdAll,
                ),
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                child: ListTile(
                  leading: Icon(Icons.cake, color: Theme.of(context).colorScheme.primary),
                  title: Text(_isHistoricalLitter ? '${l10n.dateOfBirth} (${l10n.historicalLitter})' : l10n.dateOfBirth),
                  subtitle: Text(
                    DateFormat('dd.MM.yyyy').format(_dateOfBirth),
                    style: const TextStyle(fontSize: 16),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    // For historiske kull, tillat datoer tilbake til 2000
                    // For nye kull, begrens til siste 75 dager
                    final firstAllowedDate = _isHistoricalLitter 
                        ? DateTime(2000) 
                        : DateTime.now().subtract(const Duration(days: 75));
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dateOfBirth.isBefore(firstAllowedDate) ? firstAllowedDate : _dateOfBirth,
                      firstDate: firstAllowedDate,
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _dateOfBirth = picked);
                    }
                  },
                ),
              ),
            if (!_isPlannedLitter) const SizedBox(height: AppSpacing.lg),

            // Number of Puppies Expected (vis kun for aktive kull, ikke planlagt eller historisk)
            if (!_isPlannedLitter && !_isHistoricalLitter) ...[
              TextFormField(
                decoration: InputDecoration(
                  labelText: l10n.numberOfPuppiesExpected,
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) =>
                    _numberOfPuppies = int.tryParse(value) ?? 0,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Males Count (vis for aktive og historiske kull, ikke planlagte)
            if (!_isPlannedLitter) ...[
              TextFormField(
                decoration: InputDecoration(
                  labelText: l10n.numberOfMales,
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) =>
                    _actualMalesCount = int.tryParse(value) ?? 0,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Females Count
              TextFormField(
                decoration: InputDecoration(
                  labelText: l10n.numberOfFemales,
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
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) =>
                  _actualFemalesCount = int.tryParse(value) ?? 0,
            ),
              const SizedBox(height: AppSpacing.lg),
            ], // Slutt på if (!_isPlannedLitter) - hanner/tisper

            // Notes
            TextFormField(
              decoration: InputDecoration(
                labelText: l10n.notes,
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
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              ),
              maxLines: 3,
              onChanged: (value) => _notes = value,
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Save Button
            ElevatedButton.icon(
              onPressed: _saveLitter,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                backgroundColor: _isPlannedLitter 
                    ? AppColors.warning 
                    : Theme.of(context).primaryColor,
              ),
              icon: Icon(_isPlannedLitter ? Icons.calendar_month : Icons.save),
              label: Text(_isPlannedLitter ? l10n.savePlannedLitter : l10n.saveLitter),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchableBreedDropdown() {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => _showBreedSearchDialog(),
      child: FormField<String>(
        initialValue: _breed,
        validator: (value) =>
            value?.isEmpty ?? true ? l10n.pleaseSelectBreed : null,
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
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            ),
            child: Text(
              _breed.isEmpty ? l10n.pleaseSelectBreed : _breed,
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
          const Text('Velg rase'),
          if (hasKennelBreeds)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                _showAllBreeds ? l10n.showingAllBreeds : l10n.showingKennelBreeds,
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
                padding: const EdgeInsets.all(AppSpacing.md),
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: AppRadius.smAll,
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.tipSetUpBreeds,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            l10n.addBreedsToKennelInfo,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          GestureDetector(
                            onTap: widget.onNavigateToKennelProfile,
                            child: Text(
                              l10n.goToKennelProfile,
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
                  borderRadius: AppRadius.smAll,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (hasKennelBreeds)
              InkWell(
                onTap: _toggleShowAllBreeds,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Icon(
                        _showAllBreeds ? Icons.filter_list_off : Icons.filter_list,
                        size: 18,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _showAllBreeds ? l10n.showOnlyKennelBreeds : l10n.showAllBreeds,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: _filteredBreeds.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noBreedsFoundForQuery(_searchController.text),
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
