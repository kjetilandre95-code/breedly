import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:breedly/utils/constants.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/utils/theme_colors.dart';
import 'package:breedly/models/litter.dart';
import 'package:breedly/models/puppy.dart';
import 'package:breedly/models/dog.dart';
import 'package:breedly/models/puppy_weight_log.dart';
import 'package:breedly/screens/add_puppy_screen.dart';
import 'package:breedly/screens/temperature_tracking_screen.dart';
import 'package:breedly/screens/dog_health_screen.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:breedly/utils/pdf_generator.dart';
import 'package:breedly/utils/notification_service.dart';
import 'dart:io' show File, Directory;
import 'package:path_provider/path_provider.dart';
import 'package:breedly/screens/gallery_screen.dart';
import 'package:breedly/utils/ui_helpers.dart';
import 'package:breedly/utils/translations.dart';
import 'package:breedly/models/treatment_plan.dart';
import 'package:breedly/screens/puppy_contract_list_screen.dart';
import 'package:breedly/utils/app_bar_builder.dart';
import 'package:breedly/utils/page_info_helper.dart';
import 'package:breedly/services/auth_service.dart';
import 'package:breedly/services/cloud_sync_service.dart';
import 'package:breedly/services/share_service.dart';

class LitterDetailScreen extends StatefulWidget {
  final Litter litter;

  const LitterDetailScreen({super.key, required this.litter});

  @override
  State<LitterDetailScreen> createState() => _LitterDetailScreenState();
}

