import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:breedly/models/delivery_checklist.dart';
import 'package:breedly/models/puppy.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/utils/app_bar_builder.dart';
import 'package:breedly/services/auth_service.dart';
import 'package:breedly/services/cloud_sync_service.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';

class DeliveryChecklistScreen extends StatefulWidget {
  final Puppy puppy;

  const DeliveryChecklistScreen({super.key, required this.puppy});

  @override
  State<DeliveryChecklistScreen> createState() => _DeliveryChecklistScreenState();
}

class _DeliveryChecklistScreenState extends State<DeliveryChecklistScreen> {
  DeliveryChecklist? _checklist;
  bool _isLoading = true;
  final _dateFormat = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _loadOrCreateChecklist();
  }

  Future<void> _loadOrCreateChecklist() async {
    setState(() => _isLoading = true);

    try {
      final box = Hive.box<DeliveryChecklist>('delivery_checklists');
      
      // Find existing checklist for this puppy
      final existing = box.values.where((c) => c.puppyId == widget.puppy.id).firstOrNull;
      
      if (existing != null) {
        _checklist = existing;
      } else {
        // Create a new checklist
        _checklist = DeliveryChecklist.createDefault(
          const Uuid().v4(),
          widget.puppy.id,
        );
        await box.put(_checklist!.id, _checklist!);
        await _syncToCloud();
      }
    } catch (e) {
      debugPrint('Error loading checklist: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _syncToCloud() async {
    try {
      final userId = AuthService().currentUser?.uid;
      if (userId != null && _checklist != null) {
        await CloudSyncService().syncDeliveryChecklist(_checklist!, userId);
      }
    } catch (e) {
      debugPrint('Error syncing checklist: $e');
    }
  }

  Future<void> _toggleItem(DeliveryChecklistItem item) async {
    setState(() {
      item.isCompleted = !item.isCompleted;
      item.completedDate = item.isCompleted ? DateTime.now() : null;
      
      // Update overall completion status
      _checklist!.isComplete = _checklist!.allItemsCompleted;
    });

    // Save to Hive
    try {
      final box = Hive.box<DeliveryChecklist>('delivery_checklists');
      await box.put(_checklist!.id, _checklist!);
      await _syncToCloud();
    } catch (e) {
      debugPrint('Error saving checklist: $e');
    }
  }

  Future<void> _addCustomItem() async {
    final localizations = AppLocalizations.of(context);
    final titleController = TextEditingController();
    String selectedCategory = DeliveryChecklistCategory.health;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(localizations?.addItem ?? 'Legg til punkt'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: localizations?.title ?? 'Tittel',
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: InputDecoration(
                  labelText: localizations?.category ?? 'Kategori',
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DeliveryChecklistCategory.health,
                  DeliveryChecklistCategory.documents,
                  DeliveryChecklistCategory.equipment,
                  DeliveryChecklistCategory.information,
                ].map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(DeliveryChecklistCategory.getLabel(cat)),
                )).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedCategory = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations?.cancel ?? 'Avbryt'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  Navigator.pop(context, {
                    'title': titleController.text,
                    'category': selectedCategory,
                  });
                }
              },
              child: Text(localizations?.add ?? 'Legg til'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final newItem = DeliveryChecklistItem(
        id: const Uuid().v4(),
        title: result['title']!,
        category: result['category']!,
        sortOrder: _checklist!.items.length,
      );

      setState(() {
        _checklist!.items.add(newItem);
      });

      // Save
      try {
        final box = Hive.box<DeliveryChecklist>('delivery_checklists');
        await box.put(_checklist!.id, _checklist!);
        await _syncToCloud();
      } catch (e) {
        debugPrint('Error saving new item: $e');
      }
    }
  }

  Future<void> _setDeliveryDate() async {
    final localizations = AppLocalizations.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: _checklist?.deliveryDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _checklist!.deliveryDate = picked;
      });

      // Save
      try {
        final box = Hive.box<DeliveryChecklist>('delivery_checklists');
        await box.put(_checklist!.id, _checklist!);
        await _syncToCloud();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations?.deliveryDateSet ?? 'Leveringsdato satt'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error saving delivery date: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBarBuilder.buildAppBar(
        title: localizations?.deliveryChecklist ?? 'Leveringssjekkliste',
        context: context,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _setDeliveryDate,
            tooltip: localizations?.setDeliveryDate ?? 'Sett leveringsdato',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _checklist == null
              ? Center(
                  child: Text(localizations?.errorLoadingChecklist ?? 'Kunne ikke laste sjekkliste'),
                )
              : _buildChecklistContent(primaryColor, localizations),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCustomItem,
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildChecklistContent(Color primaryColor, AppLocalizations? localizations) {
    final completionPercent = (_checklist!.completionPercentage * 100).toInt();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Puppy info and progress header
          _buildHeaderCard(primaryColor, completionPercent, localizations),
          
          const SizedBox(height: AppSpacing.xl),

          // Categories
          _buildCategorySection(
            DeliveryChecklistCategory.health,
            Icons.medical_services_rounded,
            AppColors.error,
            localizations,
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          _buildCategorySection(
            DeliveryChecklistCategory.documents,
            Icons.description_rounded,
            AppColors.info,
            localizations,
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          _buildCategorySection(
            DeliveryChecklistCategory.equipment,
            Icons.shopping_bag_rounded,
            AppColors.warning,
            localizations,
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          _buildCategorySection(
            DeliveryChecklistCategory.information,
            Icons.info_rounded,
            AppColors.accent5,
            localizations,
          ),

          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(Color primaryColor, int completionPercent, AppLocalizations? localizations) {
    final isComplete = _checklist!.allItemsCompleted;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isComplete
              ? [AppColors.success, AppColors.success.withValues(alpha: 0.8)]
              : [primaryColor, primaryColor.withValues(alpha: 0.8)],
        ),
        borderRadius: AppRadius.xlAll,
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: AppRadius.mdAll,
                ),
                child: Icon(
                  isComplete ? Icons.check_circle : Icons.pets,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.puppy.effectiveDisplayName,
                      style: AppTypography.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_checklist!.deliveryDate != null)
                      Text(
                        '${localizations?.deliveryDate ?? 'Levering'}: ${_dateFormat.format(_checklist!.deliveryDate!)}',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localizations?.progress ?? 'Fremgang',
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  Text(
                    '$completionPercent%',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: AppRadius.smAll,
                child: LinearProgressIndicator(
                  value: _checklist!.completionPercentage,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8,
                ),
              ),
            ],
          ),

          if (isComplete) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: AppRadius.mdAll,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.celebration, color: Colors.white, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    localizations?.readyForDelivery ?? 'Klar for levering!',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    String category,
    IconData icon,
    Color color,
    AppLocalizations? localizations,
  ) {
    final items = _checklist!.getItemsByCategory(category);
    if (items.isEmpty) return const SizedBox.shrink();

    final completedCount = items.where((i) => i.isCompleted).length;
    final categoryLabel = DeliveryChecklistCategory.getLabel(category);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    categoryLabel,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: completedCount == items.length
                        ? AppColors.success.withValues(alpha: 0.15)
                        : color.withValues(alpha: 0.1),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Text(
                    '$completedCount/${items.length}',
                    style: AppTypography.labelMedium.copyWith(
                      color: completedCount == items.length ? AppColors.success : color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),

          // Items list
          ...items.map((item) => _buildChecklistItem(item, color)),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(DeliveryChecklistItem item, Color categoryColor) {
    return InkWell(
      onTap: () => _toggleItem(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: item.isCompleted ? AppColors.success : Colors.transparent,
                borderRadius: AppRadius.smAll,
                border: Border.all(
                  color: item.isCompleted ? AppColors.success : Theme.of(context).colorScheme.outline,
                  width: 2,
                ),
              ),
              child: item.isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.bodyMedium.copyWith(
                      decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                      color: item.isCompleted 
                          ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5) 
                          : null,
                    ),
                  ),
                  if (item.isCompleted && item.completedDate != null)
                    Text(
                      _dateFormat.format(item.completedDate!),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                ],
              ),
            ),
            if (item.isCompleted)
              Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
