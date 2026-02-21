import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'package:breedly/models/expense.dart';
import 'package:breedly/models/income.dart';
import 'package:breedly/models/litter.dart';
import 'package:intl/intl.dart';
import 'package:breedly/services/auth_service.dart';
import 'package:breedly/services/cloud_sync_service.dart';
import 'package:breedly/services/offline_mode_manager.dart';
import 'package:breedly/utils/logger.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/utils/theme_colors.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';

class FinanceScreen extends StatefulWidget {
  final bool showAppBar;

  const FinanceScreen({super.key, this.showAppBar = true});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedLitterId; // null for hele økonomien, ellers ID på spesifikk kull

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: widget.showAppBar ? AppBar(
        title: Text(
          localizations?.finance ?? 'Økonomi',
          style: AppTypography.headlineLarge.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: context.colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: context.colors.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: context.colors.textCaption,
          tabs: [
            Tab(icon: const Icon(Icons.analytics_outlined), text: localizations?.overview ?? 'Oversikt'),
            Tab(icon: const Icon(Icons.trending_down), text: localizations?.expenses ?? 'Utgifter'),
            Tab(icon: const Icon(Icons.trending_up), text: localizations?.income ?? 'Inntekter'),
          ],
        ),
      ) : null,
      body: SafeArea(
        child: Column(
          children: [
            if (!widget.showAppBar) ...[
              // Custom header når app bar er skjult
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                color: context.colors.surface,
                child: Column(
                  children: [
                    Center(
                      child: Text(
                        localizations?.finance ?? 'Økonomi',
                        style: AppTypography.headlineLarge.copyWith(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TabBar(
                      controller: _tabController,
                      indicatorColor: primaryColor,
                      labelColor: primaryColor,
                      unselectedLabelColor: context.colors.textCaption,
                      tabs: [
                        Tab(icon: const Icon(Icons.analytics_outlined), text: localizations?.overview ?? 'Oversikt'),
                        Tab(icon: const Icon(Icons.trending_down), text: localizations?.expenses ?? 'Utgifter'),
                        Tab(icon: const Icon(Icons.trending_up), text: localizations?.income ?? 'Inntekter'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            // Kullvelger
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: ValueListenableBuilder(
                valueListenable: Hive.box<Litter>('litters').listenable(),
                builder: (context, Box<Litter> litterBox, _) {
                  final litters = litterBox.values.toList();
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() => _selectedLitterId = null);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: _selectedLitterId == null
                                  ? AppColors.primary
                                : context.colors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.full),
                              border: Border.all(
                                color: AppColors.primary,
                              ),
                            ),
                            child: Text(
                              localizations?.all ?? 'Alle',
                              style: AppTypography.labelMedium.copyWith(
                                color: _selectedLitterId == null
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: AppSpacing.sm),
                      ...litters.map((litter) {
                        final isSelected = _selectedLitterId == litter.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedLitterId = litter.id);
                            },
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : context.colors.surface,
                                borderRadius: BorderRadius.circular(AppRadius.full),
                                border: Border.all(
                                  color: AppColors.primary,
                                ),
                              ),
                              child: Text(
                                '${litter.damName} × ${litter.sireName}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverview(primaryColor),
                _buildExpenses(primaryColor),
                _buildIncomes(primaryColor),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview(Color primaryColor) {
    final localizations = AppLocalizations.of(context);
    return ValueListenableBuilder(
      valueListenable:
          Hive.box<Expense>('expenses').listenable(),
      builder: (context, Box<Expense> expenseBox, _) {
        return ValueListenableBuilder(
          valueListenable: Hive.box<Income>('incomes').listenable(),
          builder: (context, Box<Income> incomeBox, _) {
            // Filtrer utgifter og inntekter basert på valgt kull
            final filteredExpenses = _selectedLitterId == null
                ? expenseBox.values.toList()
                : expenseBox.values
                    .where((e) => e.litterId == _selectedLitterId)
                    .toList();

            final filteredIncomes = _selectedLitterId == null
                ? incomeBox.values.toList()
                : incomeBox.values
                    .where((i) => i.litterId == _selectedLitterId)
                    .toList();

            double totalExpenses =
                filteredExpenses.fold(0, (sum, item) => sum + item.amount);
            double totalIncomes =
                filteredIncomes.fold(0, (sum, item) => sum + item.amount);
            double balance = totalIncomes - totalExpenses;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  // Income card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.lgAll,
                      side: BorderSide(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    color: AppColors.success.withValues(alpha: 0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: AppRadius.mdAll,
                            ),
                            child: const Icon(Icons.trending_up, color: AppColors.success, size: 24),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  localizations?.totalIncome ?? 'Total inntekt',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: context.colors.textCaption,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  '${totalIncomes.toStringAsFixed(2)} kr',
                                  style: AppTypography.headlineMedium.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Expense card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.lgAll,
                      side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    color: AppColors.error.withValues(alpha: 0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.15),
                              borderRadius: AppRadius.mdAll,
                            ),
                            child: const Icon(Icons.trending_down, color: AppColors.error, size: 24),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  localizations?.totalExpense ?? 'Total utgift',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: context.colors.textCaption,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  '${totalExpenses.toStringAsFixed(2)} kr',
                                  style: AppTypography.headlineMedium.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Balance card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.lgAll,
                      side: BorderSide(
                        color: (balance >= 0 ? AppColors.primary : AppColors.error).withValues(alpha: 0.3),
                      ),
                    ),
                    color: (balance >= 0 ? AppColors.primary : AppColors.error).withValues(alpha: 0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: (balance >= 0 ? AppColors.primary : AppColors.error).withValues(alpha: 0.15),
                              borderRadius: AppRadius.mdAll,
                            ),
                            child: Icon(
                              balance >= 0 ? Icons.account_balance_wallet : Icons.warning_amber_rounded,
                              color: balance >= 0 ? AppColors.primary : AppColors.error,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  localizations?.netResult ?? 'Netto resultat',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: context.colors.textCaption,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  '${balance.toStringAsFixed(2)} kr',
                                  style: AppTypography.headlineMedium.copyWith(
                                    color: balance >= 0 ? AppColors.primary : AppColors.error,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Statistics section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      localizations?.statistics ?? 'Statistikk',
                      style: AppTypography.titleMedium.copyWith(
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.lgAll,
                      side: BorderSide(color: context.colors.border),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(localizations?.numberOfExpenses ?? 'Antall utgifter', style: AppTypography.bodyMedium),
                          trailing: Text(
                            '${filteredExpenses.length}',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Divider(height: 1, color: context.colors.border),
                        ListTile(
                          title: Text(localizations?.numberOfIncomes ?? 'Antall inntekter', style: AppTypography.bodyMedium),
                          trailing: Text(
                            '${filteredIncomes.length}',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExpenses(Color primaryColor) {
    final localizations = AppLocalizations.of(context);
    return ValueListenableBuilder(
      valueListenable: Hive.box<Expense>('expenses').listenable(),
      builder: (context, Box<Expense> box, _) {
        // Filtrer utgifter basert på valgt kull
        final filteredExpenses = _selectedLitterId == null
            ? box.values.toList()
            : box.values
                .where((e) => e.litterId == _selectedLitterId)
                .toList();

        if (filteredExpenses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 80, color: context.colors.divider),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  localizations?.noExpensesRegistered ?? 'Ingen utgifter registrert',
                  style: AppTypography.titleSmall.copyWith(color: context.colors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  localizations?.addFirstExpense ?? 'Legg inn første utgift for å få oversikt',
                  style: AppTypography.bodySmall.copyWith(color: context.colors.textCaption),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: () => _addExpense(context),
                  icon: const Icon(Icons.add),
                  label: Text(localizations?.addExpense ?? 'Legg til utgift'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.sm, bottom: 88),
          itemCount: filteredExpenses.length,
          itemBuilder: (context, index) {
            final expense = filteredExpenses[index];

            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.lgAll,
                side: BorderSide(color: context.colors.border),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: const Icon(
                    Icons.money_off_rounded,
                    color: AppColors.error,
                    size: 22,
                  ),
                ),
                title: Text(
                  expense.category,
                  style: AppTypography.labelLarge.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      DateFormat('dd.MM.yyyy').format(expense.date),
                      style: AppTypography.bodySmall.copyWith(
                        color: context.colors.textCaption,
                      ),
                    ),
                    if (expense.description != null &&
                        expense.description!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        expense.description!,
                        style: AppTypography.caption.copyWith(
                          color: context.colors.textDisabled,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
                trailing: Text(
                  '- ${expense.amount.toStringAsFixed(2)} kr',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.error,
                  ),
                ),
                onLongPress: () => _deleteExpense(context, expense),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIncomes(Color primaryColor) {
    final localizations = AppLocalizations.of(context);
    return ValueListenableBuilder(
      valueListenable: Hive.box<Income>('incomes').listenable(),
      builder: (context, Box<Income> box, _) {
        // Filtrer inntekter basert på valgt kull
        final filteredIncomes = _selectedLitterId == null
            ? box.values.toList()
            : box.values
                .where((i) => i.litterId == _selectedLitterId)
                .toList();

        if (filteredIncomes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.attach_money, size: 80, color: context.colors.divider),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  localizations?.noIncomesRegistered ?? 'Ingen inntekter registrert',
                  style: AppTypography.titleSmall.copyWith(color: context.colors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  localizations?.addFirstIncome ?? 'Legg inn første inntekt for å få oversikt',
                  style: AppTypography.bodySmall.copyWith(color: context.colors.textCaption),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: () => _addIncome(context),
                  icon: const Icon(Icons.add),
                  label: Text(localizations?.addIncome ?? 'Legg til inntekt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.sm, bottom: 88),
          itemCount: filteredIncomes.length,
          itemBuilder: (context, index) {
            final income = filteredIncomes[index];

            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.lgAll,
                side: BorderSide(color: context.colors.border),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: const Icon(
                    Icons.attach_money_rounded,
                    color: AppColors.success,
                    size: 22,
                  ),
                ),
                title: Text(
                  income.buyerName ?? 'Inntekt',
                  style: AppTypography.labelLarge.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      DateFormat('dd.MM.yyyy').format(income.date),
                      style: AppTypography.bodySmall.copyWith(
                        color: context.colors.textCaption,
                      ),
                    ),
                    if (income.description != null &&
                        income.description!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        income.description!,
                        style: AppTypography.caption.copyWith(
                          color: context.colors.textDisabled,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
                trailing: Text(
                  '+ ${income.amount.toStringAsFixed(2)} kr',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.success,
                  ),
                ),
                onLongPress: () => _deleteIncome(context, income),
              ),
            );
          },
        );
      },
    );
  }

  void _addExpense(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    TextEditingController categoryController = TextEditingController();
    TextEditingController amountController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    String? selectedLitterId = _selectedLitterId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(localizations?.addExpense ?? 'Legg til utgift'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder(
                    valueListenable: Hive.box<Litter>('litters').listenable(),
                    builder: (context, Box<Litter> litterBox, _) {
                      final litters = litterBox.values.toList();
                      return DropdownButtonFormField<String?>(
                        isExpanded: true,
                        initialValue: selectedLitterId,
                        decoration: const InputDecoration(labelText: 'Kull (valgfritt)'),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Ingen kull'),
                          ),
                          ...litters.map((litter) {
                            return DropdownMenuItem(
                              value: litter.id,
                              child: Text(
                                '${litter.damName} × ${litter.sireName}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() => selectedLitterId = value);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: InputDecoration(labelText: localizations?.category ?? 'Kategori'),
                    items: [
                      DropdownMenuItem(value: localizations?.food ?? 'Fôr', child: Text(localizations?.food ?? 'Fôr')),
                      DropdownMenuItem(value: localizations?.veterinary ?? 'Veterinær', child: Text(localizations?.veterinary ?? 'Veterinær')),
                      DropdownMenuItem(value: localizations?.registration ?? 'Registrering (NKK)', child: Text(localizations?.registration ?? 'Registrering (NKK)', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: localizations?.other ?? 'Annet', child: Text(localizations?.other ?? 'Annet')),
                    ],
                    onChanged: (value) {
                      categoryController.text = value ?? '';
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: amountController,
                    decoration: InputDecoration(labelText: localizations?.amount ?? 'Beløp (kr)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(labelText: localizations?.description ?? 'Beskrivelse'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations?.cancel ?? 'Avbryt'),
            ),
            TextButton(
              onPressed: () {
                final expense = Expense(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  category: categoryController.text,
                  amount: double.tryParse(amountController.text) ?? 0,
                  date: DateTime.now(),
                  description: descriptionController.text.isEmpty
                      ? null
                      : descriptionController.text,
                  litterId: selectedLitterId,
                );

                final box = Hive.box<Expense>('expenses');
                box.put(expense.id, expense);
                
                // Save to Firebase if user is authenticated and online
                final authService = AuthService();
                final offlineManager = OfflineModeManager();
                
                if (authService.isAuthenticated && offlineManager.isOnline) {
                  final cloudSync = CloudSyncService();
                  try {
                    unawaited(cloudSync.saveExpense(
                      userId: authService.currentUserId!,
                      expenseId: expense.id,
                      expenseData: expense.toJson(),
                    ));
                  } catch (e) {
                    AppLogger.debug('Feil ved lagring av utgift til Firebase: $e');
                  }
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations?.expenseAdded ?? 'Utgift lagt til')),
                );
              },
              child: Text(localizations?.save ?? 'Lagre'),
            ),
          ],
        ),
      ),
    );
  }

  void _addIncome(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    TextEditingController amountController = TextEditingController();
    TextEditingController buyerNameController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    String? selectedLitterId = _selectedLitterId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(localizations?.addIncome ?? 'Legg til inntekt'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder(
                    valueListenable: Hive.box<Litter>('litters').listenable(),
                    builder: (context, Box<Litter> litterBox, _) {
                      final litters = litterBox.values.toList();
                      return DropdownButtonFormField<String?>(
                        isExpanded: true,
                        initialValue: selectedLitterId,
                        decoration: InputDecoration(labelText: localizations?.litterOptional ?? 'Kull (valgfritt)'),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(localizations?.noLitter ?? 'Ingen kull'),
                          ),
                          ...litters.map((litter) {
                            return DropdownMenuItem(
                              value: litter.id,
                              child: Text(
                                '${litter.damName} × ${litter.sireName}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() => selectedLitterId = value);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: amountController,
                    decoration: InputDecoration(labelText: localizations?.amount ?? 'Beløp (kr)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: buyerNameController,
                    decoration: InputDecoration(labelText: localizations?.buyerOptional ?? 'Kjøper (valgfritt)'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(labelText: localizations?.description ?? 'Beskrivelse'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations?.cancel ?? 'Avbryt'),
            ),
            TextButton(
              onPressed: () {
                final income = Income(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  amount: double.tryParse(amountController.text) ?? 0,
                  date: DateTime.now(),
                  buyerName: buyerNameController.text.isEmpty
                      ? null
                      : buyerNameController.text,
                  description: descriptionController.text.isEmpty
                      ? null
                      : descriptionController.text,
                  litterId: selectedLitterId,
                );

                final box = Hive.box<Income>('incomes');
                box.put(income.id, income);
                
                // Save to Firebase if user is authenticated and online
                final authService = AuthService();
                final offlineManager = OfflineModeManager();
                
                if (authService.isAuthenticated && offlineManager.isOnline) {
                  final cloudSync = CloudSyncService();
                  try {
                    unawaited(cloudSync.saveIncome(
                      userId: authService.currentUserId!,
                      incomeId: income.id,
                      incomeData: income.toJson(),
                    ));
                  } catch (e) {
                    AppLogger.debug('Feil ved lagring av inntekt til Firebase: $e');
                  }
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations?.incomeAdded ?? 'Inntekt lagt til')),
                );
              },
              child: Text(localizations?.save ?? 'Lagre'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteExpense(BuildContext context, Expense expense) {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations?.deleteExpense ?? 'Slett utgift?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations?.cancel ?? 'Avbryt'),
          ),
          TextButton(
            onPressed: () async {
              // Slett fra Firebase først
              final userId = AuthService().currentUserId;
              if (userId != null) {
                try {
                  await CloudSyncService().deleteExpense(
                    userId: userId,
                    expenseId: expense.id,
                  );
                } catch (e) {
                  // Ignorer Firebase-feil
                }
              }
              // Slett fra Hive
              await expense.delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(localizations?.delete ?? 'Slett'),
          ),
        ],
      ),
    );
  }

  void _deleteIncome(BuildContext context, Income income) {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations?.deleteIncome ?? 'Slett inntekt?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations?.cancel ?? 'Avbryt'),
          ),
          TextButton(
            onPressed: () async {
              // Slett fra Firebase først
              final userId = AuthService().currentUserId;
              if (userId != null) {
                try {
                  await CloudSyncService().deleteIncome(
                    userId: userId,
                    incomeId: income.id,
                  );
                } catch (e) {
                  // Ignorer Firebase-feil
                }
              }
              // Slett fra Hive
              await income.delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(localizations?.delete ?? 'Slett'),
          ),
        ],
      ),
    );
  }
}