class _LitterDetailScreenState extends State<LitterDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, bool> _expandedPuppies = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      appBar: AppBarBuilder.buildAppBar(
        title: '${widget.litter.damName} × ${widget.litter.sireName}',
        context: context,
        actions: [
          PageInfoHelper.buildInfoButton(
            context,
            title: PageInfoContent.litterDetail.title,
            description: PageInfoContent.litterDetail.description,
            features: PageInfoContent.litterDetail.features,
            tip: PageInfoContent.litterDetail.tip,
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Rediger'),
                onTap: () {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (context.mounted) {
                      _editLitter(context);
                    }
                  });
                },
              ),
              PopupMenuItem(
                child: const Text('Slett kull'),
                onTap: () {
                  _deleteLitter(context);
                },
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: context.colors.textCaption,
          indicatorColor: primaryColor,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.info_outlined), text: 'Info'),
            Tab(icon: Icon(Icons.pets_outlined), text: 'Valper'),
            Tab(icon: Icon(Icons.assignment_outlined), text: 'Registrering'),
            Tab(icon: Icon(Icons.image_outlined), text: 'Galleri'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildInfoTab(),
            _buildPuppiesTab(),
            _buildTrackingTab(),
            _buildGalleryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    final puppies = Hive.box<Puppy>(
      'puppies',
    ).values.where((p) => p.litterId == widget.litter.id).toList();
    final soldCount = puppies.where((p) => p.status == 'Sold').length;
    final reservedCount = puppies.where((p) => p.status == 'Reserved').length;
    final availableCount = puppies
        .where((p) => p.status == 'Available' || p.status == null)
        .length;

    // Sjekk om dette er et planlagt kull (fødselsdato i fremtiden)
    final isPlannedLitter = widget.litter.dateOfBirth.isAfter(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.lg, bottom: 88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Planlagt kull banner
          if (isPlannedLitter)
            _buildPlannedLitterBanner(),

          if (isPlannedLitter) const SizedBox(height: AppSpacing.lg),

          // Status Overview Card - viser raskt oversikt (kun hvis født)
          if (!isPlannedLitter)
            _buildStatusOverviewCard(
              puppies,
              soldCount,
              reservedCount,
              availableCount,
            ),
          if (!isPlannedLitter) const SizedBox(height: AppSpacing.lg),

          // Litter Information Card
          Card(
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
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        isPlannedLitter ? 'Planlagt kull' : 'Kullinfo',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildInfoRow('Mor', widget.litter.damName),
                  _buildInfoRow('Far', widget.litter.sireName),
                  _buildInfoRow('Rase', widget.litter.breed),
                  if (!isPlannedLitter) ...[
                    _buildInfoRow(
                      'Fødselsdato',
                      _formatDateWithRelative(widget.litter.dateOfBirth),
                    ),
                    _buildInfoRow(
                      'Alder',
                      _formatAge(
                        widget.litter.getAgeInWeeks(),
                        widget.litter.getAgeInDays(),
                      ),
                    ),
                    _buildInfoRow('Status', widget.litter.getStatus()),
                  ],
                  if (puppies.isNotEmpty && !isPlannedLitter) ...[
                    const SizedBox(height: AppSpacing.md),
                    const Divider(),
                    const SizedBox(height: AppSpacing.md),
                    _buildInfoRow('Totalt valper', '${puppies.length}'),
                    _buildInfoRow(
                      'Hanner',
                      '${puppies.where((p) => p.gender == "Male").length}',
                    ),
                    _buildInfoRow(
                      'Tisper',
                      '${puppies.where((p) => p.gender == "Female").length}',
                    ),
                  ],
                  if (widget.litter.damMatingDate != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    const Divider(),
                    const SizedBox(height: AppSpacing.md),
                    _buildInfoRow(
                      'Parringsdato',
                      DateFormat(
                        'dd.MM.yyyy',
                      ).format(widget.litter.damMatingDate!),
                    ),
                  ],
                  if (widget.litter.estimatedDueDate != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _buildInfoRow(
                      'Estimert dato for fødsel',
                      DateFormat(
                        'dd.MM.yyyy',
                      ).format(widget.litter.estimatedDueDate!),
                    ),
                    // Vis bare "Dager til valping" hvis forventet dato er i fremtiden
                    if (widget.litter.estimatedDueDate!.isAfter(
                      DateTime.now(),
                    )) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _buildHighlightedInfoRow(
                        'Dager til valping',
                        '${widget.litter.estimatedDueDate!.difference(DateTime.now()).inDays}',
                        Theme.of(context).primaryColor,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),

          // Hurtighandlinger
          const SizedBox(height: AppSpacing.lg),
          if (isPlannedLitter)
            _buildPlannedLitterActionsCard()
          else
            _buildQuickActionsCard(),

          // Behandlingsoversikt
          if (puppies.isNotEmpty && !isPlannedLitter) ...[
            const SizedBox(height: AppSpacing.lg),
            _buildTreatmentOverviewCard(puppies),
          ],
        ],
      ),
    );
  }

  Widget _buildPlannedLitterBanner() {
    final hasEstimatedDate = widget.litter.estimatedDueDate != null;
    final daysToGo = hasEstimatedDate
        ? widget.litter.estimatedDueDate!.difference(DateTime.now()).inDays
        : null;
    final primaryColor = Theme.of(context).primaryColor;

    return Card(
      color: primaryColor.withValues(alpha: ThemeOpacity.medium(context)),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: BorderSide(color: primaryColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: ThemeOpacity.high(context)),
                    borderRadius: AppRadius.lgAll,
                  ),
                  child: Icon(
                    Icons.calendar_month,
                    color: primaryColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Planlagt kull',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        daysToGo != null
                            ? (daysToGo > 0
                                ? '$daysToGo dager til estimert fødsel'
                                : 'Estimert dato for fødsel har passert')
                            : 'Sett parringsdato for å beregne termin',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _registerBirth(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                icon: const Icon(Icons.cake),
                label: const Text('Registrer fødsel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlannedLitterActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.rocket_launch,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  'Planleggingsverktøy',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Parringsdato-seksjon
            _buildMatingDateSection(),
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.thermostat,
                    label: 'Temperatur',
                    color: Theme.of(context).primaryColor,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TemperatureTrackingScreen(litter: widget.litter),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.science,
                    label: 'Progesteron',
                    color: Theme.of(context).colorScheme.secondary,
                    onTap: () => _openProgesteroneMeasurements(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.edit_calendar,
                    label: 'Rediger',
                    color: Theme.of(context).primaryColor,
                    onTap: () => _editLitter(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.cake,
                    label: 'Fødsel',
                    color: Theme.of(context).colorScheme.secondary,
                    onTap: () => _registerBirth(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatingDateSection() {
    final hasMatingDate = widget.litter.damMatingDate != null;
    final hasEstimatedDate = widget.litter.estimatedDueDate != null;
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasMatingDate ? Icons.check_circle : Icons.calendar_today,
                color: primaryColor,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  hasMatingDate
                      ? 'Parringsdato: ${DateFormat('dd.MM.yyyy').format(widget.litter.damMatingDate!)}'
                      : 'Ingen parringsdato satt',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _selectMatingDate,
                icon: Icon(
                  hasMatingDate ? Icons.edit : Icons.add,
                  size: 16,
                ),
                label: Text(hasMatingDate ? 'Endre' : 'Sett dato'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                ),
              ),
            ],
          ),
          if (hasEstimatedDate) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.child_care, color: Theme.of(context).primaryColor, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Estimert fødsel: ${DateFormat('dd.MM.yyyy').format(widget.litter.estimatedDueDate!)}',
                  style: TextStyle(
                    color: context.colors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (widget.litter.estimatedDueDate!.isAfter(DateTime.now())) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const SizedBox(width: 26),
                  Text(
                    '${widget.litter.estimatedDueDate!.difference(DateTime.now()).inDays} dager igjen',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _selectMatingDate() async {
    final now = DateTime.now();
    final initialDate = widget.litter.damMatingDate ?? now;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? now : initialDate,
      firstDate: now.subtract(const Duration(days: 120)),
      lastDate: now,
      helpText: 'Velg parringsdato',
    );

    if (selectedDate != null) {
      setState(() {
        widget.litter.damMatingDate = selectedDate;
        // Beregn estimert fødselsdato: 63 dager etter parring
        final estimatedDue = selectedDate.add(const Duration(days: 63));
        widget.litter.estimatedDueDate = estimatedDue;
        // Oppdater dateOfBirth til estimert fødselsdato (for visning)
        widget.litter.dateOfBirth = estimatedDue;
      });

      await widget.litter.save();

      // Synkroniser til Firebase
      final authService = AuthService();
      if (authService.isAuthenticated) {
        final cloudSync = CloudSyncService();
        try {
          await cloudSync.saveLitter(
            userId: authService.currentUserId!,
            litterId: widget.litter.id,
            litterData: widget.litter.toJson(),
          );
        } catch (e) {
          // Ignorer feil
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Parringsdato satt til ${DateFormat('dd.MM.yyyy').format(selectedDate)}. '
              'Estimert fødsel: ${DateFormat('dd.MM.yyyy').format(widget.litter.estimatedDueDate!)}',
            ),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
      }
    }
  }

  void _openProgesteroneMeasurements() async {
    // Finn tispen
    final dogBox = Hive.box<Dog>('dogs');
    Dog? dam;
    try {
      dam = dogBox.values.firstWhere((d) => d.id == widget.litter.damId);
    } catch (e) {
      dam = null;
    }
    
    if (dam != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DogHealthScreen(dog: dam!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunne ikke finne tispen')),
      );
    }
  }

  void _registerBirth() {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Registrer fødsel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kullet er nå født! Vil du oppdatere fødselsdatoen til i dag?'),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Du kan deretter legge til valpene manuelt.',
              style: TextStyle(color: context.colors.textDisabled, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Avbryt'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Oppdater fødselsdato til i dag
              widget.litter.dateOfBirth = DateTime.now();
              // Fjern [Planlagt kull] fra notater hvis det finnes
              if (widget.litter.notes != null) {
                widget.litter.notes = widget.litter.notes!.replaceAll('[Planlagt kull]', '').trim();
                if (widget.litter.notes!.isEmpty) {
                  widget.litter.notes = null;
                }
              }
              await widget.litter.save();
              
              // Synkroniser til Firebase
              final authService = AuthService();
              if (authService.isAuthenticated) {
                final cloudSync = CloudSyncService();
                try {
                  await cloudSync.saveLitter(
                    userId: authService.currentUserId!,
                    litterId: widget.litter.id,
                    litterData: widget.litter.toJson(),
                  );
                } catch (e) {
                  // Ignorer feil
                }
              }
              
              if (mounted) {
                navigator.pop();
                setState(() {});
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Fødsel registrert! Du kan nå legge til valper.')),
                );
              }
            },
            child: const Text('Registrer'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOverviewCard(
    List<Puppy> puppies,
    int sold,
    int reserved,
    int available,
  ) {
    final total = puppies.length;
    if (total == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(Icons.pets_outlined, size: 40, color: context.colors.textDisabled),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ingen valper ennå',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Gå til Valper-fanen for å legge til valper',
                      style: TextStyle(color: context.colors.textCaption, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pets, color: Theme.of(context).primaryColor),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Valper ($total)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Progress bar
            ClipRRect(
              borderRadius: AppRadius.mdAll,
              child: LinearProgressIndicator(
                value: total > 0 ? (sold + reserved) / total : 0,
                backgroundColor: context.colors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  sold == total ? AppColors.success : Theme.of(context).primaryColor,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStatusBox('Ledig', available, AppColors.info),
                _buildMiniStatusBox('Reservert', reserved, AppColors.reserved),
                _buildMiniStatusBox('Solgt', sold, AppColors.success),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatusBox(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: ThemeOpacity.low(context)),
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: AppTypography.caption.copyWith(color: context.colors.textCaption)),
      ],
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Theme.of(context).primaryColor),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Hurtighandlinger',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.thermostat,
                    label: 'Temperatur',
                    color: Theme.of(context).primaryColor,
                    onTap: widget.litter.damMatingDate != null
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TemperatureTrackingScreen(
                                  litter: widget.litter,
                                ),
                              ),
                            );
                          }
                        : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.scale,
                    label: 'Veiing',
                    color: Theme.of(context).colorScheme.secondary,
                    onTap: () => _showBulkWeightDialog(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.add,
                    label: 'Ny valp',
                    color: AppColors.success,
                    onTap: () => _showAddPuppyDialog(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgAll,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isEnabled ? color.withValues(alpha: ThemeOpacity.low(context)) : context.colors.borderSubtle,
          borderRadius: AppRadius.lgAll,
          border: Border.all(
            color: isEnabled ? color.withValues(alpha: 0.3) : context.colors.divider,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isEnabled ? color : context.colors.textDisabled, size: 24),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isEnabled ? color : context.colors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentOverviewCard(List<Puppy> puppies) {
    int totalVaccinated = 0;
    int totalDewormed = 0;
    int totalMicrochipped = 0;

    for (var puppy in puppies) {
      if (puppy.vaccinated) totalVaccinated++;
      if (puppy.dewormed) totalDewormed++;
      if (puppy.microchipped) totalMicrochipped++;
    }

    final total = puppies.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.medical_services,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Behandlingsoversikt',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildTreatmentProgressRow(
              'Vaksinert',
              totalVaccinated,
              total,
              AppColors.success,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildTreatmentProgressRow(
              'Avmasket',
              totalDewormed,
              total,
              AppColors.warning,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildTreatmentProgressRow(
              'ID-merket',
              totalMicrochipped,
              total,
              AppColors.info,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentProgressRow(
    String label,
    int done,
    int total,
    Color color,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: AppRadius.xsAll,
            child: LinearProgressIndicator(
              value: total > 0 ? done / total : 0,
              backgroundColor: context.colors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$done/$total',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: done == total && total > 0 ? color : context.colors.textCaption,
          ),
        ),
      ],
    );
  }

  String _formatDateWithRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final diff = dateOnly.difference(today).inDays;

    final formatted = DateFormat('dd.MM.yyyy').format(date);

    if (diff == 0) return '$formatted (i dag)';
    if (diff == 1) return '$formatted (i morgen)';
    if (diff == -1) return '$formatted (i går)';

    return formatted;
  }

  String _formatAge(int weeks, int days) {
    if (weeks == 0) {
      return '$days ${days == 1 ? "dag" : "dager"}';
    }
    final remainingDays = days % 7;
    if (remainingDays == 0) {
      return '$weeks ${weeks == 1 ? "uke" : "uker"}';
    }
    return '$weeks ${weeks == 1 ? "uke" : "uker"} og $remainingDays ${remainingDays == 1 ? "dag" : "dager"}';
  }

  Widget _buildHighlightedInfoRow(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: ThemeOpacity.low(context)),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.9),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPuppiesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.lg, bottom: 88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Puppies Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sammendrag',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Builder(
                        builder: (context) {
                          final primaryColor = Theme.of(context).primaryColor;
                          return ElevatedButton.icon(
                            onPressed: () => _showAddPuppyDialog(),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Legg til valp'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryBoxWithIcon(
                        'Totalt',
                        '${widget.litter.getTotalPuppiesCountFromPuppies()}',
                        AppColors.info,
                        Icons.pets,
                      ),
                      _buildSummaryBoxWithIcon(
                        'Hanner',
                        '${widget.litter.getActualMalesCountFromPuppies()}',
                        AppColors.male,
                        Icons.male,
                      ),
                      _buildSummaryBoxWithIcon(
                        'Tisper',
                        '${widget.litter.getActualFemalesCountFromPuppies()}',
                        AppColors.female,
                        Icons.female,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Puppies List
          Text('Valpeliste', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          ValueListenableBuilder(
            valueListenable: Hive.box<Puppy>('puppies').listenable(),
            builder: (context, Box<Puppy> box, _) {
              final puppies = box.values
                  .where((p) => p.litterId == widget.litter.id)
                  .toList();

              if (puppies.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.xxxl),
                  decoration: BoxDecoration(
                    border: Border.all(color: context.colors.divider),
                    borderRadius: AppRadius.lgAll,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.pets_outlined,
                          size: 48,
                          color: context.colors.textDisabled,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Ingen valper registrert ennå',
                          style: TextStyle(color: context.colors.textCaption),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: puppies.length,
                itemBuilder: (context, index) {
                  final puppy = puppies[index];
                  final puppyId = puppy.id;

                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        onExpansionChanged: (expanded) {
                          setState(() {
                            _expandedPuppies[puppyId] = expanded;
                          });
                        },
                        title: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: puppy.gender == 'Male'
                                    ? AppColors.male.withValues(alpha: ThemeOpacity.medium(context))
                                    : AppColors.female.withValues(alpha: ThemeOpacity.medium(context)),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.pets,
                                  size: 20,
                                  color: puppy.gender == 'Male'
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
                                    puppy.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Farge: ${puppy.color} • Alder: ${puppy.getAgeInWeeks()} uker',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: context.colors.textCaption,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  puppy.status ?? 'Available',
                                ).withValues(alpha: ThemeOpacity.medium(context)),
                                borderRadius: AppRadius.lgAll,
                              ),
                              child: Text(
                                AppTranslations.translatePuppyStatus(
                                  puppy.status ?? 'Available',
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(
                                    puppy.status ?? 'Available',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailSection('Grunninfo', [
                                  UIHelpers.buildDetailRow(
                                    'Kjønn',
                                    AppTranslations.translateGender(
                                      puppy.gender,
                                    ),
                                  ),
                                  UIHelpers.buildDetailRow(
                                    'Fødselsdato',
                                    DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(puppy.dateOfBirth),
                                  ),
                                  if (puppy.birthTime != null)
                                    UIHelpers.buildDetailRow(
                                      'Fødselsidspunkt',
                                      DateFormat(
                                        'HH:mm',
                                      ).format(puppy.birthTime!),
                                    ),
                                  if (puppy.birthWeight != null)
                                    UIHelpers.buildDetailRow(
                                      'Fødselsvekt',
                                      '${puppy.birthWeight?.toStringAsFixed(0)} g',
                                    ),
                                ]),
                                const SizedBox(height: AppSpacing.lg),
                                _buildDetailSection('Behandlinger', [
                                  UIHelpers.buildDetailRow(
                                    'Vaksinert',
                                    puppy.vaccinated ? '✓ Ja' : '✗ Nei',
                                  ),
                                  UIHelpers.buildDetailRow(
                                    'Avmasket',
                                    puppy.dewormed ? '✓ Ja' : '✗ Nei',
                                  ),
                                  UIHelpers.buildDetailRow(
                                    'Microchippet',
                                    puppy.microchipped ? '✓ Ja' : '✗ Nei',
                                  ),
                                ]),
                                const SizedBox(height: AppSpacing.lg),
                                if (puppy.buyerName != null &&
                                    puppy.buyerName!.isNotEmpty) ...[
                                  _buildDetailSection('Kjøper', [
                                    UIHelpers.buildDetailRow(
                                      'Navn',
                                      puppy.buyerName!,
                                    ),
                                    if (puppy.buyerContact != null &&
                                        puppy.buyerContact!.isNotEmpty)
                                      UIHelpers.buildDetailRow(
                                        'Kontakt',
                                        puppy.buyerContact!,
                                      ),
                                  ]),
                                  const SizedBox(height: AppSpacing.lg),
                                ],
                                if (puppy.notes != null &&
                                    puppy.notes!.isNotEmpty) ...[
                                  _buildDetailSection('Notater', [
                                    Text(
                                      puppy.notes!,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ]),
                                  const SizedBox(height: AppSpacing.lg),
                                ],
                                // Action Buttons - Rad 1: Vekt og Plan
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          _showWeightChart(context, puppy);
                                        },
                                        icon: const Icon(
                                          Icons.show_chart,
                                          size: 18,
                                        ),
                                        label: const FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text('Vekt'),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: context.colors.surface,
                                          foregroundColor: Theme.of(
                                            context,
                                          ).primaryColor,
                                          side: BorderSide(
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          _showTreatmentPlan(context, puppy);
                                        },
                                        icon: const Icon(
                                          Icons.assignment,
                                          size: 18,
                                        ),
                                        label: const FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text('Plan'),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: context.colors.surface,
                                          foregroundColor: Theme.of(
                                            context,
                                          ).primaryColor,
                                          side: BorderSide(
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  PuppyContractListScreen(
                                                    puppy: puppy,
                                                  ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.receipt,
                                          size: 18,
                                        ),
                                        label: const FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text('Kontrakt'),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: context.colors.surface,
                                          foregroundColor: Theme.of(
                                            context,
                                          ).primaryColor,
                                          side: BorderSide(
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          _exportPuppyPDF(context, puppy);
                                        },
                                        icon: const Icon(
                                          Icons.description,
                                          size: 18,
                                        ),
                                        label: const FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text('PDF'),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: context.colors.surface,
                                          foregroundColor: Theme.of(
                                            context,
                                          ).primaryColor,
                                          side: BorderSide(
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          _showHealthCertificateDialog(context, puppy);
                                        },
                                        icon: const Icon(Icons.medical_services, size: 18),
                                        label: const FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text('Helseattest'),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.success.withValues(alpha: ThemeOpacity.low(context)),
                                          foregroundColor: AppColors.success,
                                          side: const BorderSide(
                                            color: AppColors.success,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          _editPuppy(context, puppy);
                                        },
                                        icon: const Icon(Icons.edit, size: 18),
                                        label: const FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text('Rediger'),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: context.colors.surface,
                                          foregroundColor: Theme.of(
                                            context,
                                          ).primaryColor,
                                          side: BorderSide(
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          _sharePuppyUpdate(context, puppy);
                                        },
                                        icon: const Icon(Icons.share, size: 18),
                                        label: const FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text('Del'),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.info.withValues(alpha: ThemeOpacity.low(context)),
                                          foregroundColor: AppColors.info,
                                          side: const BorderSide(
                                            color: AppColors.info,
                                            width: 1.5,
                                          ),
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
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _buildTrackingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.lg, bottom: 88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Temperature Tracking Card
          if (widget.litter.damMatingDate != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Temperaturregistrering',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Registrer temperatur på tispa før estimert fødsel',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TemperatureTrackingScreen(
                                litter: widget.litter,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.thermostat),
                        label: const Text('Åpne temperaturlogg'),
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
          const SizedBox(height: AppSpacing.xl),

          // Puppies Weight Tracking
          Text('Valpenes vekt', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _showBulkWeightDialog(context);
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Registrer vekt for alle valper'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ValueListenableBuilder(
            valueListenable: Hive.box<Puppy>('puppies').listenable(),
            builder: (context, Box<Puppy> box, _) {
              final puppies = box.values
                  .where((p) => p.litterId == widget.litter.id)
                  .toList();

              if (puppies.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    border: Border.all(color: context.colors.divider),
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Center(
                    child: Text(
                      'Ingen valper registrert',
                      style: TextStyle(color: context.colors.textCaption),
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: puppies.length,
                itemBuilder: (context, index) {
                  final puppy = puppies[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: puppy.gender == 'Male'
                              ? AppColors.male.withValues(alpha: ThemeOpacity.medium(context))
                              : AppColors.female.withValues(alpha: ThemeOpacity.medium(context)),
                        ),
                        child: Icon(
                          Icons.scale,
                          size: 20,
                          color: puppy.gender == 'Male'
                              ? AppColors.male
                              : AppColors.female,
                        ),
                      ),
                      title: Text(puppy.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.show_chart),
                        onPressed: () {
                          _showWeightChart(context, puppy);
                        },
                      ),
                      onTap: () {
                        _showWeightChart(context, puppy);
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryTab() {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => GalleryScreen(litter: widget.litter),
        );
      },
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.colors.textDisabled,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...children,
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Sold':
        return AppColors.success;
      case 'Reserved':
        return AppColors.reserved;
      default:
        return AppColors.info;
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: AppSpacing.lg),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBoxWithIcon(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: ThemeOpacity.high(context)),
            color.withValues(alpha: ThemeOpacity.medium(context)),
          ],
        ),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.8),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  void _editPuppy(BuildContext context, Puppy puppy) {
    String selectedStatus = puppy.status ?? 'Available';
    bool vaccinated = puppy.vaccinated;
    bool dewormed = puppy.dewormed;
    bool microchipped = puppy.microchipped;
    TextEditingController buyerNameController = TextEditingController(
      text: puppy.buyerName,
    );
    TextEditingController buyerContactController = TextEditingController(
      text: puppy.buyerContact,
    );
    TextEditingController notesController = TextEditingController(
      text: puppy.notes,
    );
    TextEditingController birthWeightController = TextEditingController(
      text: puppy.birthWeight?.toString() ?? '',
    );
    TextEditingController birthNotesController = TextEditingController(
      text: puppy.birthNotes ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Rediger valp'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'Available', child: Text('Ledig')),
                    DropdownMenuItem(value: 'Sold', child: Text('Solgt')),
                    DropdownMenuItem(
                      value: 'Reserved',
                      child: Text('Reservert'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => selectedStatus = value ?? 'Available');
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: birthWeightController,
                  decoration: const InputDecoration(
                    labelText: 'Fødselsvekt (gram)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: birthNotesController,
                  decoration: const InputDecoration(
                    labelText: 'Fødselsmerknad',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.md),
                CheckboxListTile(
                  title: const Text('Vaksinert'),
                  value: vaccinated,
                  onChanged: (value) {
                    setState(() => vaccinated = value ?? false);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Avmasket'),
                  value: dewormed,
                  onChanged: (value) {
                    setState(() => dewormed = value ?? false);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Microchippet'),
                  value: microchipped,
                  onChanged: (value) {
                    setState(() => microchipped = value ?? false);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: buyerNameController,
                  decoration: const InputDecoration(labelText: 'Kjøpernavn'),
                ),
                TextFormField(
                  controller: buyerContactController,
                  decoration: const InputDecoration(labelText: 'Kjøperkontakt'),
                ),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notater'),
                  maxLines: 3,
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
              onPressed: () {
                puppy.status = selectedStatus;
                puppy.vaccinated = vaccinated;
                puppy.dewormed = dewormed;
                puppy.microchipped = microchipped;
                puppy.buyerName = buyerNameController.text;
                puppy.buyerContact = buyerContactController.text;
                puppy.notes = notesController.text;
                puppy.birthWeight = double.tryParse(birthWeightController.text);
                puppy.birthNotes = birthNotesController.text.isEmpty
                    ? null
                    : birthNotesController.text;
                puppy.save();
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Valp oppdatert')));
              },
              child: const Text('Lagre'),
            ),
          ],
        ),
      ),
    );
  }

  void _showWeightChart(BuildContext context, Puppy puppy) {
    final weightBox = Hive.box<PuppyWeightLog>('weight_logs');
    var logs = weightBox.values.where((log) => log.puppyId == puppy.id).toList()
      ..sort((a, b) => a.logDate.compareTo(b.logDate));

    // Legg til fødselssvekt som dag 0 hvis det finnes
    List<PuppyWeightLog> displayLogs = [];
    if (puppy.birthWeight != null && puppy.birthWeight! > 0) {
      final birthLog = PuppyWeightLog(
        id: 'birth_${puppy.id}',
        puppyId: puppy.id,
        logDate: puppy.dateOfBirth,
        weight: puppy.birthWeight!,
        notes: 'Fødselsvekt',
      );
      displayLogs.add(birthLog);
    }
    displayLogs.addAll(logs);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${puppy.name} - Vektkurve'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (displayLogs.isNotEmpty)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 350,
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: (displayLogs.length - 1).toDouble(),
                        minY:
                            displayLogs
                                .map((e) => e.weight)
                                .reduce((a, b) => a < b ? a : b) -
                            100,
                        maxY:
                            displayLogs
                                .map((e) => e.weight)
                                .reduce((a, b) => a > b ? a : b) +
                            100,
                        gridData: const FlGridData(
                          show: true,
                          drawHorizontalLine: true,
                          drawVerticalLine: false,
                          horizontalInterval: 100,
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: displayLogs.length > 10
                                  ? (displayLogs.length / 5).ceilToDouble()
                                  : 1,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < displayLogs.length) {
                                  if (index == 0 &&
                                      displayLogs[0].notes == 'Fødselsvekt') {
                                    return const Text(
                                      '0',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    );
                                  }
                                  final hours = displayLogs[index].logDate
                                      .difference(puppy.dateOfBirth)
                                      .inHours;
                                  final days = (hours / 24).ceil();
                                  return Text(
                                    '$days',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                            axisNameWidget: const Text(
                              'Dager siden fødsel',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            axisNameSize: 20,
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              interval: 200,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()} g',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.right,
                                );
                              },
                            ),
                            axisNameWidget: const Text(
                              'Gram',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            axisNameSize: 30,
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                            color: context.colors.divider,
                            width: 1,
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: displayLogs.asMap().entries.map((e) {
                              return FlSpot(e.key.toDouble(), e.value.weight);
                            }).toList(),
                            isCurved: true,
                            color: Theme.of(context).primaryColor,
                            barWidth: 3,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: Theme.of(context).primaryColor,
                                  strokeColor: Colors.white,
                                  strokeWidth: 2,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: ThemeOpacity.low(context)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (displayLogs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'Ingen vektmålinger eller fødselssvekt registrert',
                  ),
                )
              else
                const SizedBox(height: AppSpacing.lg),
              if (displayLogs.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Registrerte målinger:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        height: 150,
                        child: SingleChildScrollView(
                          child: Column(
                            children: displayLogs.map((log) {
                              final hours = log.logDate
                                  .difference(puppy.dateOfBirth)
                                  .inHours;
                              final days = (hours / 24).ceil();
                              return Container(
                                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: context.colors.neutral50,
                                  border: Border.all(color: context.colors.border),
                                  borderRadius: AppRadius.smAll,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${log.weight.toStringAsFixed(0)} gram',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            'Dag $days - ${DateFormat('dd.MM.yyyy').format(log.logDate)}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: context.colors.textDisabled,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (log.notes != null &&
                                        log.notes!.isNotEmpty)
                                      Flexible(
                                        child: Text(
                                          log.notes!,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: context.colors.textDisabled,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (log.notes != 'Fødselsvekt')
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              size: 16,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _editWeightLog(
                                                context,
                                                puppy,
                                                log,
                                              );
                                            },
                                          ),
                                        if (log.notes != 'Fødselsvekt')
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              size: 16,
                                              color: AppColors.error,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () async {
                                              // Delete from Firebase first
                                              final userId = AuthService()
                                                  .currentUser
                                                  ?.uid;
                                              if (userId != null) {
                                                await CloudSyncService()
                                                    .deleteWeightLog(
                                                      userId: userId,
                                                      litterId:
                                                          widget.litter.id,
                                                      puppyId: puppy.id,
                                                      logId: log.id,
                                                    );
                                              }
                                              // Then delete from Hive
                                              await log.delete();
                                              if (context.mounted) {
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Vektmåling slettet',
                                                    ),
                                                  ),
                                                );
                                              }
                                              setState(() {});
                                            },
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _addWeightLog(context, puppy);
            },
            child: const Text('Legg til måling'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Lukk'),
          ),
        ],
      ),
    );
  }

  void _addWeightLog(BuildContext context, Puppy puppy) {
    DateTime selectedDate = DateTime.now();
    final weightController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Legg til vektmåling'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Dato'),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(
                        () => selectedDate = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          selectedDate.hour,
                          selectedDate.minute,
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  title: const Text('Klokkeslett'),
                  subtitle: Text(DateFormat('HH:mm').format(selectedDate)),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedDate),
                    );
                    if (picked != null) {
                      setState(
                        () => selectedDate = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          picked.hour,
                          picked.minute,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Vekt (gram)'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  controller: weightController,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Notater'),
                  controller: notesController,
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
                final weightBox = Hive.box<PuppyWeightLog>('weight_logs');
                final log = PuppyWeightLog(
                  id: '${DateTime.now().millisecondsSinceEpoch}',
                  puppyId: puppy.id,
                  logDate: selectedDate,
                  weight: double.tryParse(weightController.text) ?? 0,
                  notes: notesController.text.isEmpty
                      ? null
                      : notesController.text,
                );
                await weightBox.put(log.id, log);

                // Save to Firebase
                final userId = AuthService().currentUser?.uid;
                if (userId != null) {
                  await CloudSyncService().saveWeightLog(
                    userId: userId,
                    litterId: widget.litter.id,
                    puppyId: puppy.id,
                    logId: log.id,
                    logData: log.toJson(),
                  );
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vektmåling lagt til')),
                  );
                }
              },
              child: const Text('Lagre'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkWeightDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    final puppies = Hive.box<Puppy>(
      'puppies',
    ).values.where((p) => p.litterId == widget.litter.id).toList();

    final Map<String, TextEditingController> weightControllers = {};
    final Map<String, TextEditingController> notesControllers = {};

    for (var puppy in puppies) {
      weightControllers[puppy.id] = TextEditingController();
      notesControllers[puppy.id] = TextEditingController();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Registrer vekt for alle valper'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Dato'),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(
                        () => selectedDate = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          selectedDate.hour,
                          selectedDate.minute,
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  title: const Text('Klokkeslett'),
                  subtitle: Text(DateFormat('HH:mm').format(selectedDate)),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedDate),
                    );
                    if (picked != null) {
                      setState(
                        () => selectedDate = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          picked.hour,
                          picked.minute,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                ...puppies.map(
                  (puppy) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            puppy.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Vekt (gram)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            controller: weightControllers[puppy.id],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Notater (valgfritt)',
                              border: OutlineInputBorder(),
                            ),
                            controller: notesControllers[puppy.id],
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                for (var controller in weightControllers.values) {
                  controller.dispose();
                }
                for (var controller in notesControllers.values) {
                  controller.dispose();
                }
              },
              child: const Text('Avbryt'),
            ),
            TextButton(
              onPressed: () async {
                final weightBox = Hive.box<PuppyWeightLog>('weight_logs');
                final userId = AuthService().currentUser?.uid;
                int savedCount = 0;

                for (var puppy in puppies) {
                  final weightText =
                      weightControllers[puppy.id]?.text.trim() ?? '';
                  if (weightText.isEmpty) continue;

                  final weight = double.tryParse(weightText);
                  if (weight == null || weight <= 0) continue;

                  final log = PuppyWeightLog(
                    id: '${DateTime.now().millisecondsSinceEpoch}_${puppy.id}',
                    puppyId: puppy.id,
                    logDate: selectedDate,
                    weight: weight,
                    notes: notesControllers[puppy.id]?.text.isEmpty ?? true
                        ? null
                        : notesControllers[puppy.id]?.text,
                  );
                  await weightBox.put(log.id, log);

                  // Save to Firebase
                  if (userId != null) {
                    await CloudSyncService().saveWeightLog(
                      userId: userId,
                      litterId: widget.litter.id,
                      puppyId: puppy.id,
                      logId: log.id,
                      logData: log.toJson(),
                    );
                  }

                  savedCount++;
                }

                if (context.mounted) {
                  Navigator.pop(context);
                }
                for (var controller in weightControllers.values) {
                  controller.dispose();
                }
                for (var controller in notesControllers.values) {
                  controller.dispose();
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$savedCount vektmålinger lagret')),
                  );
                }
              },
              child: const Text('Lagre alle'),
            ),
          ],
        ),
      ),
    );
  }

  void _editWeightLog(BuildContext context, Puppy puppy, PuppyWeightLog log) {
    DateTime selectedDate = log.logDate;
    final weightController = TextEditingController(text: log.weight.toString());
    final notesController = TextEditingController(text: log.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Rediger vektmåling'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Dato'),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(
                        () => selectedDate = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          selectedDate.hour,
                          selectedDate.minute,
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  title: const Text('Klokkeslett'),
                  subtitle: Text(DateFormat('HH:mm').format(selectedDate)),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedDate),
                    );
                    if (picked != null) {
                      setState(
                        () => selectedDate = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          picked.hour,
                          picked.minute,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Vekt (gram)'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  controller: weightController,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Notater'),
                  controller: notesController,
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
                log.logDate = selectedDate;
                log.weight =
                    double.tryParse(weightController.text) ?? log.weight;
                log.notes = notesController.text.isEmpty
                    ? null
                    : notesController.text;
                log.save();

                // Save to Firebase
                final userId = AuthService().currentUser?.uid;
                if (userId != null) {
                  await CloudSyncService().saveWeightLog(
                    userId: userId,
                    litterId: widget.litter.id,
                    puppyId: puppy.id,
                    logId: log.id,
                    logData: log.toJson(),
                  );
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vektmåling oppdatert')),
                  );
                  _showWeightChart(context, puppy);
                }
              },
              child: const Text('Lagre'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTreatmentPlan(BuildContext context, Puppy puppy) async {
    final box = Hive.box<TreatmentPlan>('treatment_plans');
    TreatmentPlan? treatmentPlan = box.values.cast<TreatmentPlan>().firstWhere(
      (tp) => tp.puppyId == puppy.id,
      orElse: () {
        final newPlan = TreatmentPlan(
          id: '${DateTime.now().millisecondsSinceEpoch}',
          puppyId: puppy.id,
        );
        box.add(newPlan);
        return newPlan;
      },
    );

    // Local state for dialog
    DateTime? wormerDate1 = treatmentPlan.wormerDate1;
    DateTime? wormerDate2 = treatmentPlan.wormerDate2;
    DateTime? wormerDate3 = treatmentPlan.wormerDate3;
    DateTime? vaccineDate1 = treatmentPlan.vaccineDate1;
    DateTime? vaccineDate2 = treatmentPlan.vaccineDate2;
    DateTime? vaccineDate3 = treatmentPlan.vaccineDate3;
    DateTime? microchipDate = treatmentPlan.microchipDate;
    String microchipNumber = treatmentPlan.microchipNumber ?? '';

    bool wormerDone1 = treatmentPlan.wormerDone1;
    bool wormerDone2 = treatmentPlan.wormerDone2;
    bool wormerDone3 = treatmentPlan.wormerDone3;
    bool vaccineDone1 = treatmentPlan.vaccineDone1;
    bool vaccineDone2 = treatmentPlan.vaccineDone2;
    bool vaccineDone3 = treatmentPlan.vaccineDone3;
    bool microchipDone = treatmentPlan.microchipDone;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          title: Text('${puppy.name} - Behandlingsplan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ormekur Section
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: const Text(
                    'Ormekur:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                _buildTreatmentTile(
                  context,
                  'ormekur 1',
                  '1. ormekur (ca. 2 uker)',
                  wormerDate1,
                  wormerDone1,
                  (date) => dialogSetState(() => wormerDate1 = date),
                  (done) => dialogSetState(() => wormerDone1 = done),
                ),
                _buildTreatmentTile(
                  context,
                  'ormekur 2',
                  '2. ormekur (ca. 4 uker)',
                  wormerDate2,
                  wormerDone2,
                  (date) => dialogSetState(() => wormerDate2 = date),
                  (done) => dialogSetState(() => wormerDone2 = done),
                ),
                _buildTreatmentTile(
                  context,
                  'ormekur 3',
                  '3. ormekur (ca. 6 uker)',
                  wormerDate3,
                  wormerDone3,
                  (date) => dialogSetState(() => wormerDate3 = date),
                  (done) => dialogSetState(() => wormerDone3 = done),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Vaksiner Section
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: const Text(
                    'Vaksiner:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                _buildTreatmentTile(
                  context,
                  'vaksin 1',
                  '1. vaksinering (8 uker)',
                  vaccineDate1,
                  vaccineDone1,
                  (date) => dialogSetState(() => vaccineDate1 = date),
                  (done) => dialogSetState(() => vaccineDone1 = done),
                ),
                _buildTreatmentTile(
                  context,
                  'vaksin 2',
                  '2. vaksinering (12 uker)',
                  vaccineDate2,
                  vaccineDone2,
                  (date) => dialogSetState(() => vaccineDate2 = date),
                  (done) => dialogSetState(() => vaccineDone2 = done),
                ),
                _buildTreatmentTile(
                  context,
                  'vaksin 3',
                  '3. vaksinering (16 uker)',
                  vaccineDate3,
                  vaccineDone3,
                  (date) => dialogSetState(() => vaccineDate3 = date),
                  (done) => dialogSetState(() => vaccineDone3 = done),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Annet Section
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: const Text(
                    'Annet:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                _buildTreatmentTile(
                  context,
                  'microchip',
                  'ID-merking',
                  microchipDate,
                  microchipDone,
                  (date) => dialogSetState(() => microchipDate = date),
                  (done) => dialogSetState(() => microchipDone = done),
                ),
                if (microchipDate != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'ID-merkenummer',
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.lgAll,
                        ),
                      ),
                      onChanged: (value) => microchipNumber = value,
                      controller: TextEditingController(text: microchipNumber),
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
            ElevatedButton(
              onPressed: () async {
                // Update treatment plan
                treatmentPlan.wormerDate1 = wormerDate1;
                treatmentPlan.wormerDate2 = wormerDate2;
                treatmentPlan.wormerDate3 = wormerDate3;
                treatmentPlan.vaccineDate1 = vaccineDate1;
                treatmentPlan.vaccineDate2 = vaccineDate2;
                treatmentPlan.vaccineDate3 = vaccineDate3;
                treatmentPlan.microchipDate = microchipDate;
                treatmentPlan.microchipNumber = microchipNumber;
                treatmentPlan.wormerDone1 = wormerDone1;
                treatmentPlan.wormerDone2 = wormerDone2;
                treatmentPlan.wormerDone3 = wormerDone3;
                treatmentPlan.vaccineDone1 = vaccineDone1;
                treatmentPlan.vaccineDone2 = vaccineDone2;
                treatmentPlan.vaccineDone3 = vaccineDone3;
                treatmentPlan.microchipDone = microchipDone;

                await treatmentPlan.save();

                // Schedule reminders
                final notificationService = NotificationService();
                if (wormerDate1 != null && !wormerDone1) {
                  await notificationService.scheduleWormerReminder(
                    id: puppy.id.hashCode + 1,
                    puppyName: puppy.name,
                    scheduleTime: wormerDate1!,
                  );
                }
                if (wormerDate2 != null && !wormerDone2) {
                  await notificationService.scheduleWormerReminder(
                    id: puppy.id.hashCode + 2,
                    puppyName: puppy.name,
                    scheduleTime: wormerDate2!,
                  );
                }
                if (wormerDate3 != null && !wormerDone3) {
                  await notificationService.scheduleWormerReminder(
                    id: puppy.id.hashCode + 3,
                    puppyName: puppy.name,
                    scheduleTime: wormerDate3!,
                  );
                }
                if (vaccineDate1 != null && !vaccineDone1) {
                  await notificationService.scheduleVaccineReminder(
                    id: puppy.id.hashCode + 4,
                    puppyName: puppy.name,
                    vaccineNumber: 1,
                    scheduleTime: vaccineDate1!,
                  );
                }
                if (vaccineDate2 != null && !vaccineDone2) {
                  await notificationService.scheduleVaccineReminder(
                    id: puppy.id.hashCode + 5,
                    puppyName: puppy.name,
                    vaccineNumber: 2,
                    scheduleTime: vaccineDate2!,
                  );
                }
                if (vaccineDate3 != null && !vaccineDone3) {
                  await notificationService.scheduleVaccineReminder(
                    id: puppy.id.hashCode + 6,
                    puppyName: puppy.name,
                    vaccineNumber: 3,
                    scheduleTime: vaccineDate3!,
                  );
                }
                if (microchipDate != null && !microchipDone) {
                  await notificationService.scheduleMicrochipReminder(
                    id: puppy.id.hashCode + 7,
                    puppyName: puppy.name,
                    scheduleTime: microchipDate!,
                  );
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Behandlingsplan oppdatert og varsler planlagt',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Lagre'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentTile(
    BuildContext context,
    String id,
    String title,
    DateTime? selectedDate,
    bool isDone,
    Function(DateTime?) onDateChanged,
    Function(bool) onDoneChanged,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Checkbox(
              value: isDone,
              onChanged: (value) => onDoneChanged(value ?? false),
            ),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, bottom: AppSpacing.sm),
          child: GestureDetector(
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime(2024),
                lastDate: DateTime(2030),
              );
              if (pickedDate != null) {
                onDateChanged(pickedDate);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                border: Border.all(color: context.colors.divider),
                borderRadius: AppRadius.lgAll,
              ),
              child: Text(
                selectedDate != null
                    ? DateFormat('dd.MM.yyyy').format(selectedDate)
                    : 'Velg dato',
                style: TextStyle(
                  color: selectedDate != null ? context.colors.textPrimary : context.colors.textCaption,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportPuppyPDF(BuildContext context, Puppy puppy) async {
    try {
      final pdf = await PDFGenerator.generatePuppyPackage(puppy, widget.litter);

      // Try to save to Downloads directory first, fall back to Documents
      late Directory directory;
      try {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory =
              await getExternalStorageDirectory() ??
              await getApplicationDocumentsDirectory();
        }
      } catch (e) {
        directory = await getApplicationDocumentsDirectory();
      }

      final fileName =
          'valp_${puppy.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Show download notification in status bar with file path
      await NotificationService().showDownloadNotification(
        title: 'PDF nedlastet',
        fileName: 'valp_${puppy.name}.pdf',
        filePath: file.path,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF lagret:\n${file.path}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Feil ved PDF-generering: $e')));
      }
    }
  }

  void _showHealthCertificateDialog(BuildContext context, Puppy puppy) {
    final vetNameController = TextEditingController();
    final vetClinicController = TextEditingController();
    final vetPhoneController = TextEditingController();
    final notesController = TextEditingController();
    
    // Helsesjekk-verdier med merknader
    final healthChecks = <String, Map<String, dynamic>>{
      'generalHealth': {'ok': true, 'note': '', 'label': 'Allmenntilstand'},
      'eyes': {'ok': true, 'note': '', 'label': 'Øyne'},
      'ears': {'ok': true, 'note': '', 'label': 'Ører'},
      'heart': {'ok': true, 'note': '', 'label': 'Hjerte'},
      'lungs': {'ok': true, 'note': '', 'label': 'Lunger'},
      'skin': {'ok': true, 'note': '', 'label': 'Hud/pels'},
      'teeth': {'ok': true, 'note': '', 'label': 'Tenner/munn'},
      'abdomen': {'ok': true, 'note': '', 'label': 'Buk (abdomen)'},
      'limbs': {'ok': true, 'note': '', 'label': 'Lemmer/ledd'},
    };
    
    // Controllers for notes
    final noteControllers = <String, TextEditingController>{};
    for (var key in healthChecks.keys) {
      noteControllers[key] = TextEditingController();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.medical_services, color: AppColors.success),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(child: Text('Helseattest')),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generer helseattest for ${puppy.name}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Helsesjekk-seksjon med ekspanderbare merknader
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: AppRadius.mdAll,
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.medical_services, color: AppColors.success, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Helseundersøkelse',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Trykk på et punkt for å legge til merknad',
                      style: TextStyle(fontSize: 11, color: context.colors.textCaption),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...healthChecks.entries.map((entry) => _buildHealthCheckItem(
                      key: entry.key,
                      label: entry.value['label'] as String,
                      isOk: entry.value['ok'] as bool,
                      noteController: noteControllers[entry.key]!,
                      onToggle: (v) => setDialogState(() {
                        healthChecks[entry.key]!['ok'] = v ?? true;
                      }),
                      onNoteChanged: (note) {
                        healthChecks[entry.key]!['note'] = note;
                      },
                      setDialogState: setDialogState,
                    )),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              Text(
                'Veterinærinformasjon (valgfritt):',
                style: TextStyle(
                  fontSize: 12,
                  color: context.colors.textDisabled,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: vetNameController,
                decoration: const InputDecoration(
                  labelText: 'Veterinærens navn',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: vetClinicController,
                decoration: const InputDecoration(
                  labelText: 'Klinikk',
                  prefixIcon: Icon(Icons.local_hospital),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: vetPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Generelle merknader',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _generateHealthCertificate(
                context,
                puppy,
                vetName: vetNameController.text.trim(),
                vetClinic: vetClinicController.text.trim(),
                vetPhone: vetPhoneController.text.trim(),
                healthNotes: notesController.text.trim(),
                generalHealthOk: healthChecks['generalHealth']!['ok'] as bool,
                eyesOk: healthChecks['eyes']!['ok'] as bool,
                earsOk: healthChecks['ears']!['ok'] as bool,
                heartOk: healthChecks['heart']!['ok'] as bool,
                lungsOk: healthChecks['lungs']!['ok'] as bool,
                skinOk: healthChecks['skin']!['ok'] as bool,
                teethOk: healthChecks['teeth']!['ok'] as bool,
                abdomenOk: healthChecks['abdomen']!['ok'] as bool,
                limbsOk: healthChecks['limbs']!['ok'] as bool,
                healthCheckNotes: {
                  for (var entry in healthChecks.entries)
                    entry.key: noteControllers[entry.key]!.text.trim(),
                },
              );
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Generer PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    ),
    );
  }
  
  Widget _buildHealthCheckItem({
    required String key,
    required String label,
    required bool isOk,
    required TextEditingController noteController,
    required ValueChanged<bool?> onToggle,
    required ValueChanged<String> onNoteChanged,
    required StateSetter setDialogState,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: isOk,
              onChanged: onToggle,
              activeColor: AppColors.success,
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => onToggle(!isOk),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: isOk ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Icon(
              isOk ? Icons.check_circle : Icons.warning,
              color: isOk ? AppColors.success : AppColors.warning,
              size: 20,
            ),
          ],
        ),
        if (!isOk || noteController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 40, right: AppSpacing.sm, bottom: AppSpacing.sm),
            child: TextField(
              controller: noteController,
              decoration: InputDecoration(
                hintText: 'Legg til merknad for $label...',
                hintStyle: TextStyle(fontSize: 12, color: context.colors.textDisabled),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.mdAll,
                  borderSide: BorderSide(color: AppColors.warning.withValues(alpha: 0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.mdAll,
                  borderSide: BorderSide(color: AppColors.warning.withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.mdAll,
                  borderSide: BorderSide(color: AppColors.warning, width: 2),
                ),
                filled: true,
                fillColor: AppColors.warning.withValues(alpha: 0.1),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              ),
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
              onChanged: onNoteChanged,
            ),
          ),
        const Divider(height: 1),
      ],
    );
  }

  Future<void> _generateHealthCertificate(
    BuildContext context,
    Puppy puppy, {
    String vetName = '',
    String vetClinic = '',
    String vetPhone = '',
    String healthNotes = '',
    bool generalHealthOk = true,
    bool eyesOk = true,
    bool earsOk = true,
    bool heartOk = true,
    bool lungsOk = true,
    bool skinOk = true,
    bool teethOk = true,
    bool abdomenOk = true,
    bool limbsOk = true,
    Map<String, String>? healthCheckNotes,
  }) async {
    try {
      final pdf = await PDFGenerator.generateHealthCertificate(
        puppy,
        widget.litter,
        vetName: vetName,
        vetClinic: vetClinic,
        vetPhone: vetPhone,
        healthNotes: healthNotes,
        generalHealthOk: generalHealthOk,
        eyesOk: eyesOk,
        earsOk: earsOk,
        heartOk: heartOk,
        lungsOk: lungsOk,
        skinOk: skinOk,
        teethOk: teethOk,
        abdomenOk: abdomenOk,
        limbsOk: limbsOk,
        healthCheckNotes: healthCheckNotes,
      );

      // Try to save to Downloads directory first, fall back to Documents
      late Directory directory;
      try {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory =
              await getExternalStorageDirectory() ??
              await getApplicationDocumentsDirectory();
        }
      } catch (e) {
        directory = await getApplicationDocumentsDirectory();
      }

      final fileName =
          'helseattest_${puppy.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Show download notification
      await NotificationService().showDownloadNotification(
        title: 'Helseattest nedlastet',
        fileName: 'helseattest_${puppy.name}.pdf',
        filePath: file.path,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Helseattest lagret:\n${file.path}'),
            duration: const Duration(seconds: 4),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Feil ved generering av helseattest: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _sharePuppyUpdate(BuildContext context, Puppy puppy) {
    final messageController = TextEditingController();
    bool includeWeight = true;
    bool includeTreatments = true;
    bool includeAge = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.share, color: AppColors.info),
              const SizedBox(width: AppSpacing.sm),
              const Text('Del oppdatering'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Del oppdatering om ${puppy.name} med kjøper',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Inkluder i meldingen:',
                  style: TextStyle(fontSize: 12, color: context.colors.textDisabled),
                ),
                CheckboxListTile(
                  title: const Text('Alder'),
                  value: includeAge,
                  onChanged: (v) => setState(() => includeAge = v ?? true),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                CheckboxListTile(
                  title: const Text('Vekt'),
                  value: includeWeight,
                  onChanged: (v) => setState(() => includeWeight = v ?? true),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                CheckboxListTile(
                  title: const Text('Behandlinger'),
                  value: includeTreatments,
                  onChanged: (v) => setState(() => includeTreatments = v ?? true),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Egen melding (valgfritt)',
                    hintText: 'Skriv en personlig hilsen...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Avbryt'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                final shareService = ShareService();
                final message = shareService.generatePuppyUpdateMessage(
                  puppy,
                  widget.litter,
                  customMessage: messageController.text.trim().isNotEmpty
                      ? messageController.text.trim()
                      : null,
                  includeWeight: includeWeight,
                  includeTreatments: includeTreatments,
                  includeAge: includeAge,
                );
                
                // Show share options
                shareService.showShareOptionsDialog(
                  context,
                  message: message,
                  phoneNumber: puppy.buyerContact,
                  subject: 'Oppdatering om ${puppy.name}',
                );
              },
              icon: const Icon(Icons.send),
              label: const Text('Del'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editLitter(BuildContext context) {
    TextEditingController damController = TextEditingController(
      text: widget.litter.damName,
    );
    TextEditingController sireController = TextEditingController(
      text: widget.litter.sireName,
    );
    TextEditingController breedController = TextEditingController(
      text: widget.litter.breed,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rediger kull'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: damController,
                decoration: const InputDecoration(labelText: 'Mor (Tispe) *'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: sireController,
                decoration: const InputDecoration(
                  labelText: 'Far (Hannhund) *',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: breedController,
                decoration: const InputDecoration(labelText: 'Rase'),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Antall valper (basert på registrerte valper):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Hanner'),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            border: Border.all(color: context.colors.textDisabled),
                            borderRadius: AppRadius.xsAll,
                          ),
                          child: Center(
                            child: Text(
                              '${widget.litter.getActualMalesCountFromPuppies()}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Tisper'),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            border: Border.all(color: context.colors.textDisabled),
                            borderRadius: AppRadius.xsAll,
                          ),
                          child: Center(
                            child: Text(
                              '${widget.litter.getActualFemalesCountFromPuppies()}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: ThemeOpacity.low(context)),
                  borderRadius: AppRadius.xsAll,
                ),
                child: const Text(
                  'Disse tallene oppdateres automatisk når du legger til eller sletter valper.',
                  style: TextStyle(fontSize: 12),
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
          TextButton(
            onPressed: () {
              if (damController.text.isEmpty || sireController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mor og Far er påkrevd')),
                );
                return;
              }

              widget.litter.damName = damController.text;
              widget.litter.sireName = sireController.text;
              widget.litter.breed = breedController.text;
              widget.litter.save();

              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Kull oppdatert')));
            },
            child: const Text('Lagre'),
          ),
        ],
      ),
    );
  }

  void _deleteLitter(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slett kull?'),
        content: Text(
          'Er du sikker på at du vil slette kullet fra ${widget.litter.damName} x ${widget.litter.sireName}?\n\nOBS: Dette vil også slette alle valper i kullet!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () async {
              final userId = AuthService().currentUserId;

              // Slett alle valper i kullet først
              final puppyBox = Hive.box<Puppy>('puppies');
              final puppiesToDelete = puppyBox.values
                  .where((p) => p.litterId == widget.litter.id)
                  .toList();
              for (var puppy in puppiesToDelete) {
                // Slett fra Firebase
                if (userId != null) {
                  try {
                    await CloudSyncService().deletePuppy(
                      userId: userId,
                      litterId: widget.litter.id,
                      puppyId: puppy.id,
                    );
                  } catch (e) {
                    // Ignorer Firebase-feil
                  }
                }
                // Slett fra Hive
                await puppy.delete();
              }

              // Slett kullet fra Firebase
              if (userId != null) {
                try {
                  await CloudSyncService().deleteLitter(
                    userId: userId,
                    litterId: widget.litter.id,
                  );
                } catch (e) {
                  // Ignorer Firebase-feil
                }
              }

              // Slett kullet fra Hive
              await widget.litter.delete();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Kull slettet')));
              }
            },
            child: const Text('Slett'),
          ),
        ],
      ),
    );
  }

  void _showAddPuppyDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPuppyScreen(litter: widget.litter),
      ),
    );
  }
}
