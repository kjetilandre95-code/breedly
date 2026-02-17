import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:breedly/models/dog.dart';
import 'package:breedly/models/health.dart';
import 'package:breedly/models/vaccine.dart';
import 'package:breedly/models/progesterone_measurement.dart';
import 'package:breedly/models/vet_visit.dart';
import 'package:breedly/models/medical_treatment.dart';
import 'package:breedly/models/dna_test.dart';
import 'package:breedly/models/weight_record.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:breedly/utils/app_bar_builder.dart';
import 'package:breedly/utils/page_info_helper.dart';
import 'package:breedly/services/auth_service.dart';
import 'package:breedly/services/cloud_sync_service.dart';
import 'package:breedly/services/reminder_manager.dart';
import 'package:breedly/utils/logger.dart';
import 'package:breedly/services/offline_mode_manager.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/utils/theme_colors.dart';

class DogHealthScreen extends StatefulWidget {
  final Dog dog;

  const DogHealthScreen({super.key, required this.dog});

  @override
  State<DogHealthScreen> createState() => _DogHealthScreenState();
}

class _DogHealthScreenState extends State<DogHealthScreen> {
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBarBuilder.buildAppBar(
          title: 'Helse - ${widget.dog.name}',
          context: context,
          actions: [
            PageInfoHelper.buildInfoButton(
              context,
              title: PageInfoContent.dogHealth.title,
              description: PageInfoContent.dogHealth.description,
              features: PageInfoContent.dogHealth.features,
              tip: PageInfoContent.dogHealth.tip,
            ),
          ],
          bottom: TabBar(
            indicatorColor: primaryColor,
            labelColor: primaryColor,
            unselectedLabelColor: context.colors.textMuted,
            indicatorWeight: 3,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Helsestatus'),
              Tab(text: 'Vaksiner'),
              Tab(text: 'Veterinær'),
              Tab(text: 'Behandlinger'),
              Tab(text: 'DNA-tester'),
              Tab(text: 'Vekt'),
              Tab(text: 'Hormoner'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              _buildHealthStatusTab(),
              _buildVaccinesTab(),
              _buildVetVisitsTab(),
              _buildTreatmentsTab(),
              _buildDnaTestsTab(),
              _buildWeightTab(),
              _buildHormonesTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthStatusTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.lg, bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Helseopplysninger',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (widget.dog.healthInfoId != null)
            _buildHealthCard()
          else
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.15),
                      borderRadius: AppRadius.xlAll,
                    ),
                    child: Icon(
                      Icons.medical_information_outlined,
                      size: 72,
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Ingen helseopplysninger registrert',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Legg til helseopplysninger for ${widget.dog.name}',
                    style: TextStyle(color: context.colors.textMuted, fontSize: 14),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton.icon(
                    onPressed: _addHealthInfo,
                    icon: const Icon(Icons.add),
                    label: const Text('Legg til helseopplysninger'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: context.colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHealthCard() {
    final healthBox = Hive.box<HealthInfo>('health_info');
    final health = healthBox.get(widget.dog.healthInfoId!);

    if (health == null) {
      return Text('Helseopplysninger ikke funnet');
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.lgAll,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [context.colors.surface, context.colors.neutral50],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.15),
                      borderRadius: AppRadius.mdAll,
                    ),
                    child: Icon(
                      Icons.health_and_safety_rounded,
                      color: Theme.of(context).primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Helsestatus',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              if (health.hdStatus != null) ...[
                _buildHealthInfoRow(
                  'HD Status',
                  health.hdStatus!,
                  health.hdDate,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (health.adStatus != null) ...[
                _buildADStatusRow('AD Status', health.adStatus!, health.adDate),
                const SizedBox(height: AppSpacing.md),
              ],
              if (health.patellaStatus != null) ...[
                _buildPatellaStatusRow(
                  'Patella Status',
                  health.patellaStatus!,
                  health.patellaDate,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (health.notes != null && health.notes!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.12),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Merknader',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        health.notes!,
                        style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              const Divider(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _editHealthInfo(health),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Rediger'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: context.colors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _deleteHealthInfo(health),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Slett'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error.withValues(alpha: 0.1),
                        foregroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthInfoRow(String label, String value, DateTime? date) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.neutral50,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: context.colors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.colors.textTertiary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).primaryColor,
              letterSpacing: 0.3,
            ),
          ),
          if (date != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Dato: ${DateFormat('dd.MM.yyyy').format(date)}',
              style: TextStyle(color: context.colors.textCaption, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildADStatusRow(String label, int value, DateTime? date) {
    final adStatusLabels = {0: 'Grad 0 (Fri)', 1: 'Grad 1 (Svak)', 2: 'Grad 2 (Moderat)', 3: 'Grad 3 (Sterk)'};
    final statusText = adStatusLabels[value] ?? 'Ukjent';
    final statusColor = value == 0
        ? AppColors.success
        : value == 1
        ? AppColors.accent3
        : value == 2
        ? AppColors.warning
        : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.colors.textTertiary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          if (date != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Dato: ${DateFormat('dd.MM.yyyy').format(date)}',
              style: TextStyle(color: context.colors.textCaption, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPatellaStatusRow(String label, String value, DateTime? date) {
    // Konverter gammel eller ny verdi til numerisk
    int? numericValue;
    if (int.tryParse(value) != null) {
      numericValue = int.parse(value);
    } else {
      // Konverter gamle verdier
      switch (value) {
        case 'Normal': numericValue = 0; break;
        case 'Grade 1': numericValue = 1; break;
        case 'Grade 2': numericValue = 2; break;
        case 'Grade 3': numericValue = 3; break;
        case 'Grade 4': numericValue = 3; break;
        default: numericValue = null;
      }
    }
    
    final patellaStatusLabels = {0: 'Grad 0 (Normal)', 1: 'Grad 1', 2: 'Grad 2', 3: 'Grad 3'};
    final statusText = numericValue != null ? patellaStatusLabels[numericValue] ?? value : value;
    final statusColor = numericValue == 0
        ? AppColors.success
        : numericValue == 1
            ? AppColors.accent3
            : numericValue == 2
                ? AppColors.warning
                : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: (statusColor).withValues(alpha: 0.15),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: (statusColor).withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.colors.textTertiary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (date != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Dato: ${DateFormat('dd.MM.yyyy').format(date)}',
              style: TextStyle(color: context.colors.textCaption, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVaccinesTab() {
    final vaccineBox = Hive.box<Vaccine>('vaccines');
    final vaccineIds = widget.dog.vaccineIds ?? [];
    final vaccines = vaccineIds
        .map((id) => vaccineBox.get(id))
        .whereType<Vaccine>()
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.lg, bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vaksiner',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: _addVaccine,
                tooltip: 'Legg til vaksin',
                icon: Icon(Icons.add, color: Theme.of(context).primaryColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (vaccines.isEmpty)
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: AppRadius.xlAll,
                    ),
                    child: Icon(
                      Icons.vaccines_outlined,
                      size: 72,
                      color: AppColors.success.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Ingen vaksiner registrert',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Legg til vaksiner for ${widget.dog.name}',
                    style: TextStyle(color: context.colors.textMuted, fontSize: 14),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vaccines.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final vaccine = vaccines[index];
                final isOverdue = vaccine.isOverdue();
                final isDueForReminder = vaccine.isDueForReminder();

                return Card(
                  elevation: isOverdue ? 4 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.lgAll,
                    side: BorderSide(
                      color: isOverdue
                          ? AppColors.error
                          : isDueForReminder
                          ? AppColors.warning
                          : Colors.transparent,
                      width: (isOverdue || isDueForReminder) ? 2 : 0,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.lgAll,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          isOverdue
                              ? AppColors.error.withValues(alpha: 0.12)
                              : isDueForReminder
                              ? AppColors.warning.withValues(alpha: 0.12)
                              : context.colors.surface,
                          context.colors.neutral50,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row with vaccine name and status badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vaccine.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                            letterSpacing: 0.2,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'Tatt: ${DateFormat('dd.MM.yyyy').format(vaccine.dateTaken)}',
                                      style: TextStyle(
                                        color: context.colors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isOverdue)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(alpha: 0.2),
                                    border: Border.all(
                                      color: AppColors.error.withValues(alpha: 0.5),
                                    ),
                                    borderRadius: AppRadius.smAll,
                                  ),
                                  child: Text(
                                    'Forfalt',
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                              else if (isDueForReminder)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withValues(alpha: 0.2),
                                    border: Border.all(
                                      color: AppColors.warning.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    borderRadius: AppRadius.smAll,
                                  ),
                                  child: Text(
                                    'Varsel',
                                    style: TextStyle(
                                      color: AppColors.warning,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.2),
                                    border: Border.all(
                                      color: AppColors.success.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    borderRadius: AppRadius.smAll,
                                  ),
                                  child: Text(
                                    'OK',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Next due date info
                          if (vaccine.nextDueDate != null)
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.info.withValues(alpha: 0.12),
                                borderRadius: AppRadius.smAll,
                                border: Border.all(
                                  color: AppColors.info.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 16,
                                    color: AppColors.info,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'Neste dose: ${DateFormat('dd.MM.yyyy').format(vaccine.nextDueDate!)}',
                                    style: TextStyle(
                                      color: AppColors.info,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (vaccine.veterinarian != null &&
                              vaccine.veterinarian!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.accent5.withValues(alpha: 0.12),
                                borderRadius: AppRadius.smAll,
                                border: Border.all(
                                  color: AppColors.accent5.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person_rounded,
                                    size: 16,
                                    color: AppColors.accent5,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      'Veterinær: ${vaccine.veterinarian!}',
                                      style: TextStyle(
                                        color: AppColors.accent5,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          // Action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _editVaccine(vaccine),
                                  icon: const Icon(Icons.edit_rounded),
                                  label: const Text('Rediger'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).primaryColor,
                                    foregroundColor: context.colors.textPrimary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.md,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _deleteVaccine(vaccine),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                  ),
                                  label: const Text('Slett'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error.withValues(
                                      alpha: 0.1,
                                    ),
                                    foregroundColor: AppColors.error,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.md,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHormonesTab() {
    final progesteroneBox = Hive.box<ProgesteroneMeasurement>(
      'progesterone_measurements',
    );
    final measurements =
        progesteroneBox.values.where((m) => m.dogId == widget.dog.id).toList()
          ..sort((a, b) => b.dateMeasured.compareTo(a.dateMeasured));

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.lg, bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progesteronmålinger',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: _addProgesteroneMeasurement,
                tooltip: 'Legg til måling',
                icon: Icon(Icons.add, color: Theme.of(context).primaryColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (measurements.isEmpty)
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.2),
                      borderRadius: AppRadius.xlAll,
                    ),
                    child: Icon(
                      Icons.science_outlined,
                      size: 72,
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Ingen progesteronmålinger registrert',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Legg til progesteronmålinger for å følge ${widget.dog.name}s syklus',
                    style: TextStyle(color: context.colors.textMuted, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...measurements.map(
              (measurement) => _buildProgesteroneCard(measurement),
            ),
        ],
      ),
    );
  }

  Widget _buildProgesteroneCard(ProgesteroneMeasurement measurement) {
    final interpretation = measurement.getInterpretation();
    Color statusColor;

    if (measurement.value < 2.0) {
      statusColor = AppColors.neutral500;
    } else if (measurement.value >= 2.0 && measurement.value < 5.0) {
      statusColor = AppColors.warning;
    } else if (measurement.value >= 5.0 && measurement.value < 10.0) {
      statusColor = AppColors.success;
    } else {
      statusColor = AppColors.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Icon(Icons.science, color: statusColor, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${measurement.value.toStringAsFixed(1)} ng/mL',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        interpretation,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('Rediger'),
                      onTap: () => Future.delayed(
                        Duration.zero,
                        () => _editProgesteroneMeasurement(measurement),
                      ),
                    ),
                    PopupMenuItem(
                      child: const Text(
                        'Slett',
                        style: TextStyle(color: AppColors.error),
                      ),
                      onTap: () => Future.delayed(
                        Duration.zero,
                        () => _deleteProgesteroneMeasurement(measurement),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Dato: ${DateFormat('dd.MM.yyyy HH:mm').format(measurement.dateMeasured)}',
              style: TextStyle(color: context.colors.textMuted, fontSize: 12),
            ),
            if (measurement.veterinarian != null &&
                measurement.veterinarian!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Veterinær: ${measurement.veterinarian}',
                style: TextStyle(color: context.colors.textMuted, fontSize: 12),
              ),
            ],
            if (measurement.notes != null && measurement.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(measurement.notes!, style: const TextStyle(fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }

  void _addProgesteroneMeasurement() {
    showDialog(
      context: context,
      builder: (context) => _ProgesteroneDialog(dog: widget.dog),
    ).then((_) => setState(() {}));
  }

  void _editProgesteroneMeasurement(ProgesteroneMeasurement measurement) {
    showDialog(
      context: context,
      builder: (context) =>
          _ProgesteroneDialog(dog: widget.dog, measurement: measurement),
    ).then((_) => setState(() {}));
  }

  void _deleteProgesteroneMeasurement(ProgesteroneMeasurement measurement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slett måling?'),
        content: const Text(
          'Er du sikker på at du vil slette denne progesteronmålingen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () async {
              // Slett fra Firebase først
              final userId = AuthService().currentUserId;
              if (userId != null) {
                try {
                  await CloudSyncService().deleteProgesteroneMeasurement(
                    userId: userId,
                    dogId: widget.dog.id,
                    measurementId: measurement.id,
                  );
                } catch (e) {
                  // Ignorer Firebase-feil
                }
              }
              // Slett fra Hive
              await measurement.delete();
              if (context.mounted) Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Slett', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _addHealthInfo() {
    showDialog(
      context: context,
      builder: (context) => _HealthInfoDialog(dog: widget.dog),
    ).then((_) => setState(() {}));
  }

  void _editHealthInfo(HealthInfo health) {
    showDialog(
      context: context,
      builder: (context) => _HealthInfoDialog(dog: widget.dog, health: health),
    ).then((_) => setState(() {}));
  }

  void _deleteHealthInfo(HealthInfo health) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slett helseopplysninger?'),
        content: const Text(
          'Er du sikker på at du vil slette disse helseopplysningene?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () async {
              // Slett fra Firebase først
              final userId = AuthService().currentUserId;
              if (userId != null) {
                try {
                  await CloudSyncService().deleteHealthInfo(
                    userId: userId,
                    dogId: widget.dog.id,
                    healthInfoId: health.id,
                  );
                } catch (e) {
                  // Ignorer Firebase-feil
                }
              }
              // Slett fra Hive
              await health.delete();
              widget.dog.healthInfoId = null;
              await widget.dog.save();
              if (context.mounted) Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Slett', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _addVaccine() {
    showDialog(
      context: context,
      builder: (context) => _VaccineDialog(dog: widget.dog),
    ).then((_) => setState(() {}));
  }

  void _editVaccine(Vaccine vaccine) {
    showDialog(
      context: context,
      builder: (context) => _VaccineDialog(dog: widget.dog, vaccine: vaccine),
    ).then((_) => setState(() {}));
  }

  void _deleteVaccine(Vaccine vaccine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slett vaksin?'),
        content: Text('Er du sikker på at du vil slette ${vaccine.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () async {
              // Slett fra Firebase først
              final userId = AuthService().currentUserId;
              if (userId != null) {
                try {
                  await CloudSyncService().deleteVaccine(
                    userId: userId,
                    dogId: widget.dog.id,
                    vaccineId: vaccine.id,
                  );
                } catch (e) {
                  // Ignorer Firebase-feil
                }
              }
              // Slett fra Hive
              await vaccine.delete();
              widget.dog.vaccineIds?.remove(vaccine.id);
              await widget.dog.save();
              if (context.mounted) Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Slett', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  // ==================== VET VISITS TAB ====================
  Widget _buildVetVisitsTab() {
    final vetVisitsBox = Hive.box<VetVisit>('vet_visits');
    final visits =
        vetVisitsBox.values.where((v) => v.dogId == widget.dog.id).toList()
          ..sort((a, b) => b.visitDate.compareTo(a.visitDate));

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.lg, bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Veterinærbesøk',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: _addVetVisit,
                tooltip: 'Legg til besøk',
                icon: Icon(Icons.add, color: Theme.of(context).primaryColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (visits.isEmpty)
            _buildEmptyState(
              icon: Icons.local_hospital_outlined,
              title: 'Ingen veterinærbesøk registrert',
              subtitle: 'Legg til veterinærbesøk for ${widget.dog.name}',
            )
          else
            ...visits.map((visit) => _buildVetVisitCard(visit)),
        ],
      ),
    );
  }

  Widget _buildVetVisitCard(VetVisit visit) {
    final visitTypeLabels = {
      'routine': 'Rutinekontroll',
      'emergency': 'Akutt',
      'surgery': 'Operasjon',
      'vaccination': 'Vaksinering',
      'followup': 'Oppfølging',
      'other': 'Annet',
    };

    Color typeColor;
    switch (visit.visitType) {
      case 'emergency':
        typeColor = AppColors.error;
        break;
      case 'surgery':
        typeColor = AppColors.accent5;
        break;
      case 'vaccination':
        typeColor = AppColors.info;
        break;
      case 'routine':
        typeColor = AppColors.success;
        break;
      case 'followup':
        typeColor = AppColors.warning;
        break;
      default:
        typeColor = AppColors.neutral500;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Icon(Icons.local_hospital, color: typeColor, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visitTypeLabels[visit.visitType] ?? visit.visitType,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('dd.MM.yyyy').format(visit.visitDate),
                        style: TextStyle(color: context.colors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('Rediger'),
                      onTap: () => Future.delayed(
                        Duration.zero,
                        () => _editVetVisit(visit),
                      ),
                    ),
                    PopupMenuItem(
                      child: const Text(
                        'Slett',
                        style: TextStyle(color: AppColors.error),
                      ),
                      onTap: () => Future.delayed(
                        Duration.zero,
                        () => _deleteVetVisit(visit),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (visit.reason != null && visit.reason!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Årsak: ${visit.reason}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (visit.diagnosis != null && visit.diagnosis!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Diagnose: ${visit.diagnosis}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (visit.treatment != null && visit.treatment!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Behandling: ${visit.treatment}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (visit.veterinarian != null &&
                visit.veterinarian!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Veterinær: ${visit.veterinarian}',
                style: TextStyle(color: context.colors.textMuted, fontSize: 12),
              ),
            ],
            if (visit.cost != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Kostnad: ${visit.cost!.toStringAsFixed(0)} kr',
                style: TextStyle(color: context.colors.textMuted, fontSize: 12),
              ),
            ],
            if (visit.followUpDate != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: AppRadius.xsAll,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event, size: 14, color: AppColors.warning),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Oppfølging: ${DateFormat('dd.MM.yyyy').format(visit.followUpDate!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.warning,
                      ),
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

  void _addVetVisit() {
    showDialog(
      context: context,
      builder: (context) => _VetVisitDialog(dog: widget.dog),
    ).then((_) => setState(() {}));
  }

  void _editVetVisit(VetVisit visit) {
    showDialog(
      context: context,
      builder: (context) => _VetVisitDialog(dog: widget.dog, visit: visit),
    ).then((_) => setState(() {}));
  }

  void _deleteVetVisit(VetVisit visit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slett veterinærbesøk?'),
        content: const Text('Er du sikker på at du vil slette dette besøket?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () async {
              // Kanseller påminnelse om oppfølging
              await ReminderManager().cancelVetVisitFollowUpReminder(visit.id);
              // Slett fra Firebase først
              final userId = AuthService().currentUserId;
              if (userId != null) {
                try {
                  await CloudSyncService().deleteVetVisit(
                    userId: userId,
                    dogId: widget.dog.id,
                    visitId: visit.id,
                  );
                } catch (e) {
                  AppLogger.debug(
                    'Feil ved sletting av veterinærbesøk fra Firebase: $e',
                  );
                }
              }
              // Slett fra Hive
              await visit.delete();
              if (context.mounted) Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Slett', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  // ==================== TREATMENTS TAB ====================
  Widget _buildTreatmentsTab() {
    final treatmentsBox = Hive.box<MedicalTreatment>('medical_treatments');
    final treatments =
        treatmentsBox.values.where((t) => t.dogId == widget.dog.id).toList()
          ..sort((a, b) => b.dateGiven.compareTo(a.dateGiven));

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.lg, bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Behandlinger',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: _addTreatment,
                tooltip: 'Legg til behandling',
                icon: Icon(Icons.add, color: Theme.of(context).primaryColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (treatments.isEmpty)
            _buildEmptyState(
              icon: Icons.medication_outlined,
              title: 'Ingen behandlinger registrert',
              subtitle: 'Legg til ormebehandlinger, lopper/flått osv.',
            )
          else
            ...treatments.map((treatment) => _buildTreatmentCard(treatment)),
        ],
      ),
    );
  }

  Widget _buildTreatmentCard(MedicalTreatment treatment) {
    final typeLabels = {
      'deworming': 'Ormekur',
      'flea': 'Loppebehandling',
      'tick': 'Flåttbehandling',
      'medication': 'Medisin',
      'supplement': 'Kosttilskudd',
      'other': 'Annet',
    };

    IconData typeIcon;
    Color typeColor;
    switch (treatment.treatmentType) {
      case 'deworming':
        typeIcon = Icons.bug_report;
        typeColor = AppColors.accent4;
        break;
      case 'flea':
        typeIcon = Icons.pest_control;
        typeColor = AppColors.warning;
        break;
      case 'tick':
        typeIcon = Icons.pest_control_rodent;
        typeColor = AppColors.error;
        break;
      case 'medication':
        typeIcon = Icons.medication;
        typeColor = AppColors.info;
        break;
      case 'supplement':
        typeIcon = Icons.local_pharmacy;
        typeColor = AppColors.success;
        break;
      default:
        typeIcon = Icons.healing;
        typeColor = AppColors.neutral500;
    }

    final isDue =
        treatment.nextDueDate != null &&
        treatment.nextDueDate!.isBefore(
          DateTime.now().add(const Duration(days: 7)),
        );

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        treatment.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        typeLabels[treatment.treatmentType] ??
                            treatment.treatmentType,
                        style: TextStyle(color: context.colors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('Rediger'),
                      onTap: () => Future.delayed(
                        Duration.zero,
                        () => _editTreatment(treatment),
                      ),
                    ),
                    PopupMenuItem(
                      child: const Text('Registrer ny dose'),
                      onTap: () => Future.delayed(
                        Duration.zero,
                        () => _registerNewDose(treatment),
                      ),
                    ),
                    PopupMenuItem(
                      child: const Text(
                        'Slett',
                        style: TextStyle(color: AppColors.error),
                      ),
                      onTap: () => Future.delayed(
                        Duration.zero,
                        () => _deleteTreatment(treatment),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Sist gitt: ${DateFormat('dd.MM.yyyy').format(treatment.dateGiven)}',
              style: TextStyle(color: context.colors.textMuted, fontSize: 12),
            ),
            if (treatment.dosage != null && treatment.dosage!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Dosering: ${treatment.dosage}',
                style: TextStyle(color: context.colors.textMuted, fontSize: 12),
              ),
            ],
            if (treatment.manufacturer != null &&
                treatment.manufacturer!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Produsent: ${treatment.manufacturer}',
                style: TextStyle(color: context.colors.textMuted, fontSize: 12),
              ),
            ],
            if (treatment.nextDueDate != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: isDue
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.success.withValues(alpha: 0.1),
                  borderRadius: AppRadius.xsAll,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDue ? Icons.warning : Icons.schedule,
                      size: 14,
                      color: isDue ? AppColors.error : AppColors.success,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Neste: ${DateFormat('dd.MM.yyyy').format(treatment.nextDueDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDue ? AppColors.error : AppColors.success,
                        fontWeight: isDue ? FontWeight.bold : FontWeight.normal,
                      ),
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

  void _addTreatment() {
    showDialog(
      context: context,
      builder: (context) => _TreatmentDialog(dog: widget.dog),
    ).then((_) => setState(() {}));
  }

  void _editTreatment(MedicalTreatment treatment) {
    showDialog(
      context: context,
      builder: (context) =>
          _TreatmentDialog(dog: widget.dog, treatment: treatment),
    ).then((_) => setState(() {}));
  }

  void _registerNewDose(MedicalTreatment treatment) async {
    final now = DateTime.now();
    treatment.dateGiven = now;
    if (treatment.intervalDays != null && treatment.intervalDays! > 0) {
      treatment.nextDueDate = now.add(Duration(days: treatment.intervalDays!));
    }
    await treatment.save();

    // Synkroniser til Firebase
    final userId = AuthService().currentUserId;
    if (userId != null) {
      try {
        await CloudSyncService().saveMedicalTreatment(
          userId: userId,
          dogId: widget.dog.id,
          treatmentId: treatment.id,
          treatmentData: treatment.toJson(),
        );
      } catch (e) {
        AppLogger.debug('Feil ved synkronisering av ny dose til Firebase: $e');
      }
    }

    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ny dose av ${treatment.name} registrert')),
      );
    }
  }

  void _deleteTreatment(MedicalTreatment treatment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slett behandling?'),
        content: Text('Er du sikker på at du vil slette ${treatment.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () async {
              // Kanseller påminnelse
              await ReminderManager().cancelMedicalTreatmentReminder(treatment.id);
              // Slett fra Firebase først
              final userId = AuthService().currentUserId;
              if (userId != null) {
                try {
                  await CloudSyncService().deleteMedicalTreatment(
                    userId: userId,
                    dogId: widget.dog.id,
                    treatmentId: treatment.id,
                  );
                } catch (e) {
                  AppLogger.debug('Feil ved sletting av behandling fra Firebase: $e');
                }
              }
              // Slett fra Hive
              await treatment.delete();
              if (context.mounted) Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Slett', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  // ==================== DNA TESTS TAB ====================
  Widget _buildDnaTestsTab() {
    final dnaTestsBox = Hive.box<DnaTest>('dna_tests');
    final tests =
        dnaTestsBox.values.where((t) => t.dogId == widget.dog.id).toList()
          ..sort(
            (a, b) => (b.testDate ?? DateTime(2000)).compareTo(
              a.testDate ?? DateTime(2000),
            ),
          );

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.lg, bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DNA-tester',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: _addDnaTest,
                tooltip: 'Legg til DNA-test',
                icon: Icon(Icons.add, color: Theme.of(context).primaryColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (tests.isEmpty)
            _buildEmptyState(
              icon: Icons.biotech_outlined,
              title: 'Ingen DNA-tester registrert',
              subtitle: 'Legg til genetiske tester for ${widget.dog.name}',
            )
          else
            ...tests.map((test) => _buildDnaTestCard(test)),
        ],
      ),
    );
  }

  Widget _buildDnaTestCard(DnaTest test) {
    Color resultColor;
    IconData resultIcon;
    String resultLabel;

    switch (test.result) {
      case 'clear':
        resultColor = AppColors.success;
        resultIcon = Icons.check_circle;
        resultLabel = 'Fri';
        break;
      case 'carrier':
        resultColor = AppColors.warning;
        resultIcon = Icons.warning;
        resultLabel = 'Bærer';
        break;
      case 'affected':
        resultColor = AppColors.error;
        resultIcon = Icons.error;
        resultLabel = 'Affisert';
        break;
      case 'pending':
        resultColor = AppColors.neutral500;
        resultIcon = Icons.hourglass_empty;
        resultLabel = 'Venter på resultat';
        break;
      default:
        resultColor = AppColors.neutral500;
        resultIcon = Icons.help_outline;
        resultLabel = test.result;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: resultColor.withValues(alpha: 0.1),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Icon(Icons.biotech, color: resultColor, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        test.testName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(resultIcon, size: 14, color: resultColor),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            resultLabel,
                            style: TextStyle(
                              color: resultColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('Rediger'),
                      onTap: () => Future.delayed(
                        Duration.zero,
                        () => _editDnaTest(test),
                      ),
                    ),
                    PopupMenuItem(
                      child: const Text(
                        'Slett',
                        style: TextStyle(color: AppColors.error),
                      ),
                      onTap: () => Future.delayed(
                        Duration.zero,
                        () => _deleteDnaTest(test),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (test.testDate != null)
              Text(
                'Testet: ${DateFormat('dd.MM.yyyy').format(test.testDate!)}',
                style: TextStyle(color: context.colors.textMuted, fontSize: 12),
              ),
            if (test.laboratory != null && test.laboratory!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Laboratorium: ${test.laboratory}',
                style: TextStyle(color: context.colors.textMuted, fontSize: 12),
              ),
            ],
            if (test.certificateNumber != null &&
                test.certificateNumber!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Sertifikatnr: ${test.certificateNumber}',
                style: TextStyle(color: context.colors.textMuted, fontSize: 12),
              ),
            ],
            if (test.notes != null && test.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(test.notes!, style: const TextStyle(fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }

  void _addDnaTest() {
    showDialog(
      context: context,
      builder: (context) => _DnaTestDialog(dog: widget.dog),
    ).then((_) => setState(() {}));
  }

  void _editDnaTest(DnaTest test) {
    showDialog(
      context: context,
      builder: (context) => _DnaTestDialog(dog: widget.dog, test: test),
    ).then((_) => setState(() {}));
  }

  void _deleteDnaTest(DnaTest test) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slett DNA-test?'),
        content: Text('Er du sikker på at du vil slette ${test.testName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () async {
              // Slett fra Firebase først
              final userId = AuthService().currentUserId;
              if (userId != null) {
                try {
                  await CloudSyncService().deleteDnaTest(
                    userId: userId,
                    dogId: widget.dog.id,
                    testId: test.id,
                  );
                } catch (e) {
                  AppLogger.debug('Feil ved sletting av DNA-test fra Firebase: $e');
                }
              }
              // Slett fra Hive
              await test.delete();
              if (context.mounted) Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Slett', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  // ==================== WEIGHT TAB ====================
  Widget _buildWeightTab() {
    final weightBox = Hive.box<WeightRecord>('weight_records');
    final records =
        weightBox.values.where((r) => r.dogId == widget.dog.id).toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.lg, bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vekthistorikk',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: _addWeightRecord,
                tooltip: 'Legg til vekt',
                icon: Icon(Icons.add, color: Theme.of(context).primaryColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (records.isEmpty)
            _buildEmptyState(
              icon: Icons.monitor_weight_outlined,
              title: 'Ingen vektregistreringer',
              subtitle: 'Følg ${widget.dog.name}s vektutvikling',
            )
          else ...[
            _buildWeightSummary(records),
            const SizedBox(height: AppSpacing.lg),
            ...records.map((record) => _buildWeightCard(record)),
          ],
        ],
      ),
    );
  }

  Widget _buildWeightSummary(List<WeightRecord> records) {
    if (records.isEmpty) return const SizedBox.shrink();

    final latestWeight = records.first.weightKg;
    double? weightChange;
    if (records.length > 1) {
      weightChange = latestWeight - records[1].weightKg;
    }

    return Card(
      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(
                  'Nåværende vekt',
                  style: TextStyle(color: context.colors.textMuted, fontSize: 12),
                ),
                Text(
                  '${latestWeight.toStringAsFixed(1)} kg',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            if (weightChange != null)
              Column(
                children: [
                  Text(
                    'Endring',
                    style: TextStyle(color: context.colors.textMuted, fontSize: 12),
                  ),
                  Row(
                    children: [
                      Icon(
                        weightChange > 0
                            ? Icons.arrow_upward
                            : weightChange < 0
                            ? Icons.arrow_downward
                            : Icons.remove,
                        color: weightChange > 0
                            ? AppColors.error
                            : weightChange < 0
                            ? AppColors.success
                            : AppColors.neutral500,
                        size: 20,
                      ),
                      Text(
                        '${weightChange.abs().toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: weightChange > 0
                              ? AppColors.error
                              : weightChange < 0
                              ? AppColors.success
                              : AppColors.neutral500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightCard(WeightRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: AppRadius.smAll,
          ),
          child: Icon(
            Icons.monitor_weight,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          '${record.weightKg.toStringAsFixed(1)} kg',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(DateFormat('dd.MM.yyyy').format(record.date)),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('Rediger'),
              onTap: () => Future.delayed(
                Duration.zero,
                () => _editWeightRecord(record),
              ),
            ),
            PopupMenuItem(
              child: const Text('Slett', style: TextStyle(color: AppColors.error)),
              onTap: () => Future.delayed(
                Duration.zero,
                () => _deleteWeightRecord(record),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addWeightRecord() {
    showDialog(
      context: context,
      builder: (context) => _WeightDialog(dog: widget.dog),
    ).then((_) => setState(() {}));
  }

  void _editWeightRecord(WeightRecord record) {
    showDialog(
      context: context,
      builder: (context) => _WeightDialog(dog: widget.dog, record: record),
    ).then((_) => setState(() {}));
  }

  void _deleteWeightRecord(WeightRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slett vektregistrering?'),
        content: const Text(
          'Er du sikker på at du vil slette denne registreringen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () async {
              // Slett fra Firebase først
              final userId = AuthService().currentUserId;
              if (userId != null) {
                try {
                  await CloudSyncService().deleteWeightRecord(
                    userId: userId,
                    dogId: widget.dog.id,
                    recordId: record.id,
                  );
                } catch (e) {
                  AppLogger.debug(
                    'Feil ved sletting av vektregistrering fra Firebase: $e',
                  );
                }
              }
              // Slett fra Hive
              await record.delete();
              if (context.mounted) Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Slett', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              borderRadius: AppRadius.xlAll,
            ),
            child: Icon(
              icon,
              size: 72,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: TextStyle(color: context.colors.textMuted, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HealthInfoDialog extends StatefulWidget {
  final Dog dog;
  final HealthInfo? health;

  const _HealthInfoDialog({required this.dog, this.health});

  @override
  State<_HealthInfoDialog> createState() => __HealthInfoDialogState();
}

class __HealthInfoDialogState extends State<_HealthInfoDialog> {
  late String? hdStatus;
  late DateTime? hdDate;
  late int? adStatus;
  late DateTime? adDate;
  late String? patellaStatus;
  late DateTime? patellaDate;
  late TextEditingController notesController;

  @override
  void initState() {
    super.initState();
    hdStatus = widget.health?.hdStatus;
    hdDate = widget.health?.hdDate;
    adStatus = widget.health?.adStatus;
    adDate = widget.health?.adDate;
    patellaStatus = widget.health?.patellaStatus;
    patellaDate = widget.health?.patellaDate;
    notesController = TextEditingController(text: widget.health?.notes ?? '');
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Helseopplysninger'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusSelector(
              'HD Status',
              ['A', 'B', 'C', 'D', 'E'],
              (value) {
                setState(() => hdStatus = value);
              },
              hdStatus,
              'HD dato',
              hdDate,
              (date) {
                setState(() => hdDate = date);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildADStatusSelector(),
            const SizedBox(height: AppSpacing.lg),
            _buildPatellaStatusSelector(),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Merknader',
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
        ElevatedButton(onPressed: _saveHealthInfo, child: const Text('Lagre')),
      ],
    );
  }

  Widget _buildADStatusSelector() {
    final adStatusLabels = {0: 'Grad 0 (Fri)', 1: 'Grad 1 (Svak)', 2: 'Grad 2 (Moderat)', 3: 'Grad 3 (Sterk)'};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AD Status', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.xs),
        DropdownButton<int?>(  
          value: adStatus,
          hint: const Text('Velg AD Status'),
          isExpanded: true,
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text('Ingen (fjern valg)', style: TextStyle(color: context.colors.textDisabled)),
            ),
            ...adStatusLabels.entries
                .map(
                  (entry) => DropdownMenuItem<int?>(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                ),
          ],
          onChanged: (value) {
            setState(() {
              adStatus = value;
              if (value == null) adDate = null;
            });
          },
        ),
        if (adStatus != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  adDate != null
                      ? DateFormat('dd.MM.yyyy').format(adDate!)
                      : 'AD dato',
                  style: TextStyle(color: context.colors.textMuted),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: adDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => adDate = date);
                  }
                },
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPatellaStatusSelector() {
    final patellaStatusLabels = {0: 'Grad 0 (Normal)', 1: 'Grad 1', 2: 'Grad 2', 3: 'Grad 3'};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Patella Status', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.xs),
        DropdownButton<int?>(
          value: patellaStatus != null ? int.tryParse(patellaStatus!) ?? _convertOldPatellaStatus(patellaStatus!) : null,
          hint: const Text('Velg Patella Status'),
          isExpanded: true,
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text('Ingen (fjern valg)', style: TextStyle(color: context.colors.textDisabled)),
            ),
            ...patellaStatusLabels.entries
                .map(
                  (entry) => DropdownMenuItem<int?>(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                ),
          ],
          onChanged: (value) {
            setState(() {
              patellaStatus = value?.toString();
              if (value == null) patellaDate = null;
            });
          },
        ),
        if (patellaStatus != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  patellaDate != null
                      ? DateFormat('dd.MM.yyyy').format(patellaDate!)
                      : 'Patella dato',
                  style: TextStyle(color: context.colors.textMuted),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: patellaDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => patellaDate = date);
                  }
                },
              ),
            ],
          ),
        ],
      ],
    );
  }

  // Konverterer gamle patella-verdier til nye tall
  int? _convertOldPatellaStatus(String status) {
    switch (status) {
      case 'Normal': return 0;
      case 'Grade 1': return 1;
      case 'Grade 2': return 2;
      case 'Grade 3': return 3;
      case 'Grade 4': return 3; // Grade 4 mappes til 3 (maksimal grad)
      default: return int.tryParse(status);
    }
  }

  Widget _buildStatusSelector(
    String label,
    List<String> options,
    Function(String?) onChanged,
    String? selectedValue,
    String dateLabel,
    DateTime? selectedDate,
    Function(DateTime?) onDateChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.xs),
        DropdownButton<String?>(
          value: selectedValue,
          hint: Text('Velg $label'),
          isExpanded: true,
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text('Ingen (fjern valg)', style: TextStyle(color: context.colors.textDisabled)),
            ),
            ...options.map(
              (status) =>
                  DropdownMenuItem<String?>(value: status, child: Text(status)),
            ),
          ],
          onChanged: (value) {
            onChanged(value);
            if (value == null) {
              onDateChanged(null);
            }
          },
        ),
        if (selectedValue != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedDate != null
                      ? DateFormat('dd.MM.yyyy').format(selectedDate)
                      : dateLabel,
                  style: TextStyle(color: context.colors.textMuted),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    onDateChanged(date);
                  }
                },
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _saveHealthInfo() async {
    final healthBox = Hive.box<HealthInfo>('health_info');

    if (widget.health != null) {
      widget.health!.hdStatus = hdStatus;
      widget.health!.hdDate = hdDate;
      widget.health!.adStatus = adStatus;
      widget.health!.adDate = adDate;
      widget.health!.patellaStatus = patellaStatus;
      widget.health!.patellaDate = patellaDate;
      widget.health!.notes = notesController.text;
      widget.health!.save();

      // Save to Firebase if user is authenticated and online
      final authService = AuthService();
      final offlineManager = OfflineModeManager();

      if (authService.isAuthenticated && offlineManager.isOnline) {
        final cloudSync = CloudSyncService();
        try {
          await cloudSync.saveHealthInfo(
            userId: authService.currentUserId!,
            dogId: widget.dog.id,
            healthInfoId: widget.health!.id,
            healthInfoData: widget.health!.toJson(),
          );
        } catch (e) {
          AppLogger.debug('Feil ved lagring av helseopplysninger til Firebase: $e');
        }
      }
    } else {
      final newHealth = HealthInfo(
        id: const Uuid().v4(),
        dogId: widget.dog.id,
        hdStatus: hdStatus,
        hdDate: hdDate,
        adStatus: adStatus,
        adDate: adDate,
        patellaStatus: patellaStatus,
        patellaDate: patellaDate,
        notes: notesController.text,
      );
      healthBox.put(newHealth.id, newHealth);
      widget.dog.healthInfoId = newHealth.id;
      widget.dog.save();

      // Save to Firebase if user is authenticated and online
      final authService = AuthService();
      final offlineManager = OfflineModeManager();

      if (authService.isAuthenticated && offlineManager.isOnline) {
        final cloudSync = CloudSyncService();
        try {
          await cloudSync.saveHealthInfo(
            userId: authService.currentUserId!,
            dogId: widget.dog.id,
            healthInfoId: newHealth.id,
            healthInfoData: newHealth.toJson(),
          );
        } catch (e) {
          AppLogger.debug('Feil ved lagring av helseopplysninger til Firebase: $e');
        }
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
}

class _VaccineDialog extends StatefulWidget {
  final Dog dog;
  final Vaccine? vaccine;

  const _VaccineDialog({required this.dog, this.vaccine});

  @override
  State<_VaccineDialog> createState() => __VaccineDialogState();
}

class __VaccineDialogState extends State<_VaccineDialog> {
  late TextEditingController nameController;
  late DateTime dateTaken;
  late DateTime? nextDueDate;
  late TextEditingController veterinarianController;
  late TextEditingController notesController;
  late TextEditingController reminderDaysController;
  late bool reminderEnabled;
  late int reminderDaysBeforeDue;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.vaccine?.name ?? '');
    dateTaken = widget.vaccine?.dateTaken ?? DateTime.now();
    nextDueDate = widget.vaccine?.nextDueDate;
    veterinarianController = TextEditingController(
      text: widget.vaccine?.veterinarian ?? '',
    );
    notesController = TextEditingController(text: widget.vaccine?.notes ?? '');
    reminderEnabled = widget.vaccine?.reminderEnabled ?? true;
    reminderDaysBeforeDue = widget.vaccine?.reminderDaysBeforeDue ?? 30;
    reminderDaysController = TextEditingController(
      text: reminderDaysBeforeDue.toString(),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    veterinarianController.dispose();
    notesController.dispose();
    reminderDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Vaksin'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Vaksin navn (f.eks. DHPPL, Rabies)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tatt dato: ${DateFormat('dd.MM.yyyy').format(dateTaken)}',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: dateTaken,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => dateTaken = date);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Neste dato: ${nextDueDate != null ? DateFormat('dd.MM.yyyy').format(nextDueDate!) : 'Ikke satt'}',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate:
                          nextDueDate ??
                          DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => nextDueDate = date);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            CheckboxListTile(
              value: reminderEnabled,
              onChanged: (value) =>
                  setState(() => reminderEnabled = value ?? true),
              title: const Text('Aktiver varsel'),
            ),
            if (reminderEnabled) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Text('Varsle $reminderDaysBeforeDue dager før'),
                  ),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: reminderDaysController,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          reminderDaysBeforeDue = int.tryParse(value) ?? 30;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: veterinarianController,
              decoration: const InputDecoration(
                labelText: 'Veterinær (valgfritt)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Merknader (valgfritt)',
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
        ElevatedButton(onPressed: _saveVaccine, child: const Text('Lagre')),
      ],
    );
  }

  void _saveVaccine() async {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vennligst angi vaksin navn')),
      );
      return;
    }

    final vaccineBox = Hive.box<Vaccine>('vaccines');
    final parsedReminderDays = int.tryParse(reminderDaysController.text) ?? 30;

    if (widget.vaccine != null) {
      widget.vaccine!.name = nameController.text;
      widget.vaccine!.dateTaken = dateTaken;
      widget.vaccine!.nextDueDate = nextDueDate;
      widget.vaccine!.veterinarian = veterinarianController.text;
      widget.vaccine!.notes = notesController.text;
      widget.vaccine!.reminderEnabled = reminderEnabled;
      widget.vaccine!.reminderDaysBeforeDue = parsedReminderDays;
      widget.vaccine!.save();

      // Save to Firebase if user is authenticated and online
      final authService = AuthService();
      final offlineManager = OfflineModeManager();

      if (authService.isAuthenticated && offlineManager.isOnline) {
        final cloudSync = CloudSyncService();
        try {
          await cloudSync.saveVaccine(
            userId: authService.currentUserId!,
            dogId: widget.dog.id,
            vaccineId: widget.vaccine!.id,
            vaccineData: widget.vaccine!.toJson(),
          );
        } catch (e) {
          AppLogger.debug('Feil ved lagring av vaksin til Firebase: $e');
        }
      }
    } else {
      final newVaccine = Vaccine(
        id: const Uuid().v4(),
        dogId: widget.dog.id,
        name: nameController.text,
        dateTaken: dateTaken,
        nextDueDate: nextDueDate,
        reminderEnabled: reminderEnabled,
        reminderDaysBeforeDue: parsedReminderDays,
        veterinarian: veterinarianController.text,
        notes: notesController.text,
      );
      vaccineBox.put(newVaccine.id, newVaccine);
      widget.dog.vaccineIds ??= [];
      widget.dog.vaccineIds!.add(newVaccine.id);
      widget.dog.save();

      // Save to Firebase if user is authenticated and online
      final authService = AuthService();
      final offlineManager = OfflineModeManager();

      if (authService.isAuthenticated && offlineManager.isOnline) {
        final cloudSync = CloudSyncService();
        try {
          await cloudSync.saveVaccine(
            userId: authService.currentUserId!,
            dogId: widget.dog.id,
            vaccineId: newVaccine.id,
            vaccineData: newVaccine.toJson(),
          );
        } catch (e) {
          AppLogger.debug('Feil ved lagring av vaksin til Firebase: $e');
        }
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
}

class _ProgesteroneDialog extends StatefulWidget {
  final Dog dog;
  final ProgesteroneMeasurement? measurement;

  const _ProgesteroneDialog({required this.dog, this.measurement});

  @override
  State<_ProgesteroneDialog> createState() => _ProgesteroneDialogState();
}

class _ProgesteroneDialogState extends State<_ProgesteroneDialog> {
  late final TextEditingController valueController;
  late final TextEditingController notesController;
  late final TextEditingController veterinarianController;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    valueController = TextEditingController(
      text: widget.measurement?.value.toString() ?? '',
    );
    notesController = TextEditingController(
      text: widget.measurement?.notes ?? '',
    );
    veterinarianController = TextEditingController(
      text: widget.measurement?.veterinarian ?? '',
    );
    selectedDate = widget.measurement?.dateMeasured ?? DateTime.now();
  }

  @override
  void dispose() {
    valueController.dispose();
    notesController.dispose();
    veterinarianController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.measurement == null
            ? 'Legg til progesteronmåling'
            : 'Rediger måling',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: valueController,
              decoration: const InputDecoration(
                labelText: 'Progesteronverdi (ng/mL) *',
                border: OutlineInputBorder(),
                hintText: 'f.eks. 5.2',
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dato og tid'),
              subtitle: Text(
                DateFormat('dd.MM.yyyy HH:mm').format(selectedDate),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDateTime,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: veterinarianController,
              decoration: const InputDecoration(
                labelText: 'Veterinær (valgfritt)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Merknader (valgfritt)',
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
        ElevatedButton(onPressed: _saveMeasurement, child: const Text('Lagre')),
      ],
    );
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDate),
      );

      if (time != null && mounted) {
        setState(() {
          selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _saveMeasurement() async {
    final value = double.tryParse(valueController.text);
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vennligst angi en gyldig progesteronverdi'),
        ),
      );
      return;
    }

    final progesteroneBox = Hive.box<ProgesteroneMeasurement>(
      'progesterone_measurements',
    );

    ProgesteroneMeasurement measurement;
    if (widget.measurement != null) {
      // Oppdater eksisterende
      measurement = widget.measurement!;
      measurement.value = value;
      measurement.dateMeasured = selectedDate;
      measurement.notes = notesController.text.isEmpty
          ? null
          : notesController.text;
      measurement.veterinarian = veterinarianController.text.isEmpty
          ? null
          : veterinarianController.text;
      await measurement.save();
    } else {
      // Opprett ny
      measurement = ProgesteroneMeasurement(
        id: const Uuid().v4(),
        dogId: widget.dog.id,
        dateMeasured: selectedDate,
        value: value,
        notes: notesController.text.isEmpty ? null : notesController.text,
        veterinarian: veterinarianController.text.isEmpty
            ? null
            : veterinarianController.text,
      );
      await progesteroneBox.add(measurement);
    }

    // Synkroniser til Firebase
    final authService = AuthService();
    final userId = authService.currentUserId;
    if (userId != null) {
      final cloudSync = CloudSyncService();
      try {
        await cloudSync.saveProgesteroneMeasurement(
          userId: userId,
          dogId: widget.dog.id,
          measurementId: measurement.id,
          measurementData: measurement.toJson(),
        );
      } catch (e) {
        AppLogger.debug('Feil ved lagring av progesteronmåling til Firebase: $e');
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
}

// ==================== VET VISIT DIALOG ====================
class _VetVisitDialog extends StatefulWidget {
  final Dog dog;
  final VetVisit? visit;

  const _VetVisitDialog({required this.dog, this.visit});

  @override
  State<_VetVisitDialog> createState() => __VetVisitDialogState();
}

class __VetVisitDialogState extends State<_VetVisitDialog> {
  late DateTime visitDate;
  late String visitType;
  late TextEditingController reasonController;
  late TextEditingController diagnosisController;
  late TextEditingController treatmentController;
  late TextEditingController prescriptionController;
  late TextEditingController veterinarianController;
  late TextEditingController clinicController;
  late TextEditingController costController;
  late TextEditingController notesController;
  DateTime? followUpDate;

  final visitTypes = [
    ('routine', 'Rutinekontroll'),
    ('emergency', 'Akutt'),
    ('surgery', 'Operasjon'),
    ('vaccination', 'Vaksinering'),
    ('followup', 'Oppfølging'),
    ('other', 'Annet'),
  ];

  @override
  void initState() {
    super.initState();
    visitDate = widget.visit?.visitDate ?? DateTime.now();
    visitType = widget.visit?.visitType ?? 'routine';
    reasonController = TextEditingController(text: widget.visit?.reason ?? '');
    diagnosisController = TextEditingController(
      text: widget.visit?.diagnosis ?? '',
    );
    treatmentController = TextEditingController(
      text: widget.visit?.treatment ?? '',
    );
    prescriptionController = TextEditingController(
      text: widget.visit?.prescription ?? '',
    );
    veterinarianController = TextEditingController(
      text: widget.visit?.veterinarian ?? '',
    );
    clinicController = TextEditingController(text: widget.visit?.clinic ?? '');
    costController = TextEditingController(
      text: widget.visit?.cost?.toString() ?? '',
    );
    notesController = TextEditingController(text: widget.visit?.notes ?? '');
    followUpDate = widget.visit?.followUpDate;
  }

  @override
  void dispose() {
    reasonController.dispose();
    diagnosisController.dispose();
    treatmentController.dispose();
    prescriptionController.dispose();
    veterinarianController.dispose();
    clinicController.dispose();
    costController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.visit == null ? 'Nytt veterinærbesøk' : 'Rediger besøk',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Dato'),
              subtitle: Text(DateFormat('dd.MM.yyyy').format(visitDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: visitDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => visitDate = date);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: visitType,
              decoration: const InputDecoration(
                labelText: 'Type besøk',
                border: OutlineInputBorder(),
              ),
              items: visitTypes
                  .map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2)))
                  .toList(),
              onChanged: (value) => setState(() => visitType = value!),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Årsak',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: diagnosisController,
              decoration: const InputDecoration(
                labelText: 'Diagnose',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: treatmentController,
              decoration: const InputDecoration(
                labelText: 'Behandling',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: prescriptionController,
              decoration: const InputDecoration(
                labelText: 'Resept/medisin',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: veterinarianController,
              decoration: const InputDecoration(
                labelText: 'Veterinær',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: clinicController,
              decoration: const InputDecoration(
                labelText: 'Klinikk',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: costController,
              decoration: const InputDecoration(
                labelText: 'Kostnad (kr)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              title: const Text('Oppfølgingsdato'),
              subtitle: Text(
                followUpDate != null
                    ? DateFormat('dd.MM.yyyy').format(followUpDate!)
                    : 'Ikke satt',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (followUpDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => followUpDate = null),
                    ),
                  const Icon(Icons.calendar_today),
                ],
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate:
                      followUpDate ??
                      DateTime.now().add(const Duration(days: 14)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => followUpDate = date);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notater',
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
        ElevatedButton(onPressed: _save, child: const Text('Lagre')),
      ],
    );
  }

  void _save() async {
    final vetVisitsBox = Hive.box<VetVisit>('vet_visits');
    VetVisit visit;

    if (widget.visit != null) {
      visit = widget.visit!;
      visit.visitDate = visitDate;
      visit.visitType = visitType;
      visit.reason = reasonController.text.isEmpty
          ? null
          : reasonController.text;
      visit.diagnosis = diagnosisController.text.isEmpty
          ? null
          : diagnosisController.text;
      visit.treatment = treatmentController.text.isEmpty
          ? null
          : treatmentController.text;
      visit.prescription = prescriptionController.text.isEmpty
          ? null
          : prescriptionController.text;
      visit.veterinarian = veterinarianController.text.isEmpty
          ? null
          : veterinarianController.text;
      visit.clinic = clinicController.text.isEmpty
          ? null
          : clinicController.text;
      visit.cost = double.tryParse(costController.text);
      visit.followUpDate = followUpDate;
      visit.notes = notesController.text.isEmpty ? null : notesController.text;
      await visit.save();
    } else {
      visit = VetVisit(
        id: const Uuid().v4(),
        dogId: widget.dog.id,
        visitDate: visitDate,
        visitType: visitType,
        reason: reasonController.text.isEmpty ? null : reasonController.text,
        diagnosis: diagnosisController.text.isEmpty
            ? null
            : diagnosisController.text,
        treatment: treatmentController.text.isEmpty
            ? null
            : treatmentController.text,
        prescription: prescriptionController.text.isEmpty
            ? null
            : prescriptionController.text,
        veterinarian: veterinarianController.text.isEmpty
            ? null
            : veterinarianController.text,
        clinic: clinicController.text.isEmpty ? null : clinicController.text,
        cost: double.tryParse(costController.text),
        followUpDate: followUpDate,
        notes: notesController.text.isEmpty ? null : notesController.text,
      );
      await vetVisitsBox.add(visit);
    }

    // Synkroniser til Firebase
    final userId = AuthService().currentUserId;
    if (userId != null) {
      try {
        await CloudSyncService().saveVetVisit(
          userId: userId,
          dogId: widget.dog.id,
          visitId: visit.id,
          visitData: visit.toJson(),
        );
      } catch (e) {
        AppLogger.debug('Feil ved lagring av veterinærbesøk til Firebase: $e');
      }
    }

    // Planlegg påminnelse for oppfølging hvis satt
    if (visit.followUpDate != null) {
      await ReminderManager().scheduleVetVisitFollowUpReminder(
        visit: visit,
        dogName: widget.dog.name,
      );
    }

    if (mounted) Navigator.pop(context);
  }
}

// ==================== TREATMENT DIALOG ====================
class _TreatmentDialog extends StatefulWidget {
  final Dog dog;
  final MedicalTreatment? treatment;

  const _TreatmentDialog({required this.dog, this.treatment});

  @override
  State<_TreatmentDialog> createState() => __TreatmentDialogState();
}

class __TreatmentDialogState extends State<_TreatmentDialog> {
  late DateTime dateGiven;
  late String treatmentType;
  late TextEditingController nameController;
  late TextEditingController dosageController;
  late TextEditingController manufacturerController;
  late TextEditingController batchNumberController;
  late TextEditingController notesController;
  late TextEditingController intervalController;
  bool reminderEnabled = true;
  int reminderDaysBefore = 3;

  final treatmentTypes = [
    ('deworming', 'Ormekur'),
    ('flea', 'Loppebehandling'),
    ('tick', 'Flåttbehandling'),
    ('medication', 'Medisin'),
    ('supplement', 'Kosttilskudd'),
    ('other', 'Annet'),
  ];

  final commonTreatments = {
    'deworming': ['Milbemax', 'Drontal', 'Panacur', 'Advocate'],
    'flea': ['Frontline', 'Advantix', 'Bravecto', 'Simparica', 'NexGard'],
    'tick': ['Frontline', 'Advantix', 'Bravecto', 'Simparica', 'Scalibor'],
  };

  @override
  void initState() {
    super.initState();
    dateGiven = widget.treatment?.dateGiven ?? DateTime.now();
    treatmentType = widget.treatment?.treatmentType ?? 'deworming';
    nameController = TextEditingController(text: widget.treatment?.name ?? '');
    dosageController = TextEditingController(
      text: widget.treatment?.dosage ?? '',
    );
    manufacturerController = TextEditingController(
      text: widget.treatment?.manufacturer ?? '',
    );
    batchNumberController = TextEditingController(
      text: widget.treatment?.batchNumber ?? '',
    );
    notesController = TextEditingController(
      text: widget.treatment?.notes ?? '',
    );
    intervalController = TextEditingController(
      text: widget.treatment?.intervalDays?.toString() ?? '90',
    );
    reminderEnabled = widget.treatment?.reminderEnabled ?? true;
    reminderDaysBefore = widget.treatment?.reminderDaysBefore ?? 3;
  }

  @override
  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    manufacturerController.dispose();
    batchNumberController.dispose();
    notesController.dispose();
    intervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.treatment == null ? 'Ny behandling' : 'Rediger behandling',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: treatmentType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: treatmentTypes
                  .map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2)))
                  .toList(),
              onChanged: (value) => setState(() => treatmentType = value!),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (commonTreatments.containsKey(treatmentType)) ...[
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: commonTreatments[treatmentType]!
                    .map(
                      (name) => ActionChip(
                        label: Text(name, style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        )),
                        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                        side: BorderSide(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                          width: 1,
                        ),
                        onPressed: () =>
                            setState(() => nameController.text = name),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Produktnavn*',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              title: const Text('Dato gitt'),
              subtitle: Text(DateFormat('dd.MM.yyyy').format(dateGiven)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: dateGiven,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => dateGiven = date);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosering',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: manufacturerController,
              decoration: const InputDecoration(
                labelText: 'Produsent',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: batchNumberController,
              decoration: const InputDecoration(
                labelText: 'Batchnummer',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: intervalController,
              decoration: const InputDecoration(
                labelText: 'Intervall (dager)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              title: const Text('Påminnelse'),
              subtitle: Text('$reminderDaysBefore dager før'),
              value: reminderEnabled,
              onChanged: (value) => setState(() => reminderEnabled = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notater',
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
        ElevatedButton(onPressed: _save, child: const Text('Lagre')),
      ],
    );
  }

  void _save() async {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Produktnavn er påkrevd')));
      return;
    }

    final treatmentsBox = Hive.box<MedicalTreatment>('medical_treatments');
    final intervalDays = int.tryParse(intervalController.text);
    DateTime? nextDueDate;
    if (intervalDays != null && intervalDays > 0) {
      nextDueDate = dateGiven.add(Duration(days: intervalDays));
    }

    MedicalTreatment treatment;

    if (widget.treatment != null) {
      treatment = widget.treatment!;
      treatment.name = nameController.text;
      treatment.treatmentType = treatmentType;
      treatment.dateGiven = dateGiven;
      treatment.dosage = dosageController.text.isEmpty
          ? null
          : dosageController.text;
      treatment.manufacturer = manufacturerController.text.isEmpty
          ? null
          : manufacturerController.text;
      treatment.batchNumber = batchNumberController.text.isEmpty
          ? null
          : batchNumberController.text;
      treatment.intervalDays = intervalDays;
      treatment.nextDueDate = nextDueDate;
      treatment.reminderEnabled = reminderEnabled;
      treatment.reminderDaysBefore = reminderDaysBefore;
      treatment.notes = notesController.text.isEmpty
          ? null
          : notesController.text;
      await treatment.save();
    } else {
      treatment = MedicalTreatment(
        id: const Uuid().v4(),
        dogId: widget.dog.id,
        name: nameController.text,
        treatmentType: treatmentType,
        dateGiven: dateGiven,
        dosage: dosageController.text.isEmpty ? null : dosageController.text,
        manufacturer: manufacturerController.text.isEmpty
            ? null
            : manufacturerController.text,
        batchNumber: batchNumberController.text.isEmpty
            ? null
            : batchNumberController.text,
        intervalDays: intervalDays,
        nextDueDate: nextDueDate,
        reminderEnabled: reminderEnabled,
        reminderDaysBefore: reminderDaysBefore,
        notes: notesController.text.isEmpty ? null : notesController.text,
      );
      await treatmentsBox.add(treatment);
    }

    // Synkroniser til Firebase
    final userId = AuthService().currentUserId;
    if (userId != null) {
      try {
        await CloudSyncService().saveMedicalTreatment(
          userId: userId,
          dogId: widget.dog.id,
          treatmentId: treatment.id,
          treatmentData: treatment.toJson(),
        );
      } catch (e) {
        AppLogger.debug('Feil ved lagring av behandling til Firebase: $e');
      }
    }

    // Planlegg påminnelse hvis aktivert
    if (treatment.reminderEnabled && treatment.nextDueDate != null) {
      await ReminderManager().scheduleMedicalTreatmentReminder(
        treatment: treatment,
        dogName: widget.dog.name,
      );
    }

    if (mounted) Navigator.pop(context);
  }
}

// ==================== DNA TEST DIALOG ====================
class _DnaTestDialog extends StatefulWidget {
  final Dog dog;
  final DnaTest? test;

  const _DnaTestDialog({required this.dog, this.test});

  @override
  State<_DnaTestDialog> createState() => __DnaTestDialogState();
}

class __DnaTestDialogState extends State<_DnaTestDialog> {
  late DateTime testDate;
  late String result;
  late TextEditingController testNameController;
  late TextEditingController laboratoryController;
  late TextEditingController certificateController;
  late TextEditingController notesController;

  final results = [
    ('pending', 'Venter på resultat'),
    ('clear', 'Fri'),
    ('carrier', 'Bærer'),
    ('affected', 'Affisert'),
  ];

  @override
  void initState() {
    super.initState();
    testDate = widget.test?.testDate ?? DateTime.now();
    result = widget.test?.result ?? 'pending';
    testNameController = TextEditingController(
      text: widget.test?.testName ?? '',
    );
    laboratoryController = TextEditingController(
      text: widget.test?.laboratory ?? '',
    );
    certificateController = TextEditingController(
      text: widget.test?.certificateNumber ?? '',
    );
    notesController = TextEditingController(text: widget.test?.notes ?? '');
  }

  @override
  void dispose() {
    testNameController.dispose();
    laboratoryController.dispose();
    certificateController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.test == null ? 'Ny DNA-test' : 'Rediger DNA-test'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Vanlige tester:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: CommonDnaTests.tests
                  .take(12)
                  .map(
                    (name) => ActionChip(
                      label: Text(name, style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      )),
                      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                      side: BorderSide(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                        width: 1,
                      ),
                      onPressed: () =>
                          setState(() => testNameController.text = name),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: testNameController,
              decoration: const InputDecoration(
                labelText: 'Testnavn*',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              title: const Text('Testdato'),
              subtitle: Text(DateFormat('dd.MM.yyyy').format(testDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: testDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => testDate = date);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: result,
              decoration: const InputDecoration(
                labelText: 'Resultat',
                border: OutlineInputBorder(),
              ),
              items: results
                  .map((r) => DropdownMenuItem(value: r.$1, child: Text(r.$2)))
                  .toList(),
              onChanged: (value) => setState(() => result = value!),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: laboratoryController,
              decoration: const InputDecoration(
                labelText: 'Laboratorium',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: certificateController,
              decoration: const InputDecoration(
                labelText: 'Sertifikatnummer',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notater',
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
        ElevatedButton(onPressed: _save, child: const Text('Lagre')),
      ],
    );
  }

  void _save() async {
    if (testNameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Testnavn er påkrevd')));
      return;
    }

    final dnaTestsBox = Hive.box<DnaTest>('dna_tests');
    DnaTest test;

    if (widget.test != null) {
      test = widget.test!;
      test.testName = testNameController.text;
      test.testDate = testDate;
      test.result = result;
      test.laboratory = laboratoryController.text.isEmpty
          ? null
          : laboratoryController.text;
      test.certificateNumber = certificateController.text.isEmpty
          ? null
          : certificateController.text;
      test.notes = notesController.text.isEmpty ? null : notesController.text;
      await test.save();
    } else {
      test = DnaTest(
        id: const Uuid().v4(),
        dogId: widget.dog.id,
        testName: testNameController.text,
        testDate: testDate,
        result: result,
        laboratory: laboratoryController.text.isEmpty
            ? null
            : laboratoryController.text,
        certificateNumber: certificateController.text.isEmpty
            ? null
            : certificateController.text,
        notes: notesController.text.isEmpty ? null : notesController.text,
      );
      await dnaTestsBox.add(test);
    }

    // Synkroniser til Firebase
    final userId = AuthService().currentUserId;
    if (userId != null) {
      try {
        await CloudSyncService().saveDnaTest(
          userId: userId,
          dogId: widget.dog.id,
          testId: test.id,
          testData: test.toJson(),
        );
      } catch (e) {
        AppLogger.debug('Feil ved lagring av DNA-test til Firebase: $e');
      }
    }

    if (mounted) Navigator.pop(context);
  }
}

// ==================== WEIGHT DIALOG ====================
class _WeightDialog extends StatefulWidget {
  final Dog dog;
  final WeightRecord? record;

  const _WeightDialog({required this.dog, this.record});

  @override
  State<_WeightDialog> createState() => __WeightDialogState();
}

class __WeightDialogState extends State<_WeightDialog> {
  late DateTime date;
  late TextEditingController weightController;
  late TextEditingController notesController;

  @override
  void initState() {
    super.initState();
    date = widget.record?.date ?? DateTime.now();
    weightController = TextEditingController(
      text: widget.record?.weightKg.toString() ?? '',
    );
    notesController = TextEditingController(text: widget.record?.notes ?? '');
  }

  @override
  void dispose() {
    weightController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.record == null ? 'Registrer vekt' : 'Rediger vekt'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Dato'),
              subtitle: Text(DateFormat('dd.MM.yyyy').format(date)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final selectedDate = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (selectedDate != null) setState(() => date = selectedDate);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: weightController,
              decoration: const InputDecoration(
                labelText: 'Vekt (kg)*',
                border: OutlineInputBorder(),
                suffixText: 'kg',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notater',
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
        ElevatedButton(onPressed: _save, child: const Text('Lagre')),
      ],
    );
  }

  void _save() async {
    final weight = double.tryParse(weightController.text.replaceAll(',', '.'));
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ugyldig vekt')));
      return;
    }

    final weightBox = Hive.box<WeightRecord>('weight_records');
    WeightRecord record;

    if (widget.record != null) {
      record = widget.record!;
      record.date = date;
      record.weightKg = weight;
      record.notes = notesController.text.isEmpty ? null : notesController.text;
      await record.save();
    } else {
      record = WeightRecord(
        id: const Uuid().v4(),
        dogId: widget.dog.id,
        date: date,
        weightKg: weight,
        notes: notesController.text.isEmpty ? null : notesController.text,
      );
      await weightBox.add(record);
    }

    // Synkroniser til Firebase
    final userId = AuthService().currentUserId;
    if (userId != null) {
      try {
        await CloudSyncService().saveWeightRecord(
          userId: userId,
          dogId: widget.dog.id,
          recordId: record.id,
          recordData: record.toJson(),
        );
      } catch (e) {
        AppLogger.debug('Feil ved lagring av vektregistrering til Firebase: $e');
      }
    }

    if (mounted) Navigator.pop(context);
  }
}
