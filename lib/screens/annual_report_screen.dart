import 'package:flutter/material.dart';
import 'package:breedly/services/annual_report_service.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/utils/theme_colors.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:breedly/models/litter.dart';
import 'package:breedly/models/puppy.dart';
import 'package:breedly/models/expense.dart';
import 'package:breedly/models/income.dart';
import 'package:breedly/models/show_result.dart';
import 'package:intl/intl.dart';

class AnnualReportScreen extends StatefulWidget {
  const AnnualReportScreen({super.key});

  @override
  State<AnnualReportScreen> createState() => _AnnualReportScreenState();
}

class _AnnualReportScreenState extends State<AnnualReportScreen> {
  late int _selectedYear;
  bool _isGenerating = false;
  final _reportService = AnnualReportService();
  final _currencyFormat = NumberFormat.currency(locale: 'nb_NO', symbol: 'kr');

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
  }

  List<int> _getAvailableYears() {
    final currentYear = DateTime.now().year;
    final years = <int>[];

    // Get years from data
    try {
      final litterBox = Hive.box<Litter>('litters');
      final expenseBox = Hive.box<Expense>('expenses');
      final incomeBox = Hive.box<Income>('incomes');

      for (final litter in litterBox.values) {
        final year = litter.dateOfBirth.year;
        if (!years.contains(year)) years.add(year);
      }
      for (final expense in expenseBox.values) {
        final year = expense.date.year;
        if (!years.contains(year)) years.add(year);
      }
      for (final income in incomeBox.values) {
        final year = income.date.year;
        if (!years.contains(year)) years.add(year);
      }
    } catch (e) {
      // Boxes might not be open
    }

    // Always include current year and last 5 years
    for (var i = 0; i < 5; i++) {
      final year = currentYear - i;
      if (!years.contains(year)) years.add(year);
    }

    years.sort((a, b) => b.compareTo(a));
    return years;
  }

  Map<String, dynamic> _getYearStats() {
    try {
      final litterBox = Hive.box<Litter>('litters');
      final puppyBox = Hive.box<Puppy>('puppies');
      final expenseBox = Hive.box<Expense>('expenses');
      final incomeBox = Hive.box<Income>('incomes');
      final showResultBox = Hive.box<ShowResult>('show_results');

      final litters = litterBox.values
          .where((l) => l.dateOfBirth.year == _selectedYear)
          .toList();
      final puppies = puppyBox.values
          .where((p) => p.dateOfBirth.year == _selectedYear)
          .toList();
      final expenses = expenseBox.values
          .where((e) => e.date.year == _selectedYear)
          .toList();
      final incomes = incomeBox.values
          .where((i) => i.date.year == _selectedYear)
          .toList();
      final showResults = showResultBox.values
          .where((s) => s.date.year == _selectedYear)
          .toList();

      final totalIncome = incomes.fold<double>(0, (sum, i) => sum + i.amount);
      final totalExpenses = expenses.fold<double>(
        0,
        (sum, e) => sum + e.amount,
      );

      return {
        'litters': litters.length,
        'puppies': puppies.length,
        'malePuppies': puppies.where((p) => p.gender == 'Male').length,
        'femalePuppies': puppies.where((p) => p.gender == 'Female').length,
        'soldPuppies': puppies
            .where((p) => p.status == 'Sold' || p.status == 'Delivered')
            .length,
        'totalIncome': totalIncome,
        'totalExpenses': totalExpenses,
        'netResult': totalIncome - totalExpenses,
        'showResults': showResults.length,
        'birCount': showResults.where((s) => s.placement == 'BIR').length,
        'certCount': showResults
            .where((s) => s.certificates?.isNotEmpty == true)
            .length,
      };
    } catch (e) {
      return {
        'litters': 0,
        'puppies': 0,
        'malePuppies': 0,
        'femalePuppies': 0,
        'soldPuppies': 0,
        'totalIncome': 0.0,
        'totalExpenses': 0.0,
        'netResult': 0.0,
        'showResults': 0,
        'birCount': 0,
        'certCount': 0,
      };
    }
  }

  Future<void> _generateAndShareReport() async {
    setState(() => _isGenerating = true);

    try {
      await _reportService.shareAnnualReport(_selectedYear);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.error ?? 'Feil'}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final theme = Theme.of(context);
    final stats = _getYearStats();
    final availableYears = _getAvailableYears();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.annualReport),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Year selector card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectYear,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: context.colors.divider),
                        borderRadius: AppRadius.mdAll,
                      ),
                      child: DropdownButton<int>(
                        value: _selectedYear,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        items: availableYears.map((year) {
                          return DropdownMenuItem(
                            value: year,
                            child: Text(
                              year.toString(),
                              style: theme.textTheme.bodyLarge,
                            ),
                          );
                        }).toList(),
                        onChanged: (year) {
                          if (year != null) {
                            setState(() => _selectedYear = year);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Summary cards
            Text(
              l10n.annualSummary,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Litters and puppies row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: l10n.littersRegistered,
                    value: '${stats['litters']}',
                    icon: Icons.pets,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatCard(
                    title: l10n.puppiesBorn,
                    value: '${stats['puppies']}',
                    icon: Icons.pets,
                    color: AppColors.accent5,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // Gender distribution
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: l10n.malePuppies,
                    value: '${stats['malePuppies']}',
                    icon: Icons.male,
                    color: AppColors.male,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatCard(
                    title: l10n.femalePuppies,
                    value: '${stats['femalePuppies']}',
                    icon: Icons.female,
                    color: AppColors.female,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // Sales
            _StatCard(
              title: l10n.puppiesSold,
              value: '${stats['soldPuppies']}',
              icon: Icons.shopping_cart,
              color: AppColors.warning,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Finance section
            Text(
              l10n.financialSummary,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: l10n.totalIncome,
                    value: _currencyFormat.format(stats['totalIncome']),
                    icon: Icons.arrow_upward,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatCard(
                    title: l10n.totalExpenses,
                    value: _currencyFormat.format(stats['totalExpenses']),
                    icon: Icons.arrow_downward,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            _StatCard(
              title: l10n.netResult,
              value: _currencyFormat.format(stats['netResult']),
              icon: stats['netResult'] >= 0
                  ? Icons.trending_up
                  : Icons.trending_down,
              color: stats['netResult'] >= 0 ? AppColors.success : AppColors.error,
              large: true,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Show results section
            if (stats['showResults'] > 0) ...[
              Text(
                l10n.showResults,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: l10n.shows,
                      value: '${stats['showResults']}',
                      icon: Icons.emoji_events,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _StatCard(
                      title: 'BIR',
                      value: '${stats['birCount']}',
                      icon: Icons.star,
                      color: AppColors.accent3,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _StatCard(
                      title: l10n.certificates,
                      value: '${stats['certCount']}',
                      icon: Icons.verified,
                      color: AppColors.accent4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Generate PDF button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateAndShareReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(AppSpacing.md),
                ),
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(
                  _isGenerating ? l10n.generating : l10n.generatePdfReport,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Info text
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.colors.neutral100,
                borderRadius: AppRadius.mdAll,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: context.colors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.reportInfo,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.colors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool large;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(large ? AppSpacing.lg : AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Icon(icon, color: color, size: large ? 28 : 20),
                ),
                const Spacer(),
              ],
            ),
            SizedBox(height: large ? AppSpacing.md : AppSpacing.sm),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: large ? 24 : 18,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
