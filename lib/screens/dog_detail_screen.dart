import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:breedly/utils/constants.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/models/dog.dart';
import 'package:breedly/models/mating.dart';
import 'package:breedly/models/progesterone_measurement.dart';
import 'package:breedly/utils/app_bar_builder.dart';
import 'package:breedly/screens/dog_health_screen.dart';
import 'package:breedly/screens/dog_show_results_screen.dart';
import 'package:breedly/screens/add_dog_screen.dart';
import 'package:breedly/screens/breeding_contract_screen.dart';
import 'package:breedly/screens/co_ownership_contract_screen.dart';
import 'package:breedly/screens/foster_contract_screen.dart';
import 'package:breedly/widgets/pedigree_widget.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:breedly/services/auth_service.dart';
import 'package:breedly/services/cloud_sync_service.dart';
import 'package:breedly/services/offline_mode_manager.dart';
import 'package:breedly/utils/logger.dart';

class DogDetailScreen extends StatefulWidget {
  final Dog dog;

  const DogDetailScreen({super.key, required this.dog});

  @override
  State<DogDetailScreen> createState() => _DogDetailScreenState();
}

class _DogDetailScreenState extends State<DogDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final dogBox = Hive.box<Dog>('dogs');
    final dam = widget.dog.damId != null
        ? dogBox.values.firstWhere((d) => d.id == widget.dog.damId, orElse: () => Dog(
              id: '',
              name: 'Ukjent',
              breed: '',
              color: '',
              dateOfBirth: DateTime.now(),
              gender: 'Female',
            ))
        : null;

    final sire = widget.dog.sireId != null
        ? dogBox.values.firstWhere((d) => d.id == widget.dog.sireId, orElse: () => Dog(
              id: '',
              name: 'Ukjent',
              breed: '',
              color: '',
              dateOfBirth: DateTime.now(),
              gender: 'Male',
            ))
        : null;

    return Scaffold(
      appBar: AppBarBuilder.buildAppBar(
        title: widget.dog.name,
        context: context,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree_rounded),
            tooltip: 'Stamtavle',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PedigreeScreen(dog: widget.dog),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Rediger',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddDogScreen(dogToEdit: widget.dog),
                ),
              );
              if (result == true && mounted) {
                setState(() {});
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red[400]),
            tooltip: 'Slett hund',
            onPressed: _confirmDeleteDog,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.lg, bottom: 88),
          children: [
          // Basic Info Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.lgAll,
              side: BorderSide(color: AppColors.neutral200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Grunnleggende informasjon',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.neutral900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildInfoRow('Navn', widget.dog.name),
                  _buildInfoRow('Rase', widget.dog.breed),
                  _buildInfoRow('Farge', widget.dog.color),
                  _buildInfoRow('Kjønn', widget.dog.gender == 'Male' ? 'Hann' : 'Tispe'),
                  _buildInfoRow('Fødselsdato', DateFormat('dd.MM.yyyy').format(widget.dog.dateOfBirth)),
                  if (widget.dog.deathDate != null)
                    _buildInfoRow('Dødsdato', DateFormat('dd.MM.yyyy').format(widget.dog.deathDate!)),
                  _buildInfoRow('Alder', widget.dog.deathDate != null 
                      ? 'Avdød (${_calculateAgeAtDeath(widget.dog)})' 
                      : '${widget.dog.getAgeInYears()} år, ${widget.dog.getAgeInMonths() % 12} mnd'),
                  if (widget.dog.registrationNumber != null)
                    _buildInfoRow('Registreringsnummer', widget.dog.registrationNumber!),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Heat Cycles - Only for females
          if (widget.dog.gender == 'Female')
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.lgAll,
                side: BorderSide(color: AppColors.neutral200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_month,
                                color: AppColors.female,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(
                                  'Løpetidssykler',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: AppColors.neutral900,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => _showAddHeatCycleDialog(),
                          tooltip: 'Legg til løpetidsdato',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ..._buildHeatCycleContent(),
                  ],
                ),
              ),
            ),

          const SizedBox(height: AppSpacing.xl),

          // Health Card - Navigate to health screen
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.lgAll,
              side: BorderSide(color: AppColors.neutral200),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DogHealthScreen(dog: widget.dog),
                  ),
                );
              },
              borderRadius: AppRadius.lgAll,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: ThemeOpacity.medium(context)),
                        borderRadius: AppRadius.mdAll,
                      ),
                      child: const Icon(
                        Icons.medical_services_rounded,
                        color: AppColors.success,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Helse & Vaksiner',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.neutral900,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Se og registrer helseopplysninger og vaksiner',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.neutral500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.neutral400,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Show Results Card - Navigate to show results screen
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.lgAll,
              side: BorderSide(color: AppColors.neutral200),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DogShowResultsScreen(dog: widget.dog),
                  ),
                );
              },
              borderRadius: AppRadius.lgAll,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: ThemeOpacity.medium(context)),
                        borderRadius: AppRadius.mdAll,
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: AppColors.secondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Utstillinger',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.neutral900,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Registrer resultater og se statistikk',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.neutral500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.neutral400,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Championships Card
          _buildChampionshipsCard(),
          const SizedBox(height: AppSpacing.xl),

          // Matings Card - Only for males
          if (widget.dog.gender == 'Male')
            _buildMatingsCard(),

          if (widget.dog.gender == 'Male')
            const SizedBox(height: AppSpacing.xl),

          // Pedigree Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.lgAll,
              side: BorderSide(color: AppColors.neutral200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_tree,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Stamtavle',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.neutral900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (dam != null)
                    _buildParentTile(
                      label: 'Mor (Tispe)',
                      dog: dam,
                      isDam: true,
                    )
                  else
                    _buildNoParentTile('Mor (Tispe) - Ikke registrert'),
                  const SizedBox(height: AppSpacing.md),
                  if (sire != null)
                    _buildParentTile(
                      label: 'Far (Hannhund)',
                      dog: sire,
                      isDam: false,
                    )
                  else
                    _buildNoParentTile('Far (Hannhund) - Ikke registrert'),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Notes
          if (widget.dog.notes != null && widget.dog.notes!.isNotEmpty)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.lgAll,
                side: BorderSide(color: AppColors.neutral200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.note_alt_outlined,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Notater',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.neutral900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      widget.dog.notes!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.neutral700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Documents/Contracts Card
          const SizedBox(height: AppSpacing.xl),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.lgAll,
              side: BorderSide(color: AppColors.neutral200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Dokumenter og kontrakter',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.neutral900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Breeding contract (for males)
                  if (widget.dog.gender == 'Male')
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.pets),
                      title: const Text('Avlskontrakt'),
                      subtitle: const Text('Opprett kontrakt for paringstjenester'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BreedingContractScreen(
                              preselectedStud: widget.dog,
                            ),
                          ),
                        );
                      },
                    ),
                  // Co-ownership contract
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.people),
                    title: const Text('Medeieravtale'),
                    subtitle: const Text('Opprett avtale om delt eierskap'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CoOwnershipContractScreen(
                            preselectedDog: widget.dog,
                          ),
                        ),
                      );
                    },
                  ),
                  // Foster contract
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.home_outlined),
                    title: const Text('Fôrvertsavtale'),
                    subtitle: const Text('Opprett avtale om fôrvertskap'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FosterContractScreen(
                            preselectedDog: widget.dog,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
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
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.neutral500,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.neutral900,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateAgeAtDeath(Dog dog) {
    if (dog.deathDate == null) return '';
    final ageInDays = dog.deathDate!.difference(dog.dateOfBirth).inDays;
    final years = ageInDays ~/ 365;
    final months = (ageInDays % 365) ~/ 30;
    return '$years år, $months mnd';
  }

  Widget _buildParentTile({
    required String label,
    required Dog dog,
    required bool isDam,
  }) {
    final genderColor = isDam ? AppColors.female : AppColors.male;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: genderColor.withValues(alpha: ThemeOpacity.medium(context)),
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: genderColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.neutral500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            dog.name,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${dog.breed} • ${dog.color}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoParentTile(String label) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: AppRadius.lgAll,
        border: Border.all(
          color: AppColors.neutral200,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.neutral500,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  void _showAddHeatCycleDialog() async {
    if (!mounted) return;
    
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000), // Allow dates from year 2000
      lastDate: DateTime.now(),
    );
    
    if (picked != null && mounted) {
      widget.dog.heatCycles.add(picked);
      widget.dog.heatCycles.sort((a, b) => b.compareTo(a));
      await widget.dog.save();
      
      // Save to Firebase
      final userId = AuthService().currentUser?.uid;
      if (userId != null) {
        final heatCycleId = picked.millisecondsSinceEpoch.toString();
        await CloudSyncService().saveHeatCycle(
          userId: userId,
          dogId: widget.dog.id,
          heatCycleId: heatCycleId,
          heatCycleData: {
            'date': picked.toIso8601String(),
            'timestamp': picked.millisecondsSinceEpoch,
          },
        );
      }
      
      if (mounted) {
        setState(() {});
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Løpetidsdato lagt til')),
        );
      }
    }
  }

  void _confirmDeleteDog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Slett hund'),
        content: Text(
          'Er du sikker på at du vil slette «${widget.dog.name}»?\n\n'
          'Dette fjerner hunden og alle tilknyttede data. Handlingen kan ikke angres.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Avbryt'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              await _deleteDog();
            },
            child: const Text('Slett', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDog() async {
    final dog = widget.dog;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      // Delete from Firebase first
      final auth = AuthService();
      if (auth.isAuthenticated && OfflineModeManager().isOnline) {
        try {
          await CloudSyncService().deleteDog(
            userId: auth.currentUserId!,
            dogId: dog.id,
          );
        } catch (e) {
          AppLogger.debug('Feil ved sletting fra Firebase: $e');
        }
      }

      // Delete from Hive
      final box = Hive.box<Dog>('dogs');
      await box.delete(dog.id);

      messenger.showSnackBar(
        SnackBar(
          content: Text('«${dog.name}» ble slettet'),
          backgroundColor: AppColors.success,
        ),
      );

      // Go back to the dog list
      navigator.pop(true);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Kunne ikke slette: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _deleteHeatCycle(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slett løpetidsdato'),
        content: const Text('Er du sikker på at du vil slette denne løpetidsdatoen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () async {
              final heatCycleToDelete = widget.dog.heatCycles[index];
              widget.dog.heatCycles.removeAt(index);
              await widget.dog.save();
              
              // Delete from Firebase
              final userId = AuthService().currentUser?.uid;
              if (userId != null) {
                final heatCycleId = heatCycleToDelete.millisecondsSinceEpoch.toString();
                try {
                  await CloudSyncService().deleteHeatCycle(
                    userId: userId,
                    dogId: widget.dog.id,
                    heatCycleId: heatCycleId,
                  );
                } catch (e) {
                  // Ignore errors when deleting from Firebase if it doesn't exist
                  AppLogger.debug('Error deleting heat cycle from Firebase: $e');
                }
              }
              
              if (context.mounted) {
                Navigator.pop(context);
                
                if (mounted) {
                  setState(() {});
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Løpetidsdato slettet')),
                  );
                }
              }
            },
            child: const Text('Slett'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHeatCycleContent() {
    if (widget.dog.heatCycles.isEmpty) {
      return [
        Text(
          'Ingen løpetidsdatoer registrert',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.neutral500,
            fontStyle: FontStyle.italic,
          ),
        )
      ];
    } else {
      return [Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildHeatCycleWidgets(),
      )];
    }
  }

  List<Widget> _buildHeatCycleWidgets() {
    final widgets = <Widget>[];

    // Show estimated next heat cycle
    final nextHeatCycle = widget.dog.getNextEstimatedHeatCycle();
    if (nextHeatCycle != null) {
      final daysUntil = nextHeatCycle.difference(DateTime.now()).inDays;
      
      widgets.add(
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withValues(alpha: ThemeOpacity.medium(context)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF4CAF50),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estimert neste løpetid',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        Text(
                          DateFormat('dd.MM.yyyy').format(nextHeatCycle),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: ThemeOpacity.medium(context)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$daysUntil dager',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Mating window indicator - check for progesterone data
              _buildMatingWindowIndicator(nextHeatCycle),
            ],
          ),
        ),
      );
    }

    // Add existing heat cycle entries
    widgets.addAll(widget.dog.heatCycles.asMap().entries.map((entry) {
      final index = entry.key;
      final date = entry.value;
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE91E63).withValues(alpha: ThemeOpacity.medium(context)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFE91E63).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd.MM.yyyy').format(date),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                onPressed: () => _deleteHeatCycle(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      );
    }).toList());

    return widgets;
  }

  /// Build mating window indicator based on progesterone measurements or default calculation
  Widget _buildMatingWindowIndicator(DateTime nextHeatCycle) {
    // Check for recent progesterone measurements for this dog
    final progesteroneBox = Hive.box<ProgesteroneMeasurement>('progesterone_measurements');
    final recentMeasurements = progesteroneBox.values
        .where((m) => m.dogId == widget.dog.id)
        .toList()
      ..sort((a, b) => b.dateMeasured.compareTo(a.dateMeasured));
    
    // Check if there's a recent measurement (within last 30 days)
    final hasRecentProgesterone = recentMeasurements.isNotEmpty &&
        recentMeasurements.first.dateMeasured.isAfter(
          DateTime.now().subtract(const Duration(days: 30)),
        );
    
    if (hasRecentProgesterone) {
      // Use progesterone-based mating window
      return _buildProgesteroneBasedMatingWindow(recentMeasurements);
    } else {
      // Use default day 11-14 calculation
      return _buildDefaultMatingWindow(nextHeatCycle);
    }
  }

  Widget _buildDefaultMatingWindow(DateTime heatStart) {
    final matingWindowStart = heatStart.add(const Duration(days: 11));
    final matingWindowEnd = heatStart.add(const Duration(days: 14));
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9800).withValues(alpha: ThemeOpacity.low(context)),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFFF9800).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.favorite,
            color: Color(0xFFFF9800),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Standard parringsvindu (dag 11-14)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Color(0xFFFF9800),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('dd.MM.yyyy').format(matingWindowStart)} - ${DateFormat('dd.MM.yyyy').format(matingWindowEnd)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFE65100),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Registrer progesteronmålinger for mer nøyaktig vindu',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
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

  Widget _buildProgesteroneBasedMatingWindow(List<ProgesteroneMeasurement> measurements) {
    final latestMeasurement = measurements.first;
    final status = latestMeasurement.getStatus();
    
    // Get color based on status
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case ProgesteroneStatus.basal:
        statusColor = Colors.grey;
        statusIcon = Icons.schedule;
        break;
      case ProgesteroneStatus.lhPeak:
        statusColor = const Color(0xFFFF9800);
        statusIcon = Icons.trending_up;
        break;
      case ProgesteroneStatus.ovulation:
        statusColor = const Color(0xFF8BC34A);
        statusIcon = Icons.egg_alt;
        break;
      case ProgesteroneStatus.fertileWindow:
        statusColor = const Color(0xFF4CAF50);
        statusIcon = Icons.favorite;
        break;
      case ProgesteroneStatus.lateWindow:
        statusColor = const Color(0xFF2196F3);
        statusIcon = Icons.timer;
        break;
      case ProgesteroneStatus.tooLate:
        statusColor = const Color(0xFFF44336);
        statusIcon = Icons.cancel;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: ThemeOpacity.low(context)),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                statusIcon,
                color: statusColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Parringsvindu basert på progesteron',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: statusColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: status.isUrgent ? statusColor : statusColor.withValues(alpha: ThemeOpacity.high(context)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: status.isUrgent ? Colors.white : statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Status description
          Text(
            status.description,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          // Recommendation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: ThemeOpacity.medium(context)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(
                  status.canMate ? Icons.check_circle : Icons.info_outline,
                  size: 14,
                  color: statusColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    status.recommendation,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: status.isUrgent ? FontWeight.bold : FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Reference ranges
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: ThemeOpacity.medium(context)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Referanseverdier for ${status.label}:',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        status.rangeNgMl,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    Text(
                      'eller',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[500],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        status.rangeNmolL,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.science,
                size: 12,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Siste måling: ${DateFormat('dd.MM.yyyy HH:mm').format(latestMeasurement.dateMeasured)} - ${latestMeasurement.displayValue}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          // Show history of recent measurements
          if (measurements.length > 1) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: ThemeOpacity.low(context)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Siste målinger:',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...measurements.take(3).map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('dd.MM HH:mm').format(m.dateMeasured),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              m.displayValue,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _getProgesteroneColor(m.valueInNgMl),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${m.getStatus().label})',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getProgesteroneColor(double valueNgMl) {
    if (valueNgMl < 2.0) return Colors.grey;
    if (valueNgMl < 5.0) return const Color(0xFFFF9800);
    if (valueNgMl < 10.0) return const Color(0xFF8BC34A);
    if (valueNgMl < 20.0) return const Color(0xFF4CAF50);
    if (valueNgMl < 30.0) return const Color(0xFF2196F3);
    return const Color(0xFFF44336);
  }

  // Liste over vanlige championater
  static const List<String> _availableChampionships = [
    // Nasjonale
    'NOCH', // Norsk Champion
    'NUCH', // Nordisk Utstillingschampion (gammel)
    'SUCH', // Svensk Champion
    'DKCH', // Dansk Champion
    'SFCH', // Finsk Champion
    // Nordisk
    'NORDCH', // Nordisk Champion
    // Internasjonale
    'INTCH', // Internasjonal Champion
    'C.I.B.', // Internasjonal Beauty Champion
    'C.I.E.', // Internasjonal Show Champion
    // Brukschampionater
    'KORAD', // Mentalbeskrevet og godkjent
    'BH', // Brukshund
    'NJC', // Norsk Jaktchampion
    'SJC', // Svensk Jaktchampion
    // Andre
    'JWW', // Junior World Winner
    'WW', // World Winner
    'NORDW', // Nordic Winner
    'NV', // Norsk Vinner
    'SV', // Svensk Vinner
    'DV', // Dansk Vinner
    'HeV', // Helsinki Vinner
  ];

  Widget _buildChampionshipsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: BorderSide(color: AppColors.neutral200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: ThemeOpacity.high(context)),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: AppColors.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Championater & Titler',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.neutral900,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Registrer oppnådde titler',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.neutral500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: Theme.of(context).primaryColor,
                  onPressed: _showAddChampionshipDialog,
                ),
              ],
            ),
            if (widget.dog.championships.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.dog.championships.map((title) {
                  return Chip(
                    label: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: Colors.amber[700],
                    deleteIcon: const Icon(Icons.close, size: 18, color: Colors.white),
                    onDeleted: () => _removeChampionship(title),
                  );
                }).toList(),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: ThemeOpacity.low(context)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Ingen championater registrert',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddChampionshipDialog() {
    // Filtrer ut allerede valgte championater
    final available = _availableChampionships
        .where((c) => !widget.dog.championships.contains(c))
        .toList();
    
    String? selectedChampionship;
    final customController = TextEditingController();
    bool useCustom = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Legg til championat'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (available.isNotEmpty && !useCustom) ...[
                  const Text(
                    'Velg championat:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: available.map((championship) {
                      final isSelected = selectedChampionship == championship;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedChampionship = isSelected ? null : championship;
                          });
                        },
                        child: Chip(
                          label: Text(championship),
                          backgroundColor: isSelected 
                              ? Colors.amber[700] 
                              : Colors.grey[200],
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      setDialogState(() => useCustom = true);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Skriv inn annen tittel'),
                  ),
                ],
                if (useCustom || available.isEmpty) ...[
                  const Text(
                    'Skriv inn tittel:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: customController,
                    decoration: const InputDecoration(
                      hintText: 'F.eks. NOCH, NORDCH, WW-25...',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  if (available.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        setDialogState(() => useCustom = false);
                      },
                      icon: const Icon(Icons.list),
                      label: const Text('Velg fra liste'),
                    ),
                  ],
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Avbryt'),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                
                final championshipToAdd = useCustom 
                    ? customController.text.trim().toUpperCase()
                    : selectedChampionship;
                
                if (championshipToAdd != null && championshipToAdd.isNotEmpty) {
                  if (!widget.dog.championships.contains(championshipToAdd)) {
                    widget.dog.championships = [...widget.dog.championships, championshipToAdd];
                    await widget.dog.save();
                    
                    // Sync to cloud
                    try {
                      final userId = AuthService().currentUserId;
                      if (userId != null) {
                        await CloudSyncService().saveDog(
                          userId: userId,
                          dogId: widget.dog.id,
                          dogData: widget.dog.toJson(),
                        );
                      }
                    } catch (e) {
                      AppLogger.debug('Error syncing championship: \$e');
                    }
                    
                    if (mounted) {
                      navigator.pop();
                      setState(() {});
                    }
                  } else {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Denne tittelen er allerede registrert')),
                    );
                  }
                }
              },
              child: const Text('Legg til'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeChampionship(String championship) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fjern championat'),
        content: Text('Er du sikker på at du vil fjerne "$championship"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Fjern'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.dog.championships = widget.dog.championships
          .where((c) => c != championship)
          .toList();
      await widget.dog.save();
      
      // Sync to cloud
      try {
        final userId = AuthService().currentUserId;
        if (userId != null) {
          await CloudSyncService().saveDog(
            userId: userId,
            dogId: widget.dog.id,
            dogData: widget.dog.toJson(),
          );
        }
      } catch (e) {
        AppLogger.debug('Error syncing championship removal: \$e');
      }
      
      if (mounted) {
        setState(() {});
      }
    }
  }

  Widget _buildMatingsCard() {
    final matingsBox = Hive.box<Mating>('matings');
    final matings = matingsBox.values
        .where((m) => m.sireId == widget.dog.id)
        .toList()
      ..sort((a, b) => b.matingDate.compareTo(a.matingDate));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: BorderSide(color: AppColors.neutral200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      color: AppColors.female,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Parringer',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.neutral900,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddMatingDialog(),
                  tooltip: 'Legg til parring',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (matings.isEmpty)
              Text(
                'Ingen parringer registrert',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.neutral500,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Column(
                children: matings.map((mating) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.male.withValues(alpha: ThemeOpacity.medium(context)),
                        borderRadius: AppRadius.mdAll,
                        border: Border.all(
                          color: AppColors.male.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mating.damName ?? 'Ukjent tispe',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: AppColors.neutral900,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Dato: ${DateFormat('dd.MM.yyyy').format(mating.matingDate)}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.neutral500,
                                  ),
                                ),
                                if (mating.puppyCount != null)
                                  Text(
                                    'Valper: ${mating.puppyCount}',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.neutral500,
                                    ),
                                  ),
                                if (mating.notes != null && mating.notes!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                                    child: Text(
                                      mating.notes!,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.neutral600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _showEditMatingDialog(mating),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(height: 8),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () => _deleteMating(mating),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddMatingDialog() async {
    final dogBox = Hive.box<Dog>('dogs');
    final females = dogBox.values.where((d) => d.gender == 'Female').toList();
    
    Dog? selectedDam;
    DateTime selectedDate = DateTime.now();
    final puppyCountController = TextEditingController();
    final notesController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Legg til parring'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tispe',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<Dog>(
                  isExpanded: true,
                  initialValue: selectedDam,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Velg tispe',
                  ),
                  items: [
                    const DropdownMenuItem<Dog>(
                      value: null,
                      child: Text('Ekstern tispe'),
                    ),
                    ...females.map((dog) => DropdownMenuItem<Dog>(
                          value: dog,
                          child: Text(
                            dog.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                  ],
                  onChanged: (Dog? value) {
                    setDialogState(() {
                      selectedDam = value;
                    });
                  },
                ),
                if (selectedDam == null) ...[
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Tispens navn',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      // Store name for external dam
                    },
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Parringsdato',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('dd.MM.yyyy').format(selectedDate)),
                        const Icon(Icons.calendar_today, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: puppyCountController,
                  decoration: const InputDecoration(
                    labelText: 'Antall valper (valgfritt)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notater (valgfritt)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Avbryt'),
            ),
            TextButton(
              onPressed: () async {
                final matingsBox = Hive.box<Mating>('matings');
                final mating = Mating(
                  id: const Uuid().v4(),
                  sireId: widget.dog.id,
                  damId: selectedDam?.id ?? '',
                  damName: selectedDam?.name,
                  matingDate: selectedDate,
                  puppyCount: int.tryParse(puppyCountController.text),
                  notes: notesController.text.isEmpty ? null : notesController.text,
                );
                await matingsBox.put(mating.id, mating);
                
                // Save to Firebase
                final userId = AuthService().currentUser?.uid;
                if (userId != null) {
                  await CloudSyncService().saveMating(
                    userId: userId,
                    dogId: mating.sireId,
                    matingId: mating.id,
                    matingData: mating.toJson(),
                  );
                }
                
                if (context.mounted) {
                  Navigator.pop(context);
                  if (mounted) {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Parring lagt til')),
                    );
                  }
                }
              },
              child: const Text('Lagre'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMatingDialog(Mating mating) async {
    final dogBox = Hive.box<Dog>('dogs');
    final females = dogBox.values.where((d) => d.gender == 'Female').toList();
    
    Dog? selectedDam = mating.damId.isNotEmpty 
        ? females.firstWhere((d) => d.id == mating.damId, orElse: () => females.first)
        : null;
    DateTime selectedDate = mating.matingDate;
    final puppyCountController = TextEditingController(
      text: mating.puppyCount?.toString() ?? '',
    );
    final notesController = TextEditingController(text: mating.notes ?? '');
    final damNameController = TextEditingController(text: mating.damName ?? '');

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Rediger parring'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tispe',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<Dog?>(
                  isExpanded: true,
                  initialValue: selectedDam,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Velg tispe',
                  ),
                  items: [
                    const DropdownMenuItem<Dog?>(
                      value: null,
                      child: Text('Ekstern tispe'),
                    ),
                    ...females.map((dog) => DropdownMenuItem<Dog?>(
                          value: dog,
                          child: Text(
                            dog.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                  ],
                  onChanged: (Dog? value) {
                    setDialogState(() {
                      selectedDam = value;
                    });
                  },
                ),
                if (selectedDam == null) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: damNameController,
                    decoration: const InputDecoration(
                      labelText: 'Tispens navn',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Parringsdato',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('dd.MM.yyyy').format(selectedDate)),
                        const Icon(Icons.calendar_today, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: puppyCountController,
                  decoration: const InputDecoration(
                    labelText: 'Antall valper (valgfritt)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notater (valgfritt)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Avbryt'),
            ),
            TextButton(
              onPressed: () async {
                mating.damId = selectedDam?.id ?? '';
                mating.damName = selectedDam?.name ?? damNameController.text;
                mating.matingDate = selectedDate;
                mating.puppyCount = int.tryParse(puppyCountController.text);
                mating.notes = notesController.text.isEmpty ? null : notesController.text;
                await mating.save();
                
                // Save to Firebase
                final userId = AuthService().currentUser?.uid;
                if (userId != null) {
                  await CloudSyncService().saveMating(
                    userId: userId,
                    dogId: mating.sireId,
                    matingId: mating.id,
                    matingData: mating.toJson(),
                  );
                }
                
                if (context.mounted) {
                  Navigator.pop(context);
                  if (mounted) {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Parring oppdatert')),
                    );
                  }
                }
              },
              child: const Text('Lagre'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteMating(Mating mating) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slett parring'),
        content: const Text('Er du sikker på at du vil slette denne parringen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () async {
              // Delete from Firebase first
              final userId = AuthService().currentUser?.uid;
              if (userId != null) {
                await CloudSyncService().deleteMating(
                  userId: userId,
                  dogId: mating.sireId,
                  matingId: mating.id,
                );
              }
              // Then delete from Hive
              await mating.delete();
              if (context.mounted) {
                Navigator.pop(context);
                if (mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Parring slettet')),
                  );
                }
              }
            },
            child: const Text('Slett'),
          ),
        ],
      ),
    );
  }
}
